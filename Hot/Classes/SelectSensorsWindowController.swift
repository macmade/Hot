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

import Cocoa

public class SelectSensorsWindowController: NSWindowController, NSTableViewDelegate
{
    @objc private dynamic var items         = [ SensorItem ]()
    @objc private dynamic var selectionMode = UserDefaults.standard.integer( forKey: "selectedSensorsMode" )

    private var windowOpenObserver:  Any?
    private var windowCloseObserver: Any?
    private var updateTimer:         Timer?

    @IBOutlet private var arrayController: NSArrayController!

    public init()
    {
        super.init( window: nil )
    }

    required init?( coder: NSCoder )
    {
        nil
    }

    public override var windowNibName: NSNib.Name?
    {
        "SelectSensorsWindowController"
    }

    public override func windowDidLoad()
    {
        super.windowDidLoad()

        self.arrayController.sortDescriptors =
            [
                NSSortDescriptor( key: "name", ascending: true, selector: #selector( NSString.localizedCaseInsensitiveCompare( _: ) ) ),
            ]

        self.windowOpenObserver = NotificationCenter.default.addObserver( forName: NSWindow.didBecomeKeyNotification, object: self.window, queue: nil )
        {
            [ weak self ] _ in

            guard let self = self
            else
            {
                return
            }

            if self.updateTimer == nil
            {
                self.update()

                self.updateTimer = Timer.scheduledTimer( withTimeInterval: 1, repeats: true )
                {
                    [ weak self ] _ in self?.update()
                }
            }
        }

        self.windowCloseObserver = NotificationCenter.default.addObserver( forName: NSWindow.willCloseNotification, object: self.window, queue: nil )
        {
            [ weak self ] _ in

            guard let self = self
            else
            {
                return
            }

            self.updateTimer?.invalidate()

            self.updateTimer = nil
        }
    }

    @IBAction
    private func cancel( _ sender: Any? )
    {
        self.window?.close()
    }

    @IBAction
    private func save( _ sender: Any? )
    {
        let sensors = self.items.filter
        {
            $0.enabled
        }
        .map
        {
            $0.name
        }

        UserDefaults.standard.set( sensors, forKey: "selectedSensors" )
        UserDefaults.standard.set( self.selectionMode, forKey: "selectedSensorsMode" )
        self.window?.close()
    }

    private func update()
    {
        guard let delegate = NSApp.delegate as? ApplicationDelegate,
              let log      = delegate.infoViewController?.log
        else
        {
            return
        }

        let selected = UserDefaults.standard.object( forKey: "selectedSensors" ) as? [ String ] ?? []

        self.items = log.sensors.map
        {
            let item = SensorItem( name: $0.key, enabled: false, temperature: $0.value )

            if let existing = self.items.first( where: { $0.name == item.name } )
            {
                item.enabled = existing.enabled
            }
            else if let _ = selected.first( where: { $0 == item.name } )
            {
                item.enabled = true
            }

            return item
        }
    }

    public func tableView( _ tableView: NSTableView, shouldSelectRow row: Int ) -> Bool
    {
        false
    }

    private class SensorItem: NSObject
    {
        @objc public dynamic var name:        String
        @objc public dynamic var enabled:     Bool
        @objc public dynamic var temperature: Double

        public init( name: String, enabled: Bool, temperature: Double )
        {
            self.name        = name
            self.enabled     = enabled
            self.temperature = temperature
        }

        override func isEqual( to object: Any? ) -> Bool
        {
            self.isEqual( object )
        }

        override func isEqual( _ object: Any? ) -> Bool
        {
            guard let item = object as? SensorItem
            else
            {
                return false
            }

            return self.name == item.name
        }
    }

    @IBAction
    private func toggleAll( _ sender: Any? )
    {
        let allSelected = self.items.reduce( true )
        {
            $0 == false ? false : $1.enabled
        }

        if allSelected
        {
            self.items.forEach { $0.enabled = false }
        }
        else
        {
            self.items.forEach { $0.enabled = true }
        }
    }
}
