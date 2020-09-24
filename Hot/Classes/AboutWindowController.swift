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

public class AboutWindowController: NSWindowController
{
    @objc private dynamic var name:      String?
    @objc private dynamic var version:   String?
    @objc private dynamic var copyright: String?
    
    public override var windowNibName: NSNib.Name?
    {
        return "AboutWindowController"
    }
    
    override public func windowDidLoad()
    {
        super.windowDidLoad()
        
        let version = Bundle.main.object( forInfoDictionaryKey: "CFBundleShortVersionString" ) as? String ?? "0.0.0"
        
        if let build = Bundle.main.object( forInfoDictionaryKey: "CFBundleVersion" ) as? String
        {
            self.version = "\(version) (\(build))"
        }
        else
        {
            self.version = version
        }
        
        self.name      = Bundle.main.object( forInfoDictionaryKey: "CFBundleName"             ) as? String
        self.copyright = Bundle.main.object( forInfoDictionaryKey: "NSHumanReadableCopyright" ) as? String
    }
}
