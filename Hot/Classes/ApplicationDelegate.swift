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
    private var timer:                 Timer?
    private var statusItem:            NSStatusItem?
    private var observations:          [ NSKeyValueObservation ] = []
    private var aboutWindowController: AboutWindowController?
    
    @IBOutlet private var menu:    NSMenu!
    @IBOutlet private var updater: GitHubUpdater!
    
    @objc public dynamic var log          = ThermalLog()
    @objc public dynamic var startAtLogin = false
    {
        didSet
        {
            NSApp.setLoginItemEnabled( self.startAtLogin )
        }
    }
    
    func applicationDidFinishLaunching( _ notification: Notification )
    {
        self.startAtLogin                      = NSApp.isLoginItemEnabled()
        self.aboutWindowController             = AboutWindowController()
        self.statusItem                        = NSStatusBar.system.statusItem( withLength: NSStatusItem.variableLength )
        self.statusItem?.button?.image         = NSImage( named: "StatusIconTemplate" )
        self.statusItem?.button?.imagePosition = .imageLeading
        self.statusItem?.button?.font          = NSFont.systemFont( ofSize: NSFont.smallSystemFontSize )
        self.statusItem?.menu                  = self.menu
        
        let o1 = self.log.observe( \.schedulerLimit ) { [ weak self ] _, _ in self?.update() }
        let o2 = self.log.observe( \.availableCPUs  ) { [ weak self ] _, _ in self?.update() }
        let o3 = self.log.observe( \.speedLimit     ) { [ weak self ] _, _ in self?.update() }
        
        self.observations.append( contentsOf: [ o1, o2, o3 ] )
        
        self.timer = Timer.scheduledTimer( withTimeInterval: 2, repeats: true )
        {
            _ in self.log.refresh()
        }
        
        self.log.refresh()
        
        DispatchQueue.main.asyncAfter( deadline: .now() + .seconds( 10 ) )
        {
            self.updater.checkForUpdatesInBackground()
        }
    }
    
    func applicationWillTerminate( _ notification: Notification )
    {
        self.timer?.invalidate()
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
            window.center()
        }
        
        window.makeKeyAndOrderFront( nil )
    }
    
    @IBAction public func checkForUpdates( _ sender: Any? )
    {
        self.updater.checkForUpdates( sender )
    }
    
    private func update()
    {
        let item1 = self.menu.item( withTag: 1 )
        let item2 = self.menu.item( withTag: 2 )
        let item3 = self.menu.item( withTag: 3 )
        let item4 = self.menu.item( withTag: 4 )
        
        if let n = self.log.schedulerLimit?.intValue
        {
            item1?.isHidden = false
            item1?.title    = "Scheduler Limit: \( n )"
        }
        else
        {
            item1?.isHidden = true
            item1?.title    = ""
        }
        
        if let n = self.log.availableCPUs?.intValue
        {
            item2?.isHidden = false
            item2?.title    = "Available CPUs: \( n )"
        }
        else
        {
            item2?.isHidden = true
            item2?.title    = ""
        }
        
        if let n = self.log.speedLimit?.intValue
        {
            item3?.isHidden                = false
            item3?.title                   = "Speed Limit: \( n )"
            self.statusItem?.button?.title = "\( n )%"
        }
        else
        {
            item3?.isHidden                = true
            item3?.title                   = ""
            self.statusItem?.button?.title = ""
        }
        
        if let n = self.log.cpuTemperature?.intValue
        {
            item4?.isHidden = false
            item4?.title    = "CPU  Temperature: \( n )"
        }
        else
        {
            item4?.isHidden = true
            item4?.title    = ""
        }
    }
}
