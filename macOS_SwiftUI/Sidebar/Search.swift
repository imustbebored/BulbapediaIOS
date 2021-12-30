//
//  Search.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 11/6/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import CoreData
import SwiftUI

import Defaults

/// Search interface in the sidebar.
struct Search: View {
    @Binding var url: URL?
    @State private var selectedSearchText: String?
    @StateObject private var viewModel = ViewModel()
    @Default(.recentSearchTexts) private var recentSearchTexts: [String]
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        SearchField(searchText: $viewModel.searchText).padding(.horizontal, 10).padding(.vertical, 6)
        searchResults
        searchFilter
    }
    
    @ViewBuilder
    var searchResults: some View {
        if viewModel.searchText.isEmpty, !recentSearchTexts.isEmpty {
            List(recentSearchTexts, id: \.self, selection: $selectedSearchText) { searchText in
                Text(searchText)
            }.onChange(of: selectedSearchText) { self.updateCurrentSearchText($0) }
        } else if !viewModel.searchText.isEmpty, !viewModel.results.isEmpty {
            List(viewModel.results, id: \.url, selection: $url) { searchResult in
                Text(searchResult.title)
            }.onChange(of: url) { _ in self.updateRecentSearchTexts(viewModel.searchText) }
        } else if !viewModel.searchText.isEmpty, viewModel.results.isEmpty, !viewModel.inProgress {
            List { Text("No Result") }
        } else {
            List { }
        }
    }
    
    var searchFilter: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("Include in Search").fontWeight(.medium)
                Spacer()
                if zimFiles.map {$0.includedInSearch }.reduce(true) { $0 && $1 } {
                    Button { selectNoZimFiles() } label: {
                        Text("None").font(.caption).fontWeight(.medium)
                    }
                } else {
                    Button { selectAllZimFiles() } label: {
                        Text("All").font(.caption).fontWeight(.medium)
                    }
                }
            }.padding(.vertical, 5).padding(.leading, 16).padding(.trailing, 10).background(.regularMaterial)
            Divider()
            List {
                ForEach(zimFiles, id: \.fileID) { zimFile in
                    Toggle(zimFile.name, isOn: Binding<Bool>(get: {
                        zimFile.includedInSearch
                    }, set: {
                        zimFile.includedInSearch = $0
                        try? managedObjectContext.save()
                    }))
                }
            }
        }.frame(height: 180)
    }
    
    private func updateCurrentSearchText(_ searchText: String?) {
        guard let searchText = searchText else { return }
        viewModel.searchText = searchText
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedSearchText = nil
        }
    }
    
    private func updateRecentSearchTexts(_ searchText: String) {
        guard !searchText.isEmpty else { return }
        var recentSearchTexts = self.recentSearchTexts
        recentSearchTexts.removeAll { $0 == searchText }
        recentSearchTexts.insert(searchText, at: 0)
        self.recentSearchTexts = recentSearchTexts
    }
    
    private func selectAllZimFiles() {
        let request = ZimFile.fetchRequest()
        try? managedObjectContext.fetch(request).forEach { zimFile in
            zimFile.includedInSearch = true
        }
        try? managedObjectContext.save()
    }
    
    private func selectNoZimFiles() {
        let request = ZimFile.fetchRequest()
        try? managedObjectContext.fetch(request).forEach { zimFile in
            zimFile.includedInSearch = false
        }
        try? managedObjectContext.save()
    }
}

private class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var searchText: String = ""
    @Published var zimFileIDs: [UUID] = []
    @Published var inProgress = false
    @Published var results = [SearchResult]()
    
    private let fetchedResultsController: NSFetchedResultsController<ZimFile>
    private var searchSubscriber: AnyCancellable?
    private var searchTextSubscriber: AnyCancellable?
    private let queue = OperationQueue()
    
    override init() {
        queue.maxConcurrentOperationCount = 1
        
        let predicate = NSPredicate(format: "includedInSearch == true AND fileURLBookmark != nil")
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: ZimFile.fetchRequest(predicate: predicate),
            managedObjectContext: Database.shared.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        try? fetchedResultsController.performFetch()
        zimFileIDs = fetchedResultsController.fetchedObjects?.map { $0.fileID } ?? []
        
        super.init()
        
        fetchedResultsController.delegate = self
        searchSubscriber = Publishers.CombineLatest($zimFileIDs, $searchText)
            .debounce(for: 0.2, scheduler: queue, options: nil)
            .receive(on: DispatchQueue.main, options: nil)
            .sink { zimFileIDs, searchText in
                self.updateSearchResults(searchText, Set(zimFileIDs.map { $0.uuidString }))
            }
//        searchTextSubscriber = $searchText.sink { searchText in self.inProgress = !searchText.isEmpty }
    }
    
    private func updateSearchResults(_ searchText: String, _ zimFileIDs: Set<String>) {
        queue.cancelAllOperations()
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [unowned self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
//                self.results = operation.results
                self.inProgress = false
            }
        }
        queue.addOperation(operation)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        zimFileIDs = fetchedResultsController.fetchedObjects?.map { $0.fileID } ?? []
    }
}
