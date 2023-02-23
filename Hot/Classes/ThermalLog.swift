/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2023, Jean-David Gadina - www.xs-labs.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the Software), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Foundation
import IOHIDKit
import SMCKit

public class ThermalLog: NSObject
{
    @objc public dynamic var schedulerLimit:  NSNumber?
    @objc public dynamic var availableCPUs:   NSNumber?
    @objc public dynamic var speedLimit:      NSNumber?
    @objc public dynamic var temperature:     NSNumber?
    @objc public dynamic var thermalPressure: NSNumber?
    @objc public dynamic var sensors:         [ String: Double ] = [ : ]

    private var refreshing = false

    private static var queue = DispatchQueue( label: "com.xs-labs.Hot.ThermalLog", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil )

    public override init()
    {
        super.init()
    }

    private func readSensors() -> [ String: ( temperature: Double, isCPU: Bool ) ]
    {
        let ioHID = IOHID.shared.readTemperatureSensors().compactMap
        {
            self.sensorValue( data: $0 )
        }

        let smc = SMC.shared.readAllKeys
        {
            $0 >> 24 == 84 // T prefix (four char code)
        }
        .compactMap
        {
            self.sensorValue( data: $0 )
        }

        let all = [ ioHID, smc ].flatMap { $0 }.filter
        {
            $0.1.temperature > 0 && $0.1.temperature < 120
        }

        return Dictionary( uniqueKeysWithValues: all )
    }

    private func sensorValue( data: IOHIDData ) -> ( String, ( temperature: Double, isCPU: Bool ) )?
    {
        let isCPU = data.name.hasPrefix( "pACC" ) || data.name.hasPrefix( "eACC" )

        return ( data.name, ( temperature: data.value, isCPU: isCPU ) )
    }

    private func sensorValue( data: SMCData ) -> ( String, ( temperature: Double, isCPU: Bool ) )?
    {
        let value: Double

        if let f = data.value as? Double
        {
            value = f
        }
        else if let f = data.value as? Float32
        {
            value = Double( f )
        }
        else
        {
            return nil
        }

        return ( data.keyName, ( temperature: value, isCPU: false ) )
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

            let sensors       = self.readSensors()
            let cpu           = sensors.filter { $0.value.isCPU }.mapValues { $0.temperature }
            let all           = sensors.mapValues { $0.temperature }
            self.sensors      = all
            let names         = UserDefaults.standard.object( forKey: "selectedSensors" ) as? [ String ] ?? []
            let selectionMode = UserDefaults.standard.integer( forKey: "selectedSensorsMode" )
            let selected      = sensors.filter
            {
                selectionMode == 0 ? names.contains( $0.key ) : names.contains( $0.key ) == false
            }
            .mapValues
            {
                $0.temperature
            }

            let temperatures: [ Double ] =
            {
                if selected.count > 0
                {
                    return selected.values.map { $0 }
                }
                else if cpu.count > 0
                {
                    return cpu.values.map { $0 }
                }
                else
                {
                    let tcal = all.first { $0.key.lowercased().hasSuffix( "tcal" ) }

                    return all.filter
                    {
                        if $0.key.lowercased().hasSuffix( "tcal" )
                        {
                            return false
                        }

                        if let tcal = tcal
                        {
                            let x = Int( ceil( tcal.value * 100 ) )
                            let y = Int( ceil( $0.value   * 100 ) )

                            if x == y
                            {
                                return false
                            }
                        }

                        return true
                    }
                    .values.map { $0 }
                }
            }()

            let temp: Double =
            {
                if UserDefaults.standard.integer( forKey: "temperatureDisplayMode" ) == 1
                {
                    return temperatures.count == 0 ? 0 : temperatures.reduce( 0, + ) / Double( temperatures.count )
                }

                return temperatures.reduce( 0.0 )
                {
                    r, v in max( r, v )
                }
            }()

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

            guard let str = String( data: data, encoding: .utf8 ), str.count > 0
            else
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

                guard let n = UInt( p[ 1 ] )
                else
                {
                    continue
                }

                if p[ 0 ] == "CPU_Scheduler_Limit"
                {
                    self.schedulerLimit = NSNumber( value: n )
                }
                else if p[ 0 ] == "CPU_Available_CPUs"
                {
                    self.availableCPUs = NSNumber( value: n )
                }
                else if p[ 0 ] == "CPU_Speed_Limit"
                {
                    self.speedLimit = NSNumber( value: n )
                }
            }

            self.refreshing = false

            completion()
        }
    }
}
