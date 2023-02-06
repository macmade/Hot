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

import Foundation

@objc
public class GraphWindowController: NSWindowController
{
    @IBOutlet public private( set ) var graphView:   GraphView?

    @objc public dynamic var schedulerLimit:  Int  = 0
    @objc public dynamic var availableCPUs:   Int  = 0
    @objc public dynamic var speedLimit:      Int  = 0
    @objc public dynamic var temperature:     Int  = 0
    @objc public dynamic var thermalPressure: Int  = 0
    @objc public dynamic var showOnAllSpaces: Bool = false
    {
        didSet
        {
            UserDefaults.standard.set( self.showOnAllSpaces, forKey: "showGraphPanelOnAllSpaces" )

            self.window?.collectionBehavior = self.showOnAllSpaces ? .canJoinAllSpaces : []
        }
    }

    #if arch( arm64 )
        @objc public private( set ) dynamic var isARM = true
    #else
        @objc public private( set ) dynamic var isARM = false
    #endif

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
        "GraphWindowController"
    }

    public override func windowDidLoad()
    {
        super.windowDidLoad()

        if UserDefaults.standard.bool( forKey: "showGraphPanelOnAllSpaces" )
        {
            self.showOnAllSpaces = true
        }
    }

    @IBAction
    private func showOptions( _ sender: Any? )
    {
        let menu = NSMenu()
        let item = menu.addItem( withTitle: "Show on All Spaces", action: nil, keyEquivalent: "" )

        item.bind( NSBindingName( "value" ), to: self, withKeyPath: "showOnAllSpaces" )

        if let view  = sender as? NSView,
           let event = NSApp.currentEvent
        {
            NSMenu.popUpContextMenu( menu, with: event, for: view )
        }
    }
}
