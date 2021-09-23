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

@import IOKit;
@import CoreFoundation;

#import <IOKit/hidsystem/IOHIDEventSystemClient.h>
#import <IOKit/hidsystem/IOHIDServiceClient.h>
#import <IOKit/hid/IOHIDKeys.h>

/* @see https://opensource.apple.com/source/IOHIDFamily/ */

typedef NS_ENUM( int64_t, IOHIDPage )
{
    IOHIDPageAppleVendor                   = 0xFF00,
    IOHIDPageAppleVendorKeyboard           = 0xFF01,
    IOHIDPageAppleVendorMouse              = 0xFF02,
    IOHIDPageAppleVendorAccelerometer      = 0xFF03,
    IOHIDPageAppleVendorAmbientLightSensor = 0xFF04,
    IOHIDPageAppleVendorTemperatureSensor  = 0xFF05,
    IOHIDPageAppleVendorHeadset            = 0xFF07,
    IOHIDPageAppleVendorPowerSensor        = 0xFF08,
    IOHIDPageAppleVendorSmartCover         = 0xFF09,
    IOHIDPageAppleVendorPlatinum           = 0xFF0A,
    IOHIDPageAppleVendorLisa               = 0xFF0B,
    IOHIDPageAppleVendorMotion             = 0xFF0C,
    IOHIDPageAppleVendorBattery            = 0xFF0D,
    IOHIDPageAppleVendorIRRemote           = 0xFF0E,
    IOHIDPageAppleVendorDebug              = 0xFF0F,
    IOHIDPageAppleVendorFilteredEvent      = 0xFF50,
    IOHIDPageAppleVendorMultitouch         = 0xFF60,
    IOHIDPageAppleVendorDisplay            = 0xFF92,
    IOHIDPageAppleVendorTopCase            = 0x00FF
};

typedef NS_ENUM( int64_t, IOHIDUsageAppleVendor )
{
    IOHIDUsageAppleVendorTopCase            = 0x01,
    IOHIDUsageAppleVendorDisplay            = 0x02,
    IOHIDUsageAppleVendorAccelerometer      = 0x03,
    IOHIDUsageAppleVendorAmbientLightSensor = 0x04,
    IOHIDUsageAppleVendorTemperatureSensor  = 0x05,
    IOHIDUsageAppleVendorKeyboard           = 0x06,
    IOHIDUsageAppleVendorHeadset            = 0x07,
    IOHIDUsageAppleVendorProximitySensor    = 0x08,
    IOHIDUsageAppleVendorGyro               = 0x09,
    IOHIDUsageAppleVendorCompass            = 0x0A,
    IOHIDUsageAppleVendorDeviceManagement   = 0x0B,
    IOHIDUsageAppleVendorTrackpad           = 0x0C,
    IOHIDUsageAppleVendorTopCaseReserved    = 0x0D,
    IOHIDUsageAppleVendorMotion             = 0x0E,
    IOHIDUsageAppleVendorKeyboardBacklight  = 0x0F,
    IOHIDUsageAppleVendorDeviceMotionLite   = 0x10,
    IOHIDUsageAppleVendorForce              = 0x11,
    IOHIDUsageAppleVendorBluetoothRadio     = 0x12,
    IOHIDUsageAppleVendorOrb                = 0x13,
    IOHIDUsageAppleVendorAccessoryBattery   = 0x14
};

typedef NS_ENUM( int64_t, IOHIDUsageAppleVendorPowerSensor )
{
    IOHIDUsageAppleVendorPowerSensorPower   = 0x1,
    IOHIDUsageAppleVendorPowerSensorCurrent = 0x2,
    IOHIDUsageAppleVendorPowerSensorVoltage = 0x3
};

typedef NS_ENUM( int64_t, IOHIDEvent )
{
    IOHIDEventTypeNULL                  = 0x00,
    IOHIDEventTypeVendorDefined         = 0x01,
    IOHIDEventTypeButton                = 0x02,
    IOHIDEventTypeKeyboard              = 0x03,
    IOHIDEventTypeTranslation           = 0x04,
    IOHIDEventTypeRotation              = 0x05,
    IOHIDEventTypeScroll                = 0x06,
    IOHIDEventTypeScale                 = 0x07,
    IOHIDEventTypeZoom                  = 0x08,
    IOHIDEventTypeVelocity              = 0x09,
    IOHIDEventTypeOrientation           = 0x0A,
    IOHIDEventTypeDigitizer             = 0x0B,
    IOHIDEventTypeAmbientLightSensor    = 0x0C,
    IOHIDEventTypeAccelerometer         = 0x0D,
    IOHIDEventTypeProximity             = 0x0E,
    IOHIDEventTypeTemperature           = 0x0F,
    IOHIDEventTypeNavigationSwipe       = 0x10,
    IOHIDEventTypeSwipe                 = IOHIDEventTypeNavigationSwipe,
    IOHIDEventTypeMouse                 = 0x11,
    IOHIDEventTypeProgress              = 0x12,
    IOHIDEventTypeCount                 = 0x13,
    IOHIDEventTypeGyro                  = 0x14,
    IOHIDEventTypeCompass               = 0x15,
    IOHIDEventTypeZoomToggle            = 0x16,
    IOHIDEventTypeDockSwipe             = 0x17,
    IOHIDEventTypeSymbolicHotKey        = 0x18,
    IOHIDEventTypePower                 = 0x19,
    IOHIDEventTypeBrightness            = 0x1A,
    IOHIDEventTypeFluidTouchGesture     = 0x1B,
    IOHIDEventTypeBoundaryScroll        = 0x1C,
    IOHIDEventTypeReset                 = 0x1D
};

extern IOHIDEventSystemClientRef IOHIDEventSystemClientCreate( CFAllocatorRef );
extern void                      IOHIDEventSystemClientSetMatching( IOHIDEventSystemClientRef, CFDictionaryRef );
extern CFTypeRef                 IOHIDServiceClientCopyEvent( IOHIDServiceClientRef, IOHIDEvent, int64_t, int64_t );
extern CFDictionaryRef           IOHIDServiceClientCopyProperties( IOHIDServiceClientRef, CFArrayRef );
extern double                    IOHIDEventGetFloatValue( CFTypeRef, int64_t );
