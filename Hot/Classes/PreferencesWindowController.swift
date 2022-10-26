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

public class PreferencesWindowController: NSWindowController
{
    @objc public dynamic var displayCPUTemperature = UserDefaults.standard.bool( forKey: "displayCPUTemperature" )
    {
        didSet
        {
            UserDefaults.standard.setValue( self.displayCPUTemperature, forKey: "displayCPUTemperature" )
        }
    }

    @objc public dynamic var colorizeStatusItemText = UserDefaults.standard.bool( forKey: "colorizeStatusItemText" )
    {
        didSet
        {
            UserDefaults.standard.setValue( self.colorizeStatusItemText, forKey: "colorizeStatusItemText" )
        }
    }

    @objc public dynamic var convertToFahrenheit = UserDefaults.standard.bool( forKey: "convertToFahrenheit" )
    {
        didSet
        {
            UserDefaults.standard.setValue( self.convertToFahrenheit, forKey: "convertToFahrenheit" )
        }
    }

    @objc public dynamic var automaticallyCheckForUpdates = UserDefaults.standard.bool( forKey: "automaticallyCheckForUpdates" )
    {
        didSet
        {
            UserDefaults.standard.setValue( self.automaticallyCheckForUpdates, forKey: "automaticallyCheckForUpdates" )
        }
    }

    @objc public dynamic var hideStatusIcon = UserDefaults.standard.bool( forKey: "hideStatusIcon" )
    {
        didSet
        {
            UserDefaults.standard.setValue( self.hideStatusIcon, forKey: "hideStatusIcon" )
        }
    }

    @objc public dynamic var refreshInterval = UserDefaults.standard.integer( forKey: "refreshInterval" )
    {
        didSet
        {
            UserDefaults.standard.setValue( self.refreshInterval, forKey: "refreshInterval" )
        }
    }

    @objc public dynamic var fontName = UserDefaults.standard.string( forKey: "fontName" ) ?? "Default"
    {
        didSet
        {
            if self.fontName == "Default"
            {
                UserDefaults.standard.setValue( nil, forKey: "fontName" )
            }
            else
            {
                UserDefaults.standard.setValue( self.fontName, forKey: "fontName" )
            }
        }
    }

    @objc public dynamic var startAtLogin = NSApp.isLoginItemEnabled()
    {
        didSet
        {
            NSApp.setLoginItemEnabled( self.startAtLogin )
        }
    }

    @objc private dynamic var isAppleSilicon             = false
    @objc private dynamic var colorizeStatusItemTextLabel: String?

    public override var windowNibName: NSNib.Name?
    {
        return "PreferencesWindowController"
    }

    public override func windowDidLoad()
    {
        super.windowDidLoad()

        #if arch( arm64 )
            self.colorizeStatusItemTextLabel = "Colorize the status item text if the thermal pressure is not nominal"
            self.isAppleSilicon              = true
        #else
            self.colorizeStatusItemTextLabel = "Colorize the status item text if the CPU speed limit is below 60%"
            self.isAppleSilicon              = false
        #endif
    }

    private var fontPanel: NSFontPanel?

    @IBAction
    private func chooseFont( _ sender: Any? )
    {
        if let panel = self.fontPanel
        {
            panel.makeKeyAndOrderFront( sender )

            return
        }

        let panel      = NSFontManager.shared.fontPanel( true )
        self.fontPanel = panel

        panel?.makeKeyAndOrderFront( sender )
    }

    @IBAction
    private func resetFont( _ sender: Any? )
    {
        self.fontName = "Default"
    }

    @IBAction
    public func changeFont( _ sender: Any? )
    {
        let selected  = NSFontManager.shared.selectedFont
        let font      = NSFontManager.shared.convert( selected ?? NSFont.systemFont( ofSize: NSFont.systemFontSize ) )
        self.fontName = "\( font.fontName ) \( Int( font.pointSize ) )"
    }
}
