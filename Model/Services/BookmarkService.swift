//
//  BookmarkService.swift
//  Kiwix
//
//  Created by Chris Li on 1/1/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Foundation
import NotificationCenter
import RealmSwift

class BookmarkService {
    class func list() -> Results<Bookmark>? {
        do {
            let database = try Realm()
            return database.objects(Bookmark.self)
        } catch { return nil }
    }
    
    func get(url: URL) -> Bookmark? {
        guard let zimFileID = url.host else { return nil }
        return get(zimFileID: zimFileID, path: url.path)
    }
    
    func get(zimFileID: String, path: String) -> Bookmark? {
        let predicate = NSPredicate(format: "zimFile.fileID == %@ AND path == %@", zimFileID, path)
        do {
            let database = try Realm()
            return database.objects(Bookmark.self).filter(predicate).first
        } catch { return nil }
    }
    
    func create(url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let database = try Realm()
                guard let zimFileID = url.host,
                      let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID)
                else { return }
                
                let bookmark = Bookmark()
                bookmark.zimFile = zimFile
                bookmark.path = url.path
                bookmark.date = Date()
                
                let parser = try Parser(url: url)
                if let title = parser.title, title.count > 0 {
                    bookmark.title = title
                } else {
                    bookmark.title = zimFile.title
                }
                bookmark.snippet = parser.getFirstSentence(languageCode: zimFile.languageCode)?.string
                if let imagePath = parser.getFirstImagePath(), let imageURL = URL(string: imagePath, relativeTo: url) {
                    bookmark.thumbImagePath = imageURL.path
                }
                
                try database.write {
                    database.add(bookmark)
                }
            } catch {}
        }
    }
    
    func delete(_ bookmark: Bookmark) {
        do {
            let database = try Realm()
            try database.write {
                database.delete(bookmark)
            }
        } catch {}
    }
}
