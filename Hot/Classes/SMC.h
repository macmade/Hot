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

/*!
 * @header      SMC.h
 * @copyright   (c) 2020, Jean-David Gadina - www.xs-labs.com
 */

#ifndef SMC_H
#define SMC_H

#include <stdint.h>
#include <IOKit/IOKitLib.h>

/*
 * Reference:
 *   - https://opensource.apple.com/source/IOKitUser/
 *   - https://opensource.apple.com/source/IOKitUser/IOKitUser-647.6/pwr_mgt.subproj/IOPMLibPrivate.c
 */

enum
{
    kSMCKeyNotFound = 0x84
};

enum
{
    kSMCSuccess = 0,
    kSMCError   = 1
};

enum
{
    kSMCUserClientOpen  = 0,
    kSMCUserClientClose = 1,
    kSMCHandleYPCEvent  = 2,
    kSMCReadKey         = 5,
    kSMCWriteKey        = 6,
    kSMCGetKeyCount     = 7,
    kSMCGetKeyFromIndex = 8,
    kSMCGetKeyInfo      = 9
};

typedef struct
{
    unsigned char  major;
    unsigned char  minor;
    unsigned char  build;
    unsigned char  reserved;
    unsigned short release;
}
SMCVersion;

typedef struct
{
    uint16_t version;
    uint16_t length;
    uint32_t cpuPLimit;
    uint32_t gpuPLimit;
    uint32_t memPLimit;
}
SMCPLimitData;

typedef struct
{
    IOByteCount dataSize;
    uint32_t    dataType;
    uint8_t     dataAttributes;
}
SMCKeyInfoData;

typedef struct
{
    uint32_t       key;
    SMCVersion     vers;
    SMCPLimitData  pLimitData;
    SMCKeyInfoData keyInfo;
    uint8_t        result;
    uint8_t        status;
    uint8_t        data8;
    uint32_t       data32;
    uint8_t        bytes[ 32 ];
}
SMCParamStruct;

IOReturn SMCReadKey( uint32_t key, uint8_t * buf, IOByteCount * maxSize );
IOReturn SMCCallFunction( uint32_t function, SMCParamStruct * input, SMCParamStruct * output );
double   SMCGetCPUTemperature( void );

#endif /* SMC_H */
