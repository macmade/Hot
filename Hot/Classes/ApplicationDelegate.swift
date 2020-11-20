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

import Cocoa
import GitHubUpdates

@NSApplicationMain
class ApplicationDelegate: NSObject, NSApplicationDelegate
{
    private var statusItem:                  NSStatusItem?
    private var aboutWindowController:       AboutWindowController?
    private var preferencesWindowController: PreferencesWindowController?
    private var infoViewController:          InfoViewController?
    private var observations:                [ NSKeyValueObservation ] = []
    
    @IBOutlet private var menu:    NSMenu!
    @IBOutlet private var updater: GitHubUpdater!
    
    func applicationDidFinishLaunching( _ notification: Notification )
    {
        if UserDefaults.standard.object( forKey: "LastLaunch" ) == nil
        {
            UserDefaults.standard.setValue( true,     forKey: "automaticallyCheckForUpdates" )
            UserDefaults.standard.setValue( true,     forKey: "displayCPUTemperature" )
            UserDefaults.standard.setValue( true,     forKey: "colorizeStatusItemText" )
            UserDefaults.standard.setValue( NSDate(), forKey: "LastLaunch" )
        }
        
        self.aboutWindowController             = AboutWindowController()
        self.preferencesWindowController       = PreferencesWindowController()
        self.statusItem                        = NSStatusBar.system.statusItem( withLength: NSStatusItem.variableLength )
        self.statusItem?.button?.image         = NSImage( named: "StatusIconTemplate" )
        self.statusItem?.button?.imagePosition = .imageLeading
        self.statusItem?.button?.font          = NSFont.monospacedDigitSystemFont( ofSize: NSFont.smallSystemFontSize, weight: .light )
        self.statusItem?.menu                  = self.menu
        
        let infoViewController             = InfoViewController()
        self.infoViewController            = infoViewController
        self.menu.item( withTag: 1 )?.view = infoViewController.view
        
        let o1 = infoViewController.observe( \.speedLimit     ) { [ weak self ] _, _ in self?.updateTitle() }
        let o2 = infoViewController.observe( \.cpuTemperature ) { [ weak self ] _, _ in self?.updateTitle() }
        
        self.observations.append( contentsOf: [ o1, o2 ] )
        
        if UserDefaults.standard.bool( forKey: "automaticallyCheckForUpdates" )
        {
            DispatchQueue.main.asyncAfter( deadline: .now() + .seconds( 2 ) )
            {
                self.updater.checkForUpdatesInBackground()
            }
        }
        
        Timer.scheduledTimer( withTimeInterval: 3600, repeats: true )
        {
            _ in 
            
            if UserDefaults.standard.bool( forKey: "automaticallyCheckForUpdates" )
            {
                self.updater.checkForUpdatesInBackground()
            }
        }
    }
    
    @IBAction public func showAboutWindow( _ sender: Any? )
    {
        guard let window = self.aboutWindowController?.window else
        {
            NSSound.beep()
            
            return
        }
        
        if window.isVisible == false
        {
            window.layoutIfNeeded()
            window.center()
        }
        
        NSApp.activate( ignoringOtherApps: true )
        window.makeKeyAndOrderFront( nil )
    }
    
    @IBAction public func showPreferencesWindow( _ sender: Any? )
    {
        guard let window = self.preferencesWindowController?.window else
        {
            NSSound.beep()
            
            return
        }
        
        if window.isVisible == false
        {
            window.layoutIfNeeded()
            window.center()
        }
        
        NSApp.activate( ignoringOtherApps: true )
        window.makeKeyAndOrderFront( nil )
    }
    
    @IBAction public func checkForUpdates( _ sender: Any? )
    {
        self.updater.checkForUpdates( sender )
    }
    
    private func updateTitle()
    {
        var title = ""
        
        if let n1 = self.infoViewController?.speedLimit,
           let n2 = self.infoViewController?.cpuTemperature,
           UserDefaults.standard.bool( forKey: "displayCPUTemperature" ),
           n1 > 0,
           n2 > 0
        {
            title = "\( n1 )% \( n2 )°"
        }
        else if let n = self.infoViewController?.speedLimit, n > 0
        {
            title = "\( n )%"
        }
        
        if title.count == 0
        {
            self.statusItem?.button?.title = ""
        }
        else
        {
            let color = self.infoViewController?.speedLimit ?? 100 < 60 && UserDefaults.standard.bool( forKey: "colorizeStatusItemText" ) ? NSColor.orange : NSColor.controlTextColor
            
            self.statusItem?.button?.attributedTitle = NSAttributedString( string: title, attributes: [ .foregroundColor : color ] )
        }
    }
}
