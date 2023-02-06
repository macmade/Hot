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
public class SMCData: NSObject
{
    @objc public dynamic var key:   UInt32
    @objc public dynamic var type:  UInt32
    @objc public dynamic var data:  Data
    @objc public dynamic var value: Any?

    @objc public var keyName:  String
    {
        SMCData.fourCC( value: self.key )
    }

    @objc public var typeName: String
    {
        SMCData.fourCC( value: self.type )
    }

    @objc
    public init( key: UInt32, type: UInt32, data: Data )
    {
        self.key   = key
        self.type  = type
        self.data  = data
        self.value = SMCData.value( for: data, type: type )
    }

    private class func fourCC( value: UInt32 ) -> String
    {
        let c1 = UInt8( ( value >> 24 ) & 0xFF )
        let c2 = UInt8( ( value >> 16 ) & 0xFF )
        let c3 = UInt8( ( value >>  8 ) & 0xFF )
        let c4 = UInt8( ( value >>  0 ) & 0xFF )

        return String( format: "%c%c%c%c", c1, c2, c3, c4 )
    }

    private class func value( for data: Data, type: UInt32 ) -> Any?
    {
        switch self.fourCC( value: type )
        {
            case "si8 ": return self.sint8(   data: data ).byteSwapped
            case "ui8 ": return self.uint8(   data: data ).byteSwapped
            case "si16": return self.sint16(  data: data ).byteSwapped
            case "ui16": return self.uint16(  data: data ).byteSwapped
            case "si32": return self.sint32(  data: data ).byteSwapped
            case "ui32": return self.uint32(  data: data ).byteSwapped
            case "si64": return self.sint64(  data: data ).byteSwapped
            case "ui64": return self.uint64(  data: data ).byteSwapped
            case "flt ": return self.float32( data: data )
            case "ioft": return self.ioFloat( data: data )
            case "sp78": return self.sp78(    data: data )
            case "flag": return data[ 0 ] == 1 ? "True" : "False"
            case "ch8*": return String( data: Data( data.reversed() ), encoding: .utf8 )

            default: return nil
        }
    }

    private class func sint8( data: Data ) -> Int8
    {
        Int8( bitPattern: self.uint8( data: data ) )
    }

    private class func sint16( data: Data ) -> Int16
    {
        Int16( bitPattern: self.uint16( data: data ) )
    }

    private class func sint32( data: Data ) -> Int32
    {
        Int32( bitPattern: self.uint32( data: data ) )
    }

    private class func sint64( data: Data ) -> Int64
    {
        Int64( bitPattern: self.uint64( data: data ) )
    }

    private class func uint8( data: Data ) -> UInt8
    {
        UInt8( data[ 0 ] )
    }

    private class func uint16( data: Data ) -> UInt16
    {
        let u1 = UInt16( data[ 0 ] ) << 8
        let u2 = UInt16( data[ 1 ] ) << 0

        return u1 | u2
    }

    private class func uint32( data: Data ) -> UInt32
    {
        let u1 = UInt32( data[ 0 ] ) << 24
        let u2 = UInt32( data[ 1 ] ) << 16
        let u3 = UInt32( data[ 2 ] ) <<  8
        let u4 = UInt32( data[ 3 ] ) <<  0

        return u1 | u2 | u3 | u4
    }

    private class func uint64( data: Data ) -> UInt64
    {
        let u1 = UInt64( data[ 0 ] ) << 56
        let u2 = UInt64( data[ 1 ] ) << 48
        let u3 = UInt64( data[ 2 ] ) << 40
        let u4 = UInt64( data[ 3 ] ) << 32
        let u5 = UInt64( data[ 4 ] ) << 24
        let u6 = UInt64( data[ 5 ] ) << 16
        let u7 = UInt64( data[ 6 ] ) <<  8
        let u8 = UInt64( data[ 7 ] ) <<  0

        return u1 | u2 | u3 | u4 | u5 | u6 | u7 | u8
    }

    private class func float32( data: Data ) -> Float32
    {
        Float32( bitPattern: self.uint32( data: data ) )
    }

    private class func float64( data: Data ) -> Float64
    {
        Float64( bitPattern: self.uint64( data: data ) )
    }

    private class func ioFloat( data: Data ) -> Double
    {
        if data.count != 8
        {
            return 0
        }

        let u64        = self.uint64( data: data )
        let integral   = Double( u64 >> 16 )
        let mask       = pow( 2.0, 16.0 ) - 1
        let fractional = Double( u64 & UInt64( mask ) ) / Double( 1 << 16 )

        return integral + fractional
    }

    private class func sp78( data: Data ) -> Double
    {
        if data.count != 2
        {
            return 0
        }

        let b1 = Double( data[ 1 ] & 0x7F )
        let b2 = Double( data[ 0 ] ) / Double( 1 << 8 )

        return b1 + b2
    }
}
