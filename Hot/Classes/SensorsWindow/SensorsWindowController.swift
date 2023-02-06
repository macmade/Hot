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

public class SensorsWindowController: NSWindowController
{
    @objc private dynamic var sensors = Sensors()

    @objc private dynamic var showTemperature = UserDefaults.standard.object( forKey: "sensorsWindowShowTemperature" ) as? Bool ?? true
    {
        didSet
        {
            self.updateFilters()
            UserDefaults.standard.set( self.showTemperature, forKey: "sensorsWindowShowTemperature" )
        }
    }

    @objc private dynamic var showVoltage =  UserDefaults.standard.object( forKey: "sensorsWindowShowVoltage" ) as? Bool ?? true
    {
        didSet
        {
            self.updateFilters()
            UserDefaults.standard.set( self.showVoltage, forKey: "sensorsWindowShowVoltage" )
        }
    }

    @objc private dynamic var showCurrent =  UserDefaults.standard.object( forKey: "sensorsWindowShowCurrent" ) as? Bool ?? true
    {
        didSet
        {
            self.updateFilters()
            UserDefaults.standard.set( self.showCurrent, forKey: "sensorsWindowShowCurrent" )
        }
    }

    @objc private dynamic var showIOHID =  UserDefaults.standard.object( forKey: "sensorsWindowShowIOHID" ) as? Bool ?? true
    {
        didSet
        {
            self.updateFilters()
            UserDefaults.standard.set( self.showIOHID, forKey: "sensorsWindowShowIOHID" )
        }
    }

    @objc private dynamic var showSMC =  UserDefaults.standard.object( forKey: "sensorsWindowShowSMC" ) as? Bool ?? true
    {
        didSet
        {
            self.updateFilters()
            UserDefaults.standard.set( self.showSMC, forKey: "sensorsWindowShowSMC" )
        }
    }

    @objc private dynamic var searchText: String?
    {
        didSet { self.updateFilters() }
    }

    @objc private dynamic var graphStyle = UserDefaults.standard.integer( forKey: "sensorsWindowGraphStyle" )
    {
        didSet
        {
            UserDefaults.standard.set( self.graphStyle, forKey: "sensorsWindowGraphStyle" )
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

        self.arrayController.sortDescriptors = [ NSSortDescriptor( key: "name", ascending: true, selector: #selector( NSString.localizedCaseInsensitiveCompare( _: ) ) ) ]

        self.updateFilters()
    }

    public func stop( completion: ( () -> Void )? )
    {
        self.sensors.stop( completion: completion )
    }

    private func updateFilters()
    {
        var predicates = [ NSPredicate ]()

        if self.showTemperature == false
        {
            predicates.append( NSPredicate { o, i in ( o as? SensorHistoryData )?.kind != .thermal } )
        }

        if self.showVoltage == false
        {
            predicates.append( NSPredicate { o, i in ( o as? SensorHistoryData )?.kind != .voltage } )
        }

        if self.showCurrent == false
        {
            predicates.append( NSPredicate { o, i in ( o as? SensorHistoryData )?.kind != .current } )
        }

        if self.showIOHID == false
        {
            predicates.append( NSPredicate { o, i in ( o as? SensorHistoryData )?.source != .hid } )
        }

        if self.showSMC == false
        {
            predicates.append( NSPredicate { o, i in ( o as? SensorHistoryData )?.source != .smc } )
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
        ( self.arrayController.arrangedObjects as? [ SensorHistoryData ] )?.count ?? 0
    }

    public func collectionView( _ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath ) -> NSCollectionViewItem
    {
        let item = self.collectionView.makeItem( withIdentifier: NSUserInterfaceItemIdentifier( rawValue: "SensorItem" ), for: indexPath )

        if let item = item as? SensorItem, let sensors = self.arrayController.arrangedObjects as? [ SensorHistoryData ]
        {
            if sensors.count > indexPath.item
            {
                item.sensor = sensors[ indexPath.item ]
            }
        }

        return item
    }
}
