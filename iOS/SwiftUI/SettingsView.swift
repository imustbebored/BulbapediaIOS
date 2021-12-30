//
//  SettingsView.swift
//  Kiwix
//
//  Created by Chris Li on 12/30/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import SafariServices
import SwiftUI

import Defaults

struct SettingsView: View {
    var dismiss: (() -> Void) = {}
    var sendFeedback: (() -> Void) = {}
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink("Font Size", destination: FontSizeSettingsView())
                    NavigationLink("External Link", destination: ExternalLinkSettingsView())
                    NavigationLink("Search", destination: SearchSettingsView())
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        NavigationLink("Sidebar", destination: SidebarSettingsView())
                    }
                }
                Section {
                    Button("Send Feedback") { sendFeedback() }
                    Button("Rate the App") {
                        UIApplication.shared.open(
                            URL(string: "itms-apps://itunes.apple.com/us/app/kiwix/id997079563?action=write-review")!,
                            options: [:]
                        )
                    }
                }
                Section(footer: version) {
                    NavigationLink("About", destination: AboutView())
                }
            }
            .insetGroupedListStyle()
            .navigationBarTitle("Settings")
            .navigationBarItems(leading: Button("Done", action: dismiss))
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    var version: some View {
        HStack {
            Spacer()
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Kiwix for iOS v\(version)")
            }
            Spacer()
        }
    }
}

fileprivate struct FontSizeSettingsView: View {
    @Default(.webViewTextSizeAdjustFactor) var webViewTextSizeAdjustFactor
    private let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.maximumIntegerDigits = 3
        return formatter
    }()
    
    var body: some View {
        List {
            Section(header: Text("Example")) {
                Text("Kiwix is an offline reader for online content like Wikipedia, Project Gutenberg, or TED Talks.")
                    .font(Font.system(size: 17.0 * CGFloat(webViewTextSizeAdjustFactor)))
            }
            if let number = NSNumber(value: webViewTextSizeAdjustFactor),
               let formatted = percentageFormatter.string(from: number) {
                Section(header: Text("Font Size")) {
                    Stepper(formatted, value: $webViewTextSizeAdjustFactor, in: 0.75...2, step: 0.05)
                }
            }
        }
        .insetGroupedListStyle()
        .navigationBarTitle("Font Size")
    }
}

fileprivate struct ExternalLinkSettingsView: View {
    @Default(.externalLinkLoadingPolicy) var externalLinkLoadingPolicy
    private let help = """
                       Decide if app should ask for permission to load an external link \
                       when Internet connection is required.
                       """
    
    var body: some View {
        List {
            Section(header: Text("Loading Policy"), footer: Text(help)) {
                ForEach(ExternalLinkLoadingPolicy.allCases) { policy in
                    Button(action: {
                        externalLinkLoadingPolicy = policy
                    }, label: {
                        HStack {
                            Text(policy.description).foregroundColor(.primary)
                            Spacer()
                            if externalLinkLoadingPolicy == policy {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    })
                }
            }
        }
        .insetGroupedListStyle()
        .navigationBarTitle("External Link")
    }
}

fileprivate struct SearchSettingsView: View {
    @Default(.searchResultSnippetMode) var searchResultSnippetMode
    private let help = "If search is becoming too slow, disable the snippets to improve the situation."
    
    var body: some View {
        List {
            Section(header: Text("Snippets"), footer: Text(help)) {
                ForEach(SearchResultSnippetMode.allCases) { snippetMode in
                    Button(action: {
                        searchResultSnippetMode = snippetMode
                    }, label: {
                        HStack {
                            Text(snippetMode.description).foregroundColor(.primary)
                            Spacer()
                            if searchResultSnippetMode == snippetMode {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    })
                }
            }
        }
        .insetGroupedListStyle()
        .navigationBarTitle("Search")
    }
}

fileprivate struct SidebarSettingsView: View {
    @Default(.sideBarDisplayMode) var sideBarDisplayMode
    private let help = """
                       Controls how the sidebar containing article outline and bookmarks \
                       should be displayed when it's available.
                       """
    
    var body: some View {
        List {
            Section(footer: Text(help)) {
                ForEach(SideBarDisplayMode.allCases) { displayMode in
                    Button(action: {
                        sideBarDisplayMode = displayMode
                    }, label: {
                        HStack {
                            Text(displayMode.description).foregroundColor(.primary)
                            Spacer()
                            if sideBarDisplayMode == displayMode {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    })
                }
            }
        }
        .insetGroupedListStyle()
        .navigationBarTitle("Sidebar")
    }
}

fileprivate struct AboutView: View {
    @State var externalLinkURL: URL?
    
    var body: some View {
        List {
            Section {
                Text("""
                     Kiwix is an offline reader for online content like Wikipedia, Project Gutenberg, or TED Talks. \
                     It makes knowledge available to people with no or limited internet access. \
                     The software as well as the content is free to use for anyone.
                     """
                )
                    .lineLimit(nil)
                    .minimumScaleFactor(0.5) // to avoid unnecessary truncation (three dots)
                Button("Our Website") { externalLinkURL = URL(string: "https://www.kiwix.org") }
            }
            Section(header: Text("Release")) {
                Text("This app is released under the terms of the GNU General Public License version 3.")
                Button("Source") { externalLinkURL = URL(string: "https://github.com/kiwix/apple") }
                Button("GNU General Public License v3") {
                    externalLinkURL = URL(string: "https://www.gnu.org/licenses/gpl-3.0.en.html")
                }
            }
            Section(header: Text("Dependencies")) {
                Dependency(name: "libkiwix", license: "GPLv3", version: "9.4.1")
                Dependency(name: "libzim", license: "GPLv2", version: "6.3.2")
                Dependency(name: "Xapian", license: "GPLv2")
                Dependency(name: "ICU", license: "ICU")
                Dependency(name: "Realm", license: "Apachev2")
                Dependency(name: "Fuzi", license: "MIT")
                Dependency(name: "Defaults", license: "MIT")
            }
        }
        .insetGroupedListStyle()
        .navigationBarTitle("About")
        .sheet(item: $externalLinkURL) { SafariView(url: $0) }
    }
    
    struct Dependency: View {
        let name: String
        let license: String
        let version: String?
        
        init(name: String, license: String, version: String? = nil) {
            self.name = name
            self.license = license
            self.version = version
        }
        
        var body: some View {
            HStack {
                Text(name)
                Spacer()
                Text(license).foregroundColor(.secondary)
                if let version = version {
                    Text("(\(version))").foregroundColor(.secondary)
                }
            }
        }
    }
    
    struct SafariView: UIViewControllerRepresentable {
        let url: URL

        func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
            SFSafariViewController(url: url)
        }
        
        func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
    }
}
