/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2017 Jean-David Gadina - www.xs-labs.com / www.imazing.com
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

#import "NSApplication+LaunchServices.h"
#import <ServiceManagement/ServiceManagement.h>

/*
 * LaunchServices functions for managing login items are deprecated,
 * but there's actually no viable alternative.
 * SystemManagement functions are not viable, because they require a separate
 * helper tool (complete app bundle) to be running constantly, for the sole
 * purpose of launching the main application.
 * Also, using SystemManagement, there's no way for the user to control the
 * login item, as it does not appear in the System Preferences, meaning there's
 * no way to delete the login item without the original app...
 * Common Apple, I think you can do better...
 */
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation NSApplication( LaunchServices )

+ ( BOOL )isLoginItemEnabledForBundleURL: ( NSURL * )url
{
    BOOL                    found;
    UInt32                  seedValue;
    CFURLRef                path;
    LSSharedFileListRef     loginItemsRef;
    CFArrayRef              loginItems;
    id                      loginItem;
    LSSharedFileListItemRef loginItemRef;
    
    found         = NO;
    seedValue     = 0;
    path          = NULL;
    loginItemsRef = LSSharedFileListCreate( NULL, kLSSharedFileListSessionLoginItems, NULL );
    
    if( loginItemsRef == NULL )
    {
        return NO;
    }
    
    loginItems = LSSharedFileListCopySnapshot( loginItemsRef, &seedValue );
    
    for( loginItem in ( __bridge NSArray * )loginItems )
    {    
        loginItemRef = ( __bridge LSSharedFileListItemRef )loginItem;
        
        if( LSSharedFileListItemResolve( loginItemRef, 0, ( CFURLRef * )&path, NULL ) == noErr )
        {
            {
                NSString * s;
                
                s = url.path;
                
                if( s == nil )
                {
                    continue;
                }
                
                if( [ ( ( __bridge NSURL * )path ).path hasPrefix: s ] )
                {
                    CFRelease( path );
                    
                    found = YES;
                    
                    break;
                }
                
                if( path != NULL )
                {
                    CFRelease( path );
                }
            }
        }
    }
    
    if( loginItems != NULL )
    {
        CFRelease( loginItems );
    }
    
    CFRelease( loginItemsRef );

    return found;
}

+ ( void )setLoginItemEnabled: ( BOOL )enabled forBundleURL: ( NSURL * )url
{
    if( enabled )
    {
        [ NSApplication enableLoginItemForBundleURL: url ];
    }
    else
    {
        [ NSApplication disableLoginItemForBundleURL: url ];
    }
}

+ ( void )enableLoginItemForBundleURL: ( NSURL * )url
{
    LSSharedFileListRef     loginItemsRef;
    LSSharedFileListItemRef loginItemRef;
    
    loginItemsRef = LSSharedFileListCreate( NULL, kLSSharedFileListSessionLoginItems, NULL );
    
    if( !loginItemsRef )
    {
        return;
    }
    
	loginItemRef = LSSharedFileListInsertItemURL
    (
        loginItemsRef,
        kLSSharedFileListItemLast,
        NULL,
        NULL,
        ( __bridge CFURLRef )url,
        NULL,
        NULL
    );		
	
    if( loginItemRef )
    {
		CFRelease( loginItemRef );
    }
}

+ ( void )disableLoginItemForBundleURL: ( NSURL * )url
{
    UInt32                  seedValue;
    CFURLRef                path;
    CFArrayRef              loginItems;
    LSSharedFileListRef     loginItemsRef;
    id                      loginItem;
    LSSharedFileListItemRef loginItemRef;
    
    path          = NULL;
    seedValue     = 0;
    loginItemsRef = LSSharedFileListCreate( NULL, kLSSharedFileListSessionLoginItems, NULL );
    
    if( !loginItemsRef )
    {
        return;
    }
    
    loginItems = LSSharedFileListCopySnapshot( loginItemsRef, &seedValue );
    
    for( loginItem in ( __bridge NSArray * )loginItems )
    {		
        loginItemRef = ( __bridge LSSharedFileListItemRef )loginItem;
        
        if( LSSharedFileListItemResolve( loginItemRef, 0, ( CFURLRef * )&path, NULL ) == noErr )
        {
            {
                NSString * s;
                
                s = url.path;
                
                if( s == nil )
                {
                    continue;
                }
                
                if( [ ( ( __bridge NSURL * )path ).path hasPrefix: s ] )
                {
                    CFRelease( path );
                    LSSharedFileListItemRemove( loginItemsRef, loginItemRef );
                    
                    break;
                }
                
                if( path != NULL )
                {
                    CFRelease( path );
                }
            }
        }
    }
    
    if( loginItems != NULL )
    {
        CFRelease( loginItems );
    }
}

- ( BOOL )isLoginItemEnabled
{
	if (@available(macOS 13.0, *)) {
		
		SMAppServiceStatus status		= SMAppService.mainAppService.status;
		NSLog(@"SMAppServiceStatus=%li", status);
		return status == SMAppServiceStatusEnabled;
	} else {
		return [ NSApplication isLoginItemEnabledForBundleURL: [ NSURL fileURLWithPath: [ [ NSBundle mainBundle ] bundlePath ] ] ];
	}
}

- ( void )setLoginItemEnabled: ( BOOL )enabled
{
	if (@available(macOS 13.0, *)) {
		
		NSError *error;
		
		if (enabled) {
			[SMAppService.mainAppService registerAndReturnError:&error];
			NSLog(@"SMAppService   Registered with error: %@",error);
		} else {
			NSLog(@"SMAppService Unregistered with error: %@",error);
			[SMAppService.mainAppService unregisterAndReturnError:&error];
		}
	} else {
		[ NSApplication setLoginItemEnabled: enabled forBundleURL: [ NSURL fileURLWithPath: [ [ NSBundle mainBundle ] bundlePath ] ] ];
	}
}

- ( void )enableLoginItem
{
    [ NSApplication enableLoginItemForBundleURL: [ NSURL fileURLWithPath: [ [ NSBundle mainBundle ] bundlePath ] ] ];
}

- ( void )disableLoginItem
{
    [ NSApplication disableLoginItemForBundleURL: [ NSURL fileURLWithPath: [ [ NSBundle mainBundle ] bundlePath ] ] ];
}

@end
