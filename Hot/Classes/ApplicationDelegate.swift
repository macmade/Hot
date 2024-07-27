/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2023, Jean-David Gadina - www.xs-labs.com
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

import Cocoa
import GitHubUpdates
import SensorsUI

@NSApplicationMain
class ApplicationDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate
{
    private var statusItem:                    NSStatusItem?
    private var aboutWindowController:         AboutWindowController?
    private var preferencesWindowController:   PreferencesWindowController?
    private var sensorsWindowController:       SensorsWindowController?
    private var selectSensorsWindowController: SelectSensorsWindowController?
    private var sensorViewControllers:         [ SensorViewController  ] = []
    private var fanViewControllers:            [ FanViewController ] = []
    private var graphWindowController:         GraphWindowController?
    private var exiting                      = false

    @IBOutlet private var menu:        NSMenu!
    @IBOutlet private var sensorsMenu: NSMenu!
    @IBOutlet private var fansMenu:    NSMenu!
    @IBOutlet private var updater:     GitHubUpdater!

    @objc public private( set ) dynamic var infoViewController: InfoViewController?

    deinit
    {
        UserDefaults.standard.removeObserver( self, forKeyPath: "displayCPUTemperature" )
        UserDefaults.standard.removeObserver( self, forKeyPath: "displaySchedulerLimit" )
        UserDefaults.standard.removeObserver( self, forKeyPath: "colorizeStatusItemText" )
        UserDefaults.standard.removeObserver( self, forKeyPath: "convertToFahrenheit" )
        UserDefaults.standard.removeObserver( self, forKeyPath: "hideStatusIcon" )
    }

    func applicationDidFinishLaunching( _ notification: Notification )
    {
        self.initializePreferences()

        self.aboutWindowController             = AboutWindowController()
        self.preferencesWindowController       = PreferencesWindowController()
        self.selectSensorsWindowController     = SelectSensorsWindowController()
        self.statusItem                        = NSStatusBar.system.statusItem( withLength: NSStatusItem.variableLength )
        self.statusItem?.button?.image         = NSImage( named: "StatusIconTemplate" )
        self.statusItem?.button?.imagePosition = .imageLeading
        self.statusItem?.menu                  = self.menu

        self.updateMenuFont()

        let infoViewController             = InfoViewController()
        self.infoViewController            = infoViewController
        self.menu.item( withTag: 1 )?.view = infoViewController.view
        self.infoViewController?.onUpdate  =
        {
            [ weak self ] in

            self?.updateTitle()
            self?.updateSensors()

            self?.graphWindowController?.graphView?.data = self?.infoViewController?.graphView?.data ?? []
            self?.graphWindowController?.schedulerLimit  = self?.infoViewController?.schedulerLimit  ?? 0
            self?.graphWindowController?.availableCPUs   = self?.infoViewController?.availableCPUs   ?? 0
            self?.graphWindowController?.speedLimit      = self?.infoViewController?.speedLimit      ?? 0
            self?.graphWindowController?.temperature     = self?.infoViewController?.temperature     ?? 0
            self?.graphWindowController?.fanSpeed        = self?.infoViewController?.fanSpeed     ?? 0
            self?.graphWindowController?.thermalPressure = self?.infoViewController?.thermalPressure ?? 0
        }

        UserDefaults.standard.addObserver( self, forKeyPath: "displayCPUTemperature",  options: [], context: nil )
        UserDefaults.standard.addObserver( self, forKeyPath: "displaySchedulerLimit",  options: [], context: nil )
        UserDefaults.standard.addObserver( self, forKeyPath: "colorizeStatusItemText", options: [], context: nil )
        UserDefaults.standard.addObserver( self, forKeyPath: "convertToFahrenheit",    options: [], context: nil )
        UserDefaults.standard.addObserver( self, forKeyPath: "hideStatusIcon",         options: [], context: nil )
        UserDefaults.standard.addObserver( self, forKeyPath: "fontName",               options: [], context: nil )

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

        if UserDefaults.standard.bool( forKey: "showGraphPanel" )
        {
            DispatchQueue.main.asyncAfter( deadline: .now() + .seconds( 1 ) )
            {
                self.detachGraph( nil )
            }
        }
    }

    func applicationWillTerminate( _ notification: Notification )
    {
        self.exiting = true
    }

