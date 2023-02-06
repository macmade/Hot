/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2021 Jean-David Gadina - www.xs-labs.com
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

#import "IOHID.h"
#import "IOHID-Internal.h"
#import "Hot-Swift.h"
#import <IOKit/hidsystem/IOHIDEventSystemClient.h>
#import <IOKit/hidsystem/IOHIDServiceClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface IOHID()

@property( nonatomic, readwrite, assign, nullable ) IOHIDEventSystemClientRef client;

- ( NSArray< IOHIDData * > * )read: ( long long )page usage: ( int64_t )usage eventType: ( int64_t )eventType eventField: ( int64_t )eventField;

@end

NS_ASSUME_NONNULL_END

@implementation IOHID

+ ( IOHID * )shared
{
    static dispatch_once_t once;
    static IOHID         * instance;

    dispatch_once
    (
        &once,
        ^( void )
        {
            instance = [ IOHID new ];
        }
    );

    return instance;
}

- ( instancetype )init
{
    if( ( self = [ super init ] ) )
    {
        self.client = IOHIDEventSystemClientCreate( kCFAllocatorDefault );
    }

    return self;
}

- ( oneway void )dealloc
{
    CFRelease( self.client );
}

- ( NSArray< IOHIDData * > *  )readTemperatureSensors
{
    return [ self read: IOHIDPageAppleVendor usage: IOHIDUsageAppleVendorTemperatureSensor eventType: IOHIDEventTypeTemperature eventField: IOHIDEventFieldTemperatureLevel ];
}

- ( NSArray< IOHIDData * > *  )readVoltageSensors
{
    return [ self read: IOHIDPageAppleVendorPowerSensor usage: IOHIDUsageAppleVendorPowerSensorVoltage eventType: IOHIDEventTypePower eventField: IOHIDEventFieldPowerMeasurement ];
}

- ( NSArray< IOHIDData * > *  )readCurrentSensors
{
    return [ self read: IOHIDPageAppleVendorPowerSensor usage: IOHIDUsageAppleVendorPowerSensorCurrent eventType: IOHIDEventTypePower eventField: IOHIDEventFieldPowerMeasurement ];
}

- ( NSArray< IOHIDData * > * )read: ( long long )page usage: ( int64_t )usage eventType: ( int64_t )eventType eventField: ( int64_t )eventField
{
    if( self.client == nil )
    {
        return @[];
    }

    NSDictionary * filter =
    @{
        @"PrimaryUsagePage" : [ NSNumber numberWithLongLong: page ],
        @"PrimaryUsage"     : [ NSNumber numberWithLongLong: usage ]
    };

    IOHIDEventSystemClientSetMatching( self.client, ( __bridge CFDictionaryRef )filter );

    NSArray                       * services                = CFBridgingRelease( IOHIDEventSystemClientCopyServices( ( IOHIDEventSystemClientRef )( self.client ) ) );
    NSMutableDictionary< NSString *, IOHIDData * > * values = [ NSMutableDictionary new ];

    for( id o in services )
    {
        IOHIDServiceClientRef service = ( __bridge IOHIDServiceClientRef )o;
        NSString            * name    = CFBridgingRelease( IOHIDServiceClientCopyProperty( service, CFSTR( "Product" ) ) );
        CFTypeRef             event   = IOHIDServiceClientCopyEvent( service, eventType, 0, 0 );

        if( name != nil && event != nil )
        {
            values[ name ] = [ [ IOHIDData alloc ] initWithName: name value: IOHIDEventGetFloatValue( event, eventField ) ];
        }

        if( event != nil )
        {
            CFRelease( event );
        }
    }

    return [ values allValues ];
}

@end
