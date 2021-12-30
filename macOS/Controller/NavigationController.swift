//
//  SearchController.swift
//  macOS
//
//  Created by Chris Li on 10/13/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import Cocoa
import RealmSwift

class ArticleNavigationController: NSViewController, NSMenuDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var localOutlineView: NSOutlineView!
    
    private var localZimFilesChangeToken: NotificationToken?
    
    // MARK: - Database
    
    private let localZimFiles: Results<ZimFile>? = {
        do {
            let database = try Realm()
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }()
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localZimFilesChangeToken = localZimFiles?.observe({ [unowned self] (change) in
            switch change {
            case .initial(let zimFiles):
                self.tabView.selectTabViewItem(withIdentifier: zimFiles.count > 0 ? "ZimFileLocal" : "ZimFileLocalEmpty")
                self.localOutlineView.reloadData()
            case .update(let zimFiles, _, _, _):
                self.tabView.selectTabViewItem(withIdentifier: zimFiles.count > 0 ? "ZimFileLocal" : "ZimFileLocalEmpty")
                self.localOutlineView.reloadData()
            default:
                break
            }
        })
    }
    
    deinit {
        localZimFilesChangeToken?.invalidate()
    }
    
    // MARK: - Action
    
    @objc func removeZimFile() {
        guard let window = view.window,
            let localOutlineView = localOutlineView,
            let zimFile = localOutlineView.item(atRow: localOutlineView.clickedRow) as? ZimFile else {return}
        
        let alert = NSAlert()
        alert.messageText = "Do you want to remove zim file from Kiwix?"
        alert.informativeText = "Your file won't be deleted."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { (response) in
            switch(response) {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                let index = IndexSet(integer: localOutlineView.childIndex(forItem: zimFile))
                localOutlineView.removeItems(at: index, inParent: nil, withAnimation: NSTableView.AnimationOptions.slideLeft)
                ZimFileService.shared.remove(id: zimFile.fileID)
                do {
                    let database = try Realm()
                    try database.write {
                        database.delete(zimFile)
                    }
                } catch {}
            default:
                break
            }
        }
    }
    
    // MARK: - NSMenuDelegate
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if let clickedRow = localOutlineView?.clickedRow, clickedRow >= 0 {
            let menuItem = NSMenuItem(title: "Remove", action: #selector(removeZimFile), keyEquivalent: "")
            menu.addItem(menuItem)
        }
    }
    
    // MARK: - NSOutlineViewDataSource
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return item == nil ? (localZimFiles?.count ?? 0) : 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return localZimFiles?[index] ?? Object()
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    // MARK: - NSOutlineViewDelegate
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? ZimFile else {return nil}
        let identifier = NSUserInterfaceItemIdentifier("ZimFileCell")
        let view = outlineView.makeView(withIdentifier: identifier, owner: self) as! ZimFileTableCellView
        view.titleTextField.stringValue = item.title
        view.subtitleTextField.stringValue = item.description
        view.imageView?.image = NSImage(data: item.faviconData ?? Data())
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView,
            let windowController = view.window?.windowController as? WindowController else {return}
        guard let zimFile = outlineView.item(atRow: outlineView.selectedRow) as? ZimFile,
            let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID) else {return}
        windowController.contentTabController?.setMode(.reader)
        windowController.webViewController?.load(url: url)
    }
}

class ZimFileTableCellView: NSTableCellView {
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var subtitleTextField: NSTextField!
}
