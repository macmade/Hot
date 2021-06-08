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

public class InfoViewController: NSViewController
{
    private var timer:        Timer?
    private var observations: [ NSKeyValueObservation ] = []
    
    @objc public private( set ) dynamic var log                 = ThermalLog()
    @objc public private( set ) dynamic var schedulerLimit: Int = 0
    @objc public private( set ) dynamic var availableCPUs:  Int = 0
    @objc public private( set ) dynamic var speedLimit:     Int = 0
    @objc public private( set ) dynamic var cpuTemperature: Int = 0
    
    @IBOutlet private var graphView:       GraphView!
    @IBOutlet private var graphViewHeight: NSLayoutConstraint!
    
    public override var nibName: NSNib.Name?
    {
        "InfoViewController"
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.graphViewHeight.constant = 0
        
        let o1 = self.log.observe( \.schedulerLimit ) { [ weak self ] _, _ in self?.update() }
        let o2 = self.log.observe( \.availableCPUs  ) { [ weak self ] _, _ in self?.update() }
        let o3 = self.log.observe( \.speedLimit     ) { [ weak self ] _, _ in self?.update() }
        let o4 = self.log.observe( \.cpuTemperature ) { [ weak self ] _, _ in self?.update() }
        
        self.observations.append( contentsOf: [ o1, o2, o3, o4 ] )
        
        let timer = Timer( timeInterval: 2, repeats: true )
        {
            _ in self.log.refresh()
        }
        
        RunLoop.main.add( timer, forMode: .common )
        
        self.timer = timer
        
        self.log.refresh()
    }
    
    private func update()
    {
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
        
        if let n = self.log.cpuTemperature?.intValue
        {
            self.cpuTemperature = n
        }
        
        if self.speedLimit > 0 && self.cpuTemperature > 0
        {
            self.graphView.addData( speed: self.speedLimit, temperature: self.cpuTemperature )
        }
        else if self.cpuTemperature > 0
        {
            self.graphView.addData( speed: 100, temperature: self.cpuTemperature )
        }
        
        self.graphViewHeight.constant = self.graphView.canDisplay ? 100 : 0
    }
}
