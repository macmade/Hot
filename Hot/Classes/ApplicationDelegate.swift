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
    private var observations:                [ NSKeyValueObservation ] = []
    private var sensorViewControllers:       [ SensorViewController  ] = []
    
    @IBOutlet private var menu:        NSMenu!
    @IBOutlet private var sensorsMenu: NSMenu!
    @IBOutlet private var updater:     GitHubUpdater!
    
    @objc public private( set ) dynamic var infoViewController: InfoViewController?
    
    deinit
    {
        UserDefaults.standard.removeObserver( self, forKeyPath: "displayCPUTemperature" )
        UserDefaults.standard.removeObserver( self, forKeyPath: "colorizeStatusItemText" )
        UserDefaults.standard.removeObserver( self, forKeyPath: "convertToFahrenheit" )
        UserDefaults.standard.removeObserver( self, forKeyPath: "hideStatusIcon" )
    }
    
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
        let o3 = infoViewController.observe( \.log.sensors    ) { [ weak self ] _, _ in self?.updateSensors() }
        
        self.observations.append( contentsOf: [ o1, o2, o3 ] )
        
        UserDefaults.standard.addObserver( self, forKeyPath: "displayCPUTemperature",  options: [], context: nil )
        UserDefaults.standard.addObserver( self, forKeyPath: "colorizeStatusItemText", options: [], context: nil )
        UserDefaults.standard.addObserver( self, forKeyPath: "convertToFahrenheit",    options: [], context: nil )
        UserDefaults.standard.addObserver( self, forKeyPath: "hideStatusIcon",         options: [], context: nil )
        
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
    
    override func observeValue( forKeyPath keyPath: String?, of object: Any?, change: [ NSKeyValueChangeKey : Any ]?, context: UnsafeMutableRawPointer? )
    {
        let keyPaths =
        [
            "displayCPUTemperature",
            "colorizeStatusItemText",
            "convertToFahrenheit",
            "hideStatusIcon"
        ]
        
        if let keyPath = keyPath, let object = object as? NSObject, object == UserDefaults.standard && keyPaths.contains( keyPath )
        {
            self.updateTitle()
            self.updateSensors()
        }
        else
        {
            super.observeValue( forKeyPath: keyPath, of: object, change: change, context: context )
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
        var title       = ""
        let transformer = TemperatureToString()
        
        if let n1 = self.infoViewController?.speedLimit,
           let n2 = self.infoViewController?.cpuTemperature,
           UserDefaults.standard.bool( forKey: "displayCPUTemperature" ),
           n1 > 0,
           n2 > 0
        {
            let temp = transformer.transformedValue( n2 ) as? String ?? "--"
            title    = "\( n1 )% \( temp )"
        }
        else if let n = self.infoViewController?.speedLimit, n > 0
        {
            title = "\( n )%"
        }
        else if let n = self.infoViewController?.cpuTemperature,
                UserDefaults.standard.bool( forKey: "displayCPUTemperature" ),
                n > 0
        {
            title = transformer.transformedValue( n ) as? String ?? "--"
        }
        
        if title.count == 0
        {
            self.statusItem?.button?.title = ""
        }
        else
        {
            let color: NSColor =
            {
                let limit = self.infoViewController?.speedLimit ?? 100
                
                if limit > 0 && limit < 60 && UserDefaults.standard.bool( forKey: "colorizeStatusItemText" )
                {
                    return .orange
                }
                
                return .controlTextColor
            }()
            
            self.statusItem?.button?.attributedTitle = NSAttributedString( string: title, attributes: [ .foregroundColor : color ] )
        }
        
        if UserDefaults.standard.bool( forKey: "hideStatusIcon" ) && title.count > 0
        {
            self.statusItem?.button?.image = nil
        }
        else
        {
            self.statusItem?.button?.image = NSImage( named: "StatusIconTemplate" )
        }
    }
    
    private func updateSensors()
    {
        self.sensorsMenu.removeAllItems()
        self.sensorViewControllers.removeAll()
        
        self.infoViewController?.log.sensors.sorted
        {
            $0.key.compare( $1.key, options: .numeric, range: nil, locale: nil ) == .orderedAscending
        }
        .forEach
        {
            let controller   = SensorViewController()
            controller.name  = $0.key
            controller.value = Int( $0.value )
            let item         = NSMenuItem( title: $0.key, action: nil, keyEquivalent: "" )
            item.view        = controller.view
            
            self.sensorsMenu.addItem( item )
        }
    }
}
