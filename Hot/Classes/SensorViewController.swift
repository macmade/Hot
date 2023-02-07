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

public class SensorViewController: NSViewController
{
    @objc private dynamic var icon  = NSImage( named: "Unknown" )
    @objc private dynamic var label = "Unknown:"
    @objc public  dynamic var value = 0
    @objc public  dynamic var name  = "Unknown"
    {
        didSet {
            self.label = self.name.hasSuffix(":") ? self.name : "\(self.name):"
            
            let lowercasedName = self.name.lowercased()
            switch true {
            case lowercasedName.hasPrefix("eacc"):
                self.icon = NSImage(named: "eAccTemplate")
            case lowercasedName.hasPrefix("pacc"):
                self.icon = NSImage(named: "pAccTemplate")
            case lowercasedName.hasPrefix("tcxc"):
                self.icon = NSImage(named: "TCXCTemplate")
            case lowercasedName.contains("battery"):
                self.icon = NSImage(named: "BatteryTemplate")
            case lowercasedName.contains("tcal"):
                self.icon = NSImage(named: "TCalTemplate")
            default:
                self.icon = NSImage(named: "UnknownTemplate")
            }
        }
    }

    public override var nibName: NSNib.Name?
    {
        "SensorViewController"
    }
}