    private func initializePreferences()
    {
        if UserDefaults.standard.object( forKey: "LastLaunch" ) == nil
        {
            UserDefaults.standard.setValue( true,     forKey: "automaticallyCheckForUpdates" )
            UserDefaults.standard.setValue( true,     forKey: "displayCPUTemperature" )
            UserDefaults.standard.setValue( true,     forKey: "displaySchedulerLimit" )
            UserDefaults.standard.setValue( true,     forKey: "colorizeStatusItemText" )
            UserDefaults.standard.setValue( NSDate(), forKey: "LastLaunch" )
        }

        if UserDefaults.standard.object( forKey: "refreshInterval" ) == nil
        {
            UserDefaults.standard.setValue( 2, forKey: "refreshInterval" )
        }

        if UserDefaults.standard.object( forKey: "sensorsWindowShowTemperature" ) == nil
        {
            UserDefaults.standard.setValue( true, forKey: "sensorsWindowShowTemperature" )
        }

        if UserDefaults.standard.object( forKey: "sensorsWindowShowVoltage" ) == nil
        {
            UserDefaults.standard.setValue( true, forKey: "sensorsWindowShowVoltage" )
        }

        if UserDefaults.standard.object( forKey: "sensorsWindowShowCurrent" ) == nil
        {
            UserDefaults.standard.setValue( true, forKey: "sensorsWindowShowCurrent" )
        }

        if UserDefaults.standard.object( forKey: "displaySchedulerLimit" ) == nil
        {
            // Added in 1.8.0
            UserDefaults.standard.setValue( true, forKey: "displaySchedulerLimit" )
        }
    }

    private func updateMenuFont()
    {
        let system = NSFont.monospacedDigitSystemFont( ofSize: NSFont.smallSystemFontSize, weight: .light )

        guard let fontName = UserDefaults.standard.string( forKey: "fontName" )
        else
        {
            self.statusItem?.button?.font = system

            return
        }

        let parts = fontName.split( separator: " " )

        guard parts.count >= 2, let last = parts.last, let size = Int( String( last ) )
        else
        {
            self.statusItem?.button?.font = system

            return
        }

        let name                      = parts.dropLast().joined( separator: " " )
        self.statusItem?.button?.font = NSFont( name: name, size: CGFloat( size ) ) ?? system
    }

    override func observeValue( forKeyPath keyPath: String?, of object: Any?, change: [ NSKeyValueChangeKey: Any ]?, context: UnsafeMutableRawPointer? )
    {
        let keyPaths =
            [
                "displayCPUTemperature",
                "displaySchedulerLimit",
                "colorizeStatusItemText",
                "convertToFahrenheit",
                "hideStatusIcon",
                "fontName",
            ]

        if let keyPath = keyPath, let object = object as? NSObject, object == UserDefaults.standard, keyPaths.contains( keyPath )
        {
            self.updateMenuFont()
            self.updateTitle()
            self.updateSensors()
        }
        else
        {
            super.observeValue( forKeyPath: keyPath, of: object, change: change, context: context )
        }
    }

