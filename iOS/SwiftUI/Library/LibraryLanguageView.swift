//
//  LibraryLanguageFilterView.swift
//  Kiwix
//
//  Created by Chris Li on 4/3/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import Defaults
import RealmSwift

/// Select languages displayed in LibraryCategoryView.
struct LibraryLanguageView: View {
    @Default(.libraryLanguageSortingMode) private var sortingMode
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        if #available(iOS 14.0, *) {
            list.navigationTitle("Languages").toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker(selection: $sortingMode, label: Image(systemName: "arrow.up.arrow.down")) {
                        ForEach(LibraryLanguageSortingMode.allCases) { sortingMode in
                            Text(sortingMode.description).tag(sortingMode)
                        }
                    }.pickerStyle(MenuPickerStyle())
                }
            }
        } else {
            list.navigationBarItems(trailing: HStack {
                Picker(selection: $sortingMode, label: Image(systemName: "arrow.up.arrow.down")) {
                    ForEach(LibraryLanguageSortingMode.allCases) { sortingMode in
                        Text(sortingMode.description).tag(sortingMode)
                    }
                }.pickerStyle(SegmentedPickerStyle())
                Spacer(minLength: 60)
            })
        }
    }
    
    var list: some View {
        List {
            if viewModel.showing.count > 0 {
                Section(header: Text("Showing")) {
                    ForEach(viewModel.showing) { language in
                        Button(
                            action: { viewModel.hide(language) },
                            label: { LanguageCell(language: language) }
                        )
                    }
                }
            }
            if viewModel.hiding.count > 0 {
                Section(header: Text("Hiding")) {
                    ForEach(viewModel.hiding) { language in
                        Button(
                            action: { viewModel.show(language) },
                            label: { LanguageCell(language: language) }
                        )
                    }
                }
            }
        }
        .insetGroupedListStyle()
    }
    
    struct Language: Identifiable, Comparable {
        var id: String { code }
        let code: String
        let name: String
        let count: Int
        
        init?(code: String, count: Int) {
            guard let name = Locale.current.localizedString(forLanguageCode: code) else { return nil }
            self.code = code
            self.name = name
            self.count = count
        }
        
        static func < (lhs: LibraryLanguageView.Language, rhs: LibraryLanguageView.Language) -> Bool {
            switch lhs.name.caseInsensitiveCompare(rhs.name) {
            case .orderedAscending:
                return true
            case .orderedDescending:
                return false
            case .orderedSame:
                return lhs.count > rhs.count
            }
        }
    }
    
    struct LanguageCell: View {
        let language: Language
        
        var body: some View {
            HStack {
                Text(language.name).foregroundColor(.primary)
                Spacer()
                Text("\(language.count)").foregroundColor(.secondary)
            }
        }
    }
    
    class ViewModel: ObservableObject {
        @Published private(set) var showing: [Language] = []
        @Published private(set) var hiding: [Language] = []
        
        private var sortingModeObserver: Defaults.Observation?
        
        init() {
            sortingModeObserver = Defaults.observe(.libraryLanguageSortingMode) { _ in self.loadData() }
        }
        
        func show(_ language: Language) {
            withAnimation {
                self.showing.append(language)
                self.hiding.removeAll(where: { $0.code == language.code })
                self.sort(&showing)
                self.sort(&hiding)
            }
            Defaults[.libraryLanguageCodes].append(language.code)
        }
        
        func hide(_ language: Language) {
            withAnimation {
                self.showing.removeAll(where: { $0.code == language.code })
                self.hiding.append(language)
                self.sort(&showing)
                self.sort(&hiding)
            }
            Defaults[.libraryLanguageCodes].removeAll(where: { language.code == $0 })
        }
        
        func loadData() {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    var showing: [Language] = []
                    var hiding: [Language] = []
                    
                    let database = try Realm()
                    let codes = database.objects(ZimFile.self).distinct(by: ["languageCode"]).map({ $0.languageCode })
                    for code in codes {
                        let count = database.objects(ZimFile.self).filter("languageCode = %@", code).count
                        guard let language = Language(code: code, count: count) else { continue }
                        if Defaults[.libraryLanguageCodes].contains(code) {
                            showing.append(language)
                        } else {
                            hiding.append(language)
                        }
                    }
                    
                    self.sort(&showing)
                    self.sort(&hiding)
                    
                    DispatchQueue.main.async {
                        self.showing = showing
                        self.hiding = hiding
                    }
                } catch { }
            }
        }
        
        private func sort(_ languages: inout [Language]) {
            switch Defaults[.libraryLanguageSortingMode] {
            case .alphabetically:
                languages.sort { $0 < $1 }
            case .byCount:
                languages.sort { $0.count == $1.count ? $0 < $1 : $0.count > $1.count }
            }
        }
    }
}
