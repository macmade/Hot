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

import Foundation

@objc
public class SensorData: NSObject
{
    @objc( SensorDataKind )
    public enum Kind: Int, CustomStringConvertible
    {
        case thermal
        case voltage
        case current

        public var description: String
        {
            switch self
            {
                case .thermal: return "thermal"
                case .voltage: return "voltage"
                case .current: return "current"
            }
        }
    }

    @objc public private( set ) dynamic var kind:       Kind
    @objc public private( set ) dynamic var name:       String
    @objc public private( set ) dynamic var properties: [ String: Any ]?

    private var data: [ Double ] = []

    @objc public dynamic var values: [ NSNumber ]
    {
        self.data.map { NSNumber( floatLiteral: $0 ) }
    }

    @objc public dynamic var min: NSNumber?
    {
        guard let max = self.data.min()
        else
        {
            return nil
        }

        return NSNumber( floatLiteral: max )
    }

    @objc public dynamic var max: NSNumber?
    {
        guard let min = self.data.max()
        else
        {
            return nil
        }

        return NSNumber( floatLiteral: min )
    }

    @objc public dynamic var last: NSNumber?
    {
        guard let last = self.data.last
        else
        {
            return nil
        }

        return NSNumber( floatLiteral: last )
    }

    @objc
    public init( kind: Kind, name: String, properties: [ String: Any ]? )
    {
        self.kind       = kind
        self.name       = name
        self.properties = properties
    }

    @objc( addValue: )
    public func add( value: Double )
    {
        var data = self.data

        data.append( value )

        self.willChangeValue( for: \.values )
        self.willChangeValue( for: \.min )
        self.willChangeValue( for: \.max )
        self.willChangeValue( for: \.last )

        self.data = data.suffix( 50 )

        self.didChangeValue( for: \.values )
        self.didChangeValue( for: \.min )
        self.didChangeValue( for: \.max )
        self.didChangeValue( for: \.last )
    }

    public override var description: String
    {
        let min = String( format: "%.2f", self.min?.doubleValue ?? 0 )
        let max = String( format: "%.2f", self.max?.doubleValue ?? 0 )

        return "\( super.description ): \( self.name ) (\( self.kind ), min: \( min ), max: \( max ))"
    }
}
