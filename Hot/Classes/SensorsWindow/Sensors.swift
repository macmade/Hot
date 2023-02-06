/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2022, Jean-David Gadina - www.xs-labs.com
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

import Cocoa

@objc
public class Sensors: NSObject
{
    @objc public private( set ) dynamic var loading = true
    @objc public private( set ) dynamic var data    = [ SensorHistoryData ]()
    @objc private               dynamic var sensors = [ String: SensorHistoryData ]()

    private var shouldRun = true
    private var completion: ( () -> Void )?

    public override init()
    {
        super.init()

        DispatchQueue.global( qos: .background ).async
        {
            self.run()
        }
    }

    public func stop( completion: ( () -> Void )? )
    {
        if self.shouldRun == false
        {
            return
        }

        self.completion = completion
        self.shouldRun  = false
    }

    private func run()
    {
        let timer = Timer.scheduledTimer( withTimeInterval: 1, repeats: true )
        {
            _ in self.readSensors()
        }

        self.readSensors()
        RunLoop.current.add( timer, forMode: .default )

        while self.shouldRun
        {
            RunLoop.current.run( until: Date( timeIntervalSinceNow: 5 ) )
        }

        let completion  = self.completion
        self.completion = nil

        completion?()
    }

    private func readSensors()
    {
        self.readIOHIDSensors()
        self.readSMCSensors()

        let sensors = self.sensors

        DispatchQueue.main.async
        {
            self.data    = [ SensorHistoryData ]( sensors.values )
            self.loading = false
        }
    }

    private func readIOHIDSensors()
    {
        IOHID.shared.readTemperatureSensors().forEach { self.addSensorHistoryData( data: $0, kind: .thermal ) }
        IOHID.shared.readVoltageSensors().forEach     { self.addSensorHistoryData( data: $0, kind: .voltage ) }
        IOHID.shared.readCurrentSensors().forEach     { self.addSensorHistoryData( data: $0, kind: .current ) }
    }

    private func readSMCSensors()
    {
        let all = SMC.shared.readAllKeys()

        all.filter { $0.keyName.hasPrefix( "T" ) }.forEach { self.addSensorHistoryData( data: $0, kind: .thermal ) }
        all.filter { $0.keyName.hasPrefix( "V" ) }.forEach { self.addSensorHistoryData( data: $0, kind: .voltage ) }
        all.filter { $0.keyName.hasPrefix( "I" ) }.forEach { self.addSensorHistoryData( data: $0, kind: .current ) }
    }

    private func addSensorHistoryData( data: IOHIDData, kind: SensorHistoryData.Kind )
    {
        let key = String( format: "IOHID.%llu.%@", kind.rawValue, data.name )

        if self.sensors[ key ] == nil
        {
            self.sensors[ key ] = SensorHistoryData( source: .hid, kind: kind, name: data.name, properties: data.properties )
        }

        self.sensors[ key ]?.add( value: data.value )
    }

    private func addSensorHistoryData( data: SMCData, kind: SensorHistoryData.Kind )
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
            return
        }

        let key = String( format: "SMC.%llu.%@", kind.rawValue, data.keyName )

        if self.sensors[ key ] == nil
        {
            self.sensors[ key ] = SensorHistoryData( source: .smc, kind: kind, name: data.keyName, properties: [ : ] )
        }

        self.sensors[ key ]?.add( value: value )
    }
}
