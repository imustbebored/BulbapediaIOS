//
//  ZimFileManagerController.swift
//  macOS
//
//  Created by Chris Li on 10/12/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa
import Defaults

class ZimFileManagerController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    @IBOutlet weak var outlineView: NSOutlineView!
    private var items = [Item]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        items = [Item(name: "Files", children: [])]
        reloadData()
    }
    
    func reloadData() {
        let zimFileBookmarks = Defaults[.zimFileBookmarks]
        let urls = zimFileBookmarks.compactMap { (data) -> URL? in
            var isStale = false
            let url = (((try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)) as URL??)) ?? nil
            return isStale ? nil : url
        }
        items[0].children = urls.map({ Item(name: $0.lastPathComponent) })
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? Item {
            return item.children.count
        } else {
            return items.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? Item {
            return item.children[index]
        } else {
            return items[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let item = item as? Item else {return false}
        return item.children.count > 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? Item else {return nil}
        let identifier = NSUserInterfaceItemIdentifier(item.children.count > 0 ? "HeaderCell" : "DataCell")
        let view = outlineView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
        view.textField?.stringValue = item.name
        return view
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let item = item as? Item else {return false}
        return item.children.count == 0
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView else {return}
        let item = outlineView.item(atRow: outlineView.selectedRow)
        
        guard let windowController = view.window?.windowController as? WindowController else {return}
        windowController.webViewController?.loadMainPage(id: "")
    }
}

private class Item {
    let name: String
    var children: [Item]
    
    init(name: String, children: [Item] = []) {
        self.name = name
        self.children = children
    }
}
