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
 * @file        SMC.c
 * @copyright   (c) 2020, Jean-David Gadina - www.xs-labs.com
 */

#include "SMC.h"

/*
 * Reference:
 *   - https://opensource.apple.com/source/IOKitUser/
 *   - https://opensource.apple.com/source/IOKitUser/IOKitUser-647.6/pwr_mgt.subproj/IOPMLibPrivate.c
 */

#pragma clang diagnostic ignored "-Wfour-char-constants"

IOReturn SMCReadKey( uint32_t key, uint8_t * buf, IOByteCount * maxSize )
{
    SMCParamStruct input;
    SMCParamStruct output;
    IOReturn       ret;
    
    if( key == 0 || buf == NULL )
    {
        return kIOReturnCannotWire;
    }
    
    memset( buf,     0, *( maxSize ) );
    memset( &input,  0, sizeof( SMCParamStruct ) );
    memset( &output, 0, sizeof( SMCParamStruct ) );
    
    input.data8 = kSMCGetKeyInfo;
    input.key   = key;
    
    SMCCallFunction( kSMCHandleYPCEvent, &input, &output );
    
    if( output.result == kSMCKeyNotFound )
    {
        return kIOReturnNotFound;
    }
    else if( output.result != kSMCSuccess )
    {
        return kIOReturnInternalError;
    }
    
    input.data8            = kSMCReadKey;
    input.key              = key;
    input.keyInfo.dataSize = output.keyInfo.dataSize;
    
    memset( &output, 0, sizeof( SMCParamStruct ) );
    
    ret = SMCCallFunction( kSMCHandleYPCEvent, &input, &output );
    
    if( output.result == kSMCKeyNotFound )
    {
        return kIOReturnNotFound;
    }
    else if( output.result != kSMCSuccess )
    {
        return kIOReturnInternalError;
    }
    
    if( *( maxSize ) > input.keyInfo.dataSize )
    {
        *( maxSize ) = input.keyInfo.dataSize;
    }
    
    for( IOByteCount i = 0; i < *( maxSize ); i++ ) 
    {
        buf[ i ] = output.bytes[ i ];
    }
    
    return ret;
}

IOReturn SMCCallFunction( uint32_t function, SMCParamStruct * input, SMCParamStruct * output )
{
    io_connect_t connection;
    io_service_t smc;
    IOReturn     result; 
    
    smc = IOServiceGetMatchingService( kIOMasterPortDefault, IOServiceMatching( "AppleSMC" ) );
    
    if( smc == IO_OBJECT_NULL )
    {
        return kIOReturnNotFound;
    }
    
    result = IOServiceOpen( smc, mach_task_self(), 1, &connection );
    
    if( result != kIOReturnSuccess || connection == IO_OBJECT_NULL )
    {
        return result;
    }
    
    result = IOConnectCallMethod( connection, kSMCUserClientOpen, NULL, 0, NULL, 0, NULL, NULL, NULL, NULL );
    
    if( result != kIOReturnSuccess )
    {
        goto exit;
    }
    
    {
        size_t outputSize;
        
        outputSize = sizeof( SMCParamStruct );
        result     = IOConnectCallStructMethod( connection, function, input, sizeof( SMCParamStruct ), output, &outputSize );
    }
    
    exit:
    
        if( connection != IO_OBJECT_NULL )
        {
            IOConnectCallMethod( connection, kSMCUserClientClose, NULL, 0, NULL, 0, NULL, NULL, NULL, NULL );
            IOServiceClose( connection );
        }
        
        return result;
}

double SMCGetCPUTemperature( void )
{
    uint8_t     bytes[ 2 ];
    IOByteCount size;
    
    memset( &bytes, 0, sizeof( bytes ) );
    
    size = sizeof( bytes );
    
    if( SMCReadKey( 'TCXC', ( uint8_t * )&bytes, &size ) != kIOReturnSuccess || size != 2 )
    {
        return 0.0;
    }
    
    {
        double t1;
        double t2;
        
        t1  = bytes[ 0 ] & 0x7F;
        t2  = bytes[ 1 ];
        t2 /= 1 << 8;
        
        return t1 + t2;
    }
}