    @IBAction
    public func showAboutWindow( _ sender: Any? )
    {
        guard let window = self.aboutWindowController?.window
        else
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

    @IBAction
    public func showPreferencesWindow( _ sender: Any? )
    {
        guard let window = self.preferencesWindowController?.window
        else
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

    @IBAction
    public func showSelectSensorsWindow( _ sender: Any? )
    {
        guard let window = self.selectSensorsWindowController?.window
        else
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

    @IBAction
    public func checkForUpdates( _ sender: Any? )
    {
        self.updater.checkForUpdates( sender )
    }

    private func updateTitle()
    {
        var title       = ""
        let transformer = TemperatureToString()

        if let n1 = self.infoViewController?.speedLimit,
           let n2 = self.infoViewController?.temperature,
           UserDefaults.standard.bool( forKey: "displaySchedulerLimit" ),
           UserDefaults.standard.bool( forKey: "displayCPUTemperature" ),
           n1 > 0,
           n2 > 0
        {
            let temp = transformer.transformedValue( n2 ) as? String ?? "--"
            title    = "\( n1 )% \( temp )"
        }
        else if let n = self.infoViewController?.speedLimit, n > 0,
                UserDefaults.standard.bool( forKey: "displaySchedulerLimit" )
        {
            title = "\( n )%"
        }
        else if let n = self.infoViewController?.temperature,
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
                if UserDefaults.standard.bool( forKey: "colorizeStatusItemText" ) == false
                {
                    return .controlTextColor
                }

                let limit = self.infoViewController?.speedLimit ?? 100

                if limit > 0, limit < 60
                {
                    return .orange
                }

                if let rawPressure = self.infoViewController?.thermalPressure,
                   let pressure    = ProcessInfo.ThermalState( rawValue: rawPressure ),
                   pressure       != .nominal
                {
                    return .orange
                }

                return .controlTextColor
            }()

            self.statusItem?.button?.attributedTitle = NSAttributedString( string: title, attributes: [ .foregroundColor: color ] )
        }

        if UserDefaults.standard.bool( forKey: "hideStatusIcon" ), title.count > 0
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
        if self.sensorViewControllers.isEmpty
        {
            self.sensorsMenu.removeAllItems()
        }
        if self.fanViewControllers.isEmpty
        {
            self.fansMenu.removeAllItems()
        }

        guard let sensors = self.infoViewController?.log.sensors
        else
        {
            return
        }
        guard let fans = self.infoViewController?.log.fans
        else
        {
            return
        }

        var controllers = self.sensorViewControllers
        var fanControllers = self.fanViewControllers
        var items       = self.sensorsMenu.items
        var fanItems    = self.fansMenu.items

        controllers.removeAll { item in sensors.contains { $0.key == item.name  } == false }
        items.removeAll       { item in sensors.contains { $0.key == item.title } == false }
        fanItems.removeAll    { item in fans.contains { $0.key == item.title } == false }

        sensors.forEach
        {
            sensor in

            if let controller = self.sensorViewControllers.first( where: { $0.name  == sensor.key } )
            {
                controller.value = Int( sensor.value )
            }
            else
            {
                let controller   = SensorViewController()
                controller.name  = sensor.key
                controller.value = Int( sensor.value )
                let item         = NSMenuItem( title: sensor.key, action: nil, keyEquivalent: "" )
                item.view        = controller.view

                items.append( item )
                controllers.append( controller )
            }
        }

        self.sensorViewControllers = controllers

        self.sensorsMenu.removeAllItems()

        items.sorted
        {
            $0.title.compare( $1.title, options: [ .numeric, .caseInsensitive ], range: nil, locale: nil ) == .orderedAscending
        }
        .forEach
        {
            self.sensorsMenu.addItem( $0 )
        }

        fans.forEach
        {
            fan in

            if let controller = self.fanViewControllers.first( where: { $0.name  == fan.key } )
            {
                controller.value = Int( fan.value )
            }
            else
            {
                let controller   = FanViewController()
                controller.name  = fan.key
                controller.value = Int( fan.value )
                let item         = NSMenuItem( title: fan.key, action: nil, keyEquivalent: "" )
                item.view        = controller.view

                fanItems.append( item )
                fanControllers.append( controller )
            }
        }

        self.fanViewControllers = fanControllers

        self.fansMenu.removeAllItems()


        fanItems.sorted
        {
            $0.title.compare( $1.title, options: [ .numeric, .caseInsensitive ], range: nil, locale: nil ) == .orderedAscending
        }
        .forEach
        {
            self.fansMenu.addItem( $0 )
        }
    }

    @IBAction
    public func viewAllSensors( _ sender: Any? )
    {
        if self.sensorsWindowController == nil
        {
            self.sensorsWindowController = SensorsWindowController()
        }

        guard let window = self.sensorsWindowController?.window
        else
        {
            NSSound.beep()

            return
        }

        window.delegate = self

        if window.isVisible == false
        {
            window.layoutIfNeeded()
            window.center()
        }

        NSApp.activate( ignoringOtherApps: true )
        window.makeKeyAndOrderFront( nil )
    }

    func windowWillClose( _ notification: Notification )
    {
        guard let window = notification.object as? NSWindow
        else
        {
            return
        }

        if window == self.sensorsWindowController?.window
        {
            self.sensorsWindowController?.stop( completion: nil )

            self.sensorsWindowController = nil
        }
        else if window == self.graphWindowController?.window
        {
            self.graphWindowController = nil

            if self.exiting == false
            {
                UserDefaults.standard.set( false, forKey: "showGraphPanel" )
            }
        }
    }

    @IBAction
    public func detachGraph( _ sender: Any? )
    {
        if self.graphWindowController == nil
        {
            self.graphWindowController                  = GraphWindowController()
            self.graphWindowController?.graphView?.data = self.infoViewController?.graphView?.data ?? []
        }

        guard let window = self.graphWindowController?.window
        else
        {
            NSSound.beep()

            return
        }

        window.delegate = self

        if UserDefaults.standard.object( forKey: "NSWindow Frame GraphPanel" ) == nil
        {
            window.layoutIfNeeded()
            window.center()
        }

        NSApp.activate( ignoringOtherApps: true )
        window.makeKeyAndOrderFront( nil )
        UserDefaults.standard.set( true, forKey: "showGraphPanel" )
    }
}
