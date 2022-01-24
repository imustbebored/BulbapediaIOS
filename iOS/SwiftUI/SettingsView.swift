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

struct AboutView: View {
    @State var externalLinkURL: URL?
    
    var body: some View {
        List {
            Section {
                Text("""
                     
                     You may withdraw your consent for a personalized ad experience at any time by enabling Opt out of Ads Personalization under Settings/Google/Ads on your Android device and then restarting this app. By doing this, you will still see ads, but they may not be as relevant to your interests.
                     
                     We also use analytics tracking called Google Firebase which allows us to see helpful data of how many people are using our app, how often they are using our app, and other things like what pages they read. This data allows us get an idea what parts of our app people enjoy the most. It ultimately helps us make the app better for our users. You can learn more about how Google manages its data and ad sites at www.google.com/policies/technologies/partner-sites
                     
                     This app is a part of Wiksi Apps and is the only official Bulbapedia app. All Bulbapedia content used is under CC BY-NC-SA. Pokémon content and materials are trademarks and copyrights of Nintendo, Creatures, and Game Freak and their licensors. All rights reserved.
                     
                     This app is a heavily modified version of the official Wikipedia Android App. Below you will find information about contributors, translators, libraries used, as well as the Apache 2.0 License that the official Wikipedia Android App is licensed under. Here is a link to the Bulbapedia Privacy Policy and the following is a link to our advertiser Playwire\'s Privacy Policy. Also, we are legally obligated to let you know that because this app contains ads, there may be a collection/use of something called an advertising identifier which advertisers may use to better serve you ads. X. THIRD PARTY ADVERTISERS - YOUR AD CHOICES
                     We use third-party advertising companies to serve ads when you visit the Websites and/or use the Mobile Apps. These companies may use information about your visits to any of the Websites and other websites and the Mobile App(s) and other mobile applications in order to provide advertisements about goods and services of interest to you. You have the ability to opt out of the use of your information for purposes of online third-party advertising. If you would like more information about your choices, visit aboutads.info. You may have the ability to manage tracking and ad preferences on your mobile device from your devices settings. We do not respond to Web browser "do not track" signals or other similar mechanisms.

                     """
                )
                    .lineLimit(nil)
                    .minimumScaleFactor(0.5) // to avoid unnecessary truncation (three dots)
                Button("Our Website") { externalLinkURL = URL(string: "https://bulbapedia.bulbagarden.net/wiki/Main_Page") }
                Button("CC BY-NC-SA") { externalLinkURL = URL(string: "https://creativecommons.org/licenses/by-nc-sa/3.0/us/") }
                Button("Bulbapedia Privacy Policy") { externalLinkURL = URL(string: "http://bulbapedia.bulbagarden.net/wiki/Bulbapedia:Privacy_policy") }
                Button("Playwire Privacy Policy") { externalLinkURL = URL(string: "https://playwire.com/privacy-policy/") }
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
