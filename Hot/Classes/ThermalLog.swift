/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2020 Jean-David Gadina - www.xs-labs.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Foundation

public class ThermalLog: NSObject
{
    @objc public dynamic var schedulerLimit:  NSNumber?
    @objc public dynamic var availableCPUs:   NSNumber?
    @objc public dynamic var speedLimit:      NSNumber?
    @objc public dynamic var temperature:     NSNumber?
    @objc public dynamic var thermalPressure: NSNumber?
    @objc public dynamic var sensors:         [ String : Double ] = [:]
    
    private var refreshing = false
    
    private static var queue = DispatchQueue( label: "com.xs-labs.Hot.ThermalLog", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil )
    
    public override init()
    {
        super.init()
    }
    
    private func readSensors() -> [ String : ( temperature: Double, isCPU: Bool ) ]
    {
        #if arch( arm64 )
        
        return Dictionary( uniqueKeysWithValues:
            ReadAppleSiliconSensors().map
            {
                let isCPU = $0.key.hasPrefix( "pACC" ) || $0.key.hasPrefix( "eACC" )
                
                return ( $0.key, ( temperature: $0.value.doubleValue, isCPU: isCPU ) )
            }
        )
        
        #else
        
        let sensors =
        [
            "TCXC" : SMCKeyTCXC,
            "CUS1" : SMCKeyCUS1,
            "TC0D" : SMCKeyTC0D,
            "TC0C" : SMCKeyTC0C,
            "TCAD" : SMCKeyTCAD,
        ]
        
        for sensor in sensors
        {
            var temp = 0.0
            
            if SMCGetCPUTemperature( sensor.value, &temp )
            {
                return [ sensor.key : ( temperature: temp, isCPU: true ) ]
            }
        }
        
        return [:]
        
        #endif
    }
    
    public func refresh( completion: @escaping () -> Void )
    {
        ThermalLog.queue.async
        {
            if self.refreshing
            {
                completion()
                
                return
            }
            
            self.refreshing = true
            
            #if arch( arm64 )
            
            let pressure         = ProcessInfo.processInfo.thermalState
            self.thermalPressure = NSNumber( integerLiteral: pressure.rawValue )
            
            #endif
            
            let sensors  = self.readSensors()
            let cpu      = sensors.filter { $0.value.isCPU }.mapValues { $0.temperature }
            let all      = sensors.mapValues { $0.temperature }
            var temp     = 0.0
            self.sensors = all
            
            if cpu.count > 0
            {
                temp = cpu.reduce( 0.0 ) { r, v in v.value > r ? v.value : r }
            }
            else
            {
                temp = all.filter
                {
                    $0.key.lowercased().hasSuffix( "tcal" ) == false
                }
                .reduce( 0.0 )
                {
                    r, v in v.value > r ? v.value : r
                }
            }
            
            if temp > 1
            {
                self.temperature = NSNumber( value: temp )
            }
            
            let pipe            = Pipe()
            let task            = Process()
            task.launchPath     = "/usr/bin/pmset"
            task.arguments      = [ "-g", "therm" ]
            task.standardOutput = pipe
            
            task.launch()
            task.waitUntilExit()
            
            if task.terminationStatus != 0
            {
                self.refreshing = false
                
                completion()
                
                return
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            guard let str = String( data: data, encoding: .utf8 ), str.count > 0 else
            {
                self.refreshing = false
                
                completion()
                
                return
            }
            
            let lines = str.replacingOccurrences( of: " ",  with: "" ).replacingOccurrences( of: "\t", with: "" ).split( separator: "\n" )
            
            for line in lines
            {
                let p = line.split( separator: "=" )
                
                if p.count < 2
                {
                    continue
                }
                
                guard let n = UInt( p[ 1 ] ) else
                {
                    continue
                }
                
                if( p[ 0 ] == "CPU_Scheduler_Limit" )
                {
                    self.schedulerLimit = NSNumber( value: n )
                }
                else if( p[ 0 ] == "CPU_Available_CPUs" )
                {
                    self.availableCPUs = NSNumber( value: n )
                }
                else if( p[ 0 ] == "CPU_Speed_Limit" )
                {
                    self.speedLimit = NSNumber( value: n )
                }
            }
            
            self.refreshing = false
            
            completion()
        }
    }
}
