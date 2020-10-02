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

public class GraphView: NSView
{
    public private( set ) var data = [ ( speed: Int, temperature: Int ) ]()
    
    public func addData( speed: Int, temperature: Int )
    {
        self.data.append( ( speed: speed, temperature: temperature ) )
        
        self.data         = self.data.suffix( 50 )
        self.needsDisplay = true
    }
    
    public var canDisplay: Bool
    {
        self.data.count >= 2
    }
    
    public override func draw( _ rect: NSRect )
    {
        if self.canDisplay == false
        {
            return
        }
        
        let path = NSBezierPath( roundedRect: rect.insetBy( dx: 1, dy: 1 ), xRadius: 10, yRadius: 10 ) 
        
        NSColor.controlTextColor.withAlphaComponent( 0.2 ).setStroke()
        NSColor.controlTextColor.withAlphaComponent( 0.05 ).setFill()
        path.stroke()
        path.fill()
        
        let path1  = NSBezierPath()
        let path2  = NSBezierPath()
        
        var i = CGFloat( 0 )
        
        let rect = rect.insetBy( dx: 10, dy: 10 )
        
        for value in self.data
        {
            let n1 = value.speed       > 100 ? CGFloat( 100 ) : CGFloat( value.speed )
            let n2 = value.temperature > 100 ? CGFloat( 100 ) : CGFloat( value.temperature )
            let x  = (  i * ( rect.size.width  / CGFloat( self.data.count - 1 ) ) ) + rect.origin.x
            let y1 = ( n1 * ( rect.size.height / 100 ) ) + rect.origin.y
            let y2 = ( n2 * ( rect.size.height / 100 ) ) + rect.origin.y
            
            if i == 0
            {
                path1.move( to: NSMakePoint( x, y1 ) )
                path2.move( to: NSMakePoint( x, y2 ) )
            }
            else
            {
                path1.line( to: NSMakePoint( x, y1 ) )
                path2.line( to: NSMakePoint( x, y2 ) )
            }
            
            i += 1
        }
        
        path1.lineWidth    = 2
        path2.lineWidth    = 2
        path1.lineCapStyle = .round
        path2.lineCapStyle = .round
        
        NSColor.systemBlue.withAlphaComponent( 0.75 ).setStroke()
        path1.stroke()
        
        NSColor.systemOrange.withAlphaComponent( 0.75 ).setStroke()
        path2.stroke()
        
        let circle1 = NSBezierPath( ovalIn: NSMakeRect( rect.origin.x, rect.origin.y + 10, 7.5, 7.5 ) )
        let circle2 = NSBezierPath( ovalIn: NSMakeRect( rect.origin.x, rect.origin.y,      7.5, 7.5 ) )
        
        NSColor.systemBlue.withAlphaComponent( 0.75 ).setFill()
        circle1.fill()
        
        NSColor.systemOrange.withAlphaComponent( 0.75 ).setFill()
        circle2.fill()
        
        let attributes: [ NSAttributedString.Key : Any ] =
        [
            .foregroundColor : NSColor.controlTextColor.withAlphaComponent( 0.75 ),
            .font            : NSFont.systemFont( ofSize: 8 )
        ]
        
        ( "Speed"       as NSString ).draw( at: NSMakePoint( rect.origin.x + 10, rect.origin.y + 9 ), withAttributes: attributes )
        ( "Temperature" as NSString ).draw( at: NSMakePoint( rect.origin.x + 10, rect.origin.y - 1 ), withAttributes: attributes )
    }
}
