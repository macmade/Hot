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

public class InfoViewController: NSViewController
{
    private var timer: Timer?

    @objc public private( set ) dynamic var log                   = ThermalLog()
    @objc public private( set ) dynamic var schedulerLimit:  Int  = 0
    @objc public private( set ) dynamic var availableCPUs:   Int  = 0
    @objc public private( set ) dynamic var speedLimit:      Int  = 0
    @objc public private( set ) dynamic var temperature:     Int  = 0
    @objc public private( set ) dynamic var thermalPressure: Int  = 0
    @objc public private( set ) dynamic var hasSensors:      Bool = false

    public var onUpdate: ( () -> Void )?

    #if arch( arm64 )
        @objc public private( set ) dynamic var isARM = true
    #else
        @objc public private( set ) dynamic var isARM = false
    #endif

    @IBOutlet public private( set ) var graphView:       GraphView?
    @IBOutlet private               var graphViewHeight: NSLayoutConstraint!

    deinit
    {
        UserDefaults.standard.removeObserver( self, forKeyPath: "refreshInterval" )
    }

    public override var nibName: NSNib.Name?
    {
        "InfoViewController"
    }

    public override func viewDidLoad()
    {
        super.viewDidLoad()

        self.graphViewHeight.constant = 0

        self.setTimer()
        self.log.refresh
        {
            DispatchQueue.main.async
            {
                self.update()
            }
        }

        UserDefaults.standard.addObserver( self, forKeyPath: "refreshInterval",  options: [], context: nil )
    }

    public override func observeValue( forKeyPath keyPath: String?, of object: Any?, change: [ NSKeyValueChangeKey: Any ]?, context: UnsafeMutableRawPointer? )
    {
        if let object = object as? NSObject, object == UserDefaults.standard, keyPath == "refreshInterval"
        {
            self.setTimer()
        }
        else
        {
            super.observeValue( forKeyPath: keyPath, of: object, change: change, context: context )
        }
    }

    private func setTimer()
    {
        self.timer?.invalidate()

        var interval = UserDefaults.standard.integer( forKey: "refreshInterval" )

        if interval <= 0
        {
            interval = 2
        }

        let timer = Timer( timeInterval: Double( interval ), repeats: true )
        {
            _ in self.log.refresh
            {
                DispatchQueue.main.async
                {
                    self.update()
                }
            }
        }

        RunLoop.main.add( timer, forMode: .common )

        self.timer = timer
    }

    private func update()
    {
        self.hasSensors = self.log.sensors.isEmpty == false

        if let n = self.log.schedulerLimit?.intValue
        {
            self.schedulerLimit = n
        }

        if let n = self.log.availableCPUs?.intValue
        {
            self.availableCPUs = n
        }

        if let n = self.log.speedLimit?.intValue
        {
            self.speedLimit = n
        }

        if let n = self.log.temperature?.intValue
        {
            self.temperature = n
        }

        if let n = self.log.thermalPressure?.intValue
        {
            self.thermalPressure = n
        }

        if self.speedLimit > 0, self.temperature > 0
        {
            self.graphView?.addData( speed: self.speedLimit, temperature: self.temperature )
        }
        else if self.temperature > 0
        {
            self.graphView?.addData( speed: 100, temperature: self.temperature )
        }

        self.graphViewHeight.constant = self.graphView?.canDisplay ?? false ? 100 : 0

        self.onUpdate?()
    }
}
