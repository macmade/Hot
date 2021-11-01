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
    @objc public dynamic var cpuTemperature:  NSNumber?
    @objc public dynamic var thermalPressure: NSNumber?
    @objc public dynamic var sensors:         [ String : Double ] = [:]
    
    private var refreshing = false
    
    private static var queue = DispatchQueue( label: "com.xs-labs.Hot.ThermalLog", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil )
    
    public override init()
    {
        super.init()
    }
    
    private func readSensors() -> [ String : Double ]
    {
        #if arch( arm64 )
        
        return Dictionary( uniqueKeysWithValues:
            ReadM1Sensors().filter
            {
                $0.key.hasPrefix( "pACC" ) || $0.key.hasPrefix( "eACC" )
            }
            .map
            {
                ( $0.key, $0.value.doubleValue )
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
                return [ sensor.key : temp ]
            }
        }
        
        return [:]
        
        #endif
    }
    
    public func refresh()
    {
        ThermalLog.queue.async
        {
            if self.refreshing
            {
                return
            }
            
            self.refreshing = true
            
            #if arch( arm64 )
            
            let pressure = ProcessInfo().thermalState
            
            DispatchQueue.main.async
            {
                self.thermalPressure = NSNumber( integerLiteral: pressure.rawValue )
            }
            
            #endif
            
            let sensors = self.readSensors()
            let temp    = sensors.reduce( 0.0 )
            {
                r, v in v.value > r ? v.value : r
            }
            
            if temp > 1
            {
                DispatchQueue.main.async
                {
                    self.sensors        = sensors
                    self.cpuTemperature = NSNumber( value: temp )
                }
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
                
                return
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            guard let str = String( data: data, encoding: .utf8 ), str.count > 0 else
            {
                self.refreshing = false
                
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
                    DispatchQueue.main.async { self.schedulerLimit = NSNumber( value: n ) }
                }
                else if( p[ 0 ] == "CPU_Available_CPUs" )
                {
                    DispatchQueue.main.async { self.availableCPUs = NSNumber( value: n ) }
                }
                else if( p[ 0 ] == "CPU_Speed_Limit" )
                {
                    DispatchQueue.main.async { self.speedLimit = NSNumber( value: n ) }
                }
            }
            
            self.refreshing = false
        }
    }
}
