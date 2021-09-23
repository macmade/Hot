/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2021 Jean-David Gadina - www.xs-labs.com
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

public class SensorGraphView: NSView
{
    @objc public enum GraphStyle: Int
    {
        case gradient
        case line
        case fill
        case bars
    }
    
    @objc public dynamic var sensor: SensorData?
    
    private var graphStyleObserver: NSKeyValueObservation?
    
    public override init( frame: NSRect )
    {
        super.init( frame: frame )
        UserDefaults.standard.addObserver( self, forKeyPath: "graphStyle", options: .new, context: nil )
    }
    
    required init?( coder: NSCoder )
    {
        super.init( coder: coder )
        UserDefaults.standard.addObserver( self, forKeyPath: "graphStyle", options: .new, context: nil )
    }
    
    deinit
    {
        UserDefaults.standard.removeObserver( self, forKeyPath: "graphStyle" )
    }
    
    public override func observeValue( forKeyPath keyPath: String?, of object: Any?, change: [ NSKeyValueChangeKey : Any ]?, context: UnsafeMutableRawPointer? )
    {
        if let keyPath = keyPath, keyPath == "graphStyle", let object = object as? UserDefaults, object == UserDefaults.standard
        {
            self.needsDisplay = true
        }
        else
        {
            super.observeValue( forKeyPath: keyPath, of: object, change: change, context: context )
        }
    }
    
    private var graphStyle: GraphStyle
    {
        GraphStyle( rawValue: UserDefaults.standard.integer( forKey: "graphStyle" ) ) ?? .gradient
    }
    
    public override func draw( _ rect: NSRect )
    {
        self.drawBorder( in: rect )
        self.drawBackground( in: rect )
        
        guard let sensor = self.sensor, sensor.values.count >= 2 else
        {
            return
        }
        
        let values       = sensor.values.map { CGFloat( $0.doubleValue ) }
        var min: CGFloat = values.min() ?? 0
        var max: CGFloat = values.max() ?? 0
        
        if sensor.kind == .thermal && min >= 0 && max <= 100
        {
            min = 0
            max = 100
        }
        
        if self.graphStyle == .bars
        {
            self.drawBars( in:     rect,
                           kind:   sensor.kind,
                           values: values,
                           min:    min,
                           max:    max,
                           color:  Colors.color( for: sensor.kind )
            )
        }
        else
        {
            self.drawGraph( in:     rect.insetBy( dx: 10, dy: 10 ),
                            kind:   sensor.kind,
                            values: values,
                            min:    min,
                            max:    max,
                            color:  Colors.color( for: sensor.kind )
            )
        }
    }
    
    private func drawBorder( in rect: NSRect )
    {
        if self.graphStyle == .bars
        {
            return
        }
        
        let border       = NSBezierPath( roundedRect: rect.insetBy( dx: 1, dy: 1 ), xRadius: 10, yRadius: 10 )
        border.lineWidth = 1
        
        NSColor.gray.setStroke()
        border.stroke()
    }
    
    private func drawBackground( in rect: NSRect )
    {
        if self.graphStyle == .bars
        {
            let c = 15
            let h = rect.size.height / CGFloat( c )
            let n = rect.size.width / h
            
            for i in 0 ..< Int( n )
            {
                for j in 0 ..< c
                {
                    let square = NSRect( x: rect.origin.x + h * CGFloat( i ), y: rect.origin.y + h * CGFloat( j ), width: h, height: h ).insetBy( dx: 1, dy: 1 )
                    
                    NSColor.gray.withAlphaComponent( 0.2 ).setFill()
                    square.fill()
                }
            }
        }
        else
        {
            let border = NSBezierPath( roundedRect: rect.insetBy( dx: 1, dy: 1 ), xRadius: 10, yRadius: 10 )
            
            NSColor.gray.withAlphaComponent( 0.2 ).setFill()
            border.fill()
        }
    }
    
    private func drawGraph( in rect: NSRect, kind: SensorData.Kind, values: [ CGFloat ], min: CGFloat, max: CGFloat, color: NSColor )
    {
        let p1       = NSBezierPath()
        let p2       = NSBezierPath()
        p1.lineWidth = 1
        p2.lineWidth = 0
        
        if min == max && kind != .thermal
        {
            p1.move( to: NSPoint( x: rect.origin.x, y: rect.origin.y + rect.size.height / 2 ) )
            p1.line( to: NSPoint( x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height / 2 ) )
            p2.move( to: NSPoint( x: rect.origin.x, y: rect.origin.y + rect.size.height / 2 ) )
            p2.line( to: NSPoint( x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height / 2 ) )
        }
        else
        {
            for i in 0 ..< values.count
            {
                let value = values[ i ]
                let dx    = rect.size.width / CGFloat( values.count - 1 )
                let x     = rect.origin.x + CGFloat( i ) * dx
                let v     = ( value - min ) / ( max - min )
                let y     = rect.origin.y + v * rect.size.height
                
                if i == 0
                {
                    p1.move( to: NSPoint( x: x, y: y ) )
                    p2.move( to: NSPoint( x: x, y: y ) )
                }
                else
                {
                    p1.line( to: NSPoint( x: x, y: y ) )
                    p2.line( to: NSPoint( x: x, y: y ) )
                }
            }
        }
        
        p2.line( to: NSPoint( x: rect.origin.x + rect.size.width, y: rect.origin.y - 3 ) )
        p2.line( to: NSPoint( x: rect.origin.x, y: rect.origin.y - 3 ) )
        p2.close()
        
        if self.graphStyle == .gradient
        {
            let gradient = NSGradient( colors: [ color.withAlphaComponent( 0.25 ), color.withAlphaComponent( 0 ) ] )
            
            gradient?.draw( in: p2, angle: -90 )
        }
        else if self.graphStyle == .fill
        {
            color.setFill()
            p2.fill()
        }
        
        color.setStroke()
        p1.stroke()
    }
    
    private func drawBars( in rect: NSRect, kind: SensorData.Kind, values: [ CGFloat ], min: CGFloat, max: CGFloat, color: NSColor )
    {
        let c = 15
        let h = rect.size.height / CGFloat( c )
        let n = rect.size.width / h
        
        let values = Array( values.suffix( Int( n ) ) )
        
        for i in 0 ..< Int( n )
        {
            if i >= values.count
            {
                return
            }
            
            let v = values[ i ]
            let p = ( v - min ) / ( max - min )
            
            for j in 0 ..< c
            {
                if CGFloat( j ) / CGFloat( c ) > p
                {
                    break
                }
                
                let square = NSRect( x: rect.origin.x + h * CGFloat( i ), y: rect.origin.y + h * CGFloat( j ), width: h, height: h ).insetBy( dx: 1, dy: 1 )
                
                color.setFill()
                square.fill()
            }
        }
    }
}
