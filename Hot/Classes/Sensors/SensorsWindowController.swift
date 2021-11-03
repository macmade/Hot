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

public class SensorsWindowController: NSWindowController
{
    @objc private dynamic var sensors: Sensors? = Sensors()
    
    @objc private dynamic var showTemperature = UserDefaults.standard.bool( forKey: "sensorsWindowShowTemperature" )
    {
        didSet
        {
            self.updateFilters()
            UserDefaults.standard.set( self.showTemperature, forKey: "sensorsWindowShowTemperature" )
        }
    }
    
    @objc private dynamic var showVoltage = UserDefaults.standard.bool( forKey: "sensorsWindowShowVoltage" )
    {
        didSet
        {
            self.updateFilters()
            UserDefaults.standard.set( self.showVoltage, forKey: "sensorsWindowShowVoltage" )
        }
    }
    
    @objc private dynamic var showCurrent = UserDefaults.standard.bool( forKey: "sensorsWindowShowCurrent" )
    {
        didSet
        {
            self.updateFilters()
            UserDefaults.standard.set( self.showCurrent, forKey: "sensorsWindowShowCurrent" )
        }
    }
    
    @objc private dynamic var searchText: String?
    {
        didSet { self.updateFilters() }
    }
    
    @objc private dynamic var graphStyle = UserDefaults.standard.integer( forKey: "graphStyle" )
    {
        didSet
        {
            UserDefaults.standard.set( self.graphStyle, forKey: "graphStyle" )
        }
    }
    
    @IBOutlet private var collectionView:  NSCollectionView!
    @IBOutlet private var arrayController: NSArrayController!
    
    public override var windowNibName: NSNib.Name?
    {
        "SensorsWindowController"
    }
    
    public override func windowDidLoad()
    {
        super.windowDidLoad()
        self.updateFilters()
        
        self.arrayController.sortDescriptors = [ NSSortDescriptor( key: "name", ascending: true, selector: #selector( NSString.localizedCaseInsensitiveCompare( _: ) ) ) ]
    }
    
    public func stop()
    {
        self.sensors?.stop
        {
            DispatchQueue.main.async
            {
                self.sensors = nil
            }
        }
    }
    
    private func updateFilters()
    {
        var predicates = [ NSPredicate ]()
        
        if self.showTemperature == false
        {
            predicates.append( NSPredicate { o, i in ( o as? SensorData )?.kind != .thermal } )
        }
        
        if self.showVoltage == false
        {
            predicates.append( NSPredicate { o, i in ( o as? SensorData )?.kind != .voltage } )
        }
        
        if self.showCurrent == false
        {
            predicates.append( NSPredicate { o, i in ( o as? SensorData )?.kind != .current } )
        }
        
        if let search = self.searchText, search.count > 0
        {
            predicates.append( NSPredicate( format: "name contains[c] %@", search ) )
        }
        
        if predicates.count > 0
        {
            self.arrayController.filterPredicate = NSCompoundPredicate( andPredicateWithSubpredicates: predicates )
        }
        else
        {
            self.arrayController.filterPredicate = nil
        }
    }
}

extension SensorsWindowController: NSCollectionViewDataSource
{
    public func numberOfSections( in collectionView: NSCollectionView ) -> Int
    {
        1
    }
    
    public func collectionView( _ collectionView: NSCollectionView, numberOfItemsInSection section: Int ) -> Int
    {
        ( self.arrayController.arrangedObjects as? [ SensorData ] )?.count ?? 0
    }
    
    public func collectionView( _ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath ) -> NSCollectionViewItem
    {
        let item = collectionView.makeItem( withIdentifier: NSUserInterfaceItemIdentifier( rawValue: "SensorItem" ), for: indexPath )
        
        if let item = item as? SensorItem, let sensors = self.arrayController.arrangedObjects as? [ SensorData ]
        {
            if sensors.count > indexPath.item
            {
                item.sensor = sensors[ indexPath.item ]
            }
        }
        
        return item
    }
}
