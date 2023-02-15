//
//  SceneDelegate.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 11/28/19.
//  Copyright © 2019 Chris Li. All rights reserved.
//

import UIKit
import AppTrackingTransparency
import AdSupport

@available(iOS 13, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let rootViewController = RootViewController()
    
    // MARK: - Lifecycle
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
            window?.rootViewController = UINavigationController(rootViewController: rootViewController)
            window?.makeKeyAndVisible()
            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        }
    }
    
    // MARK: - URL Handling & Actions
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                let onDeviceZimFiles = LibraryService.onDeviceZimFiles()?.sorted(byKeyPath: "size", ascending: false)
                if let zimFiles = onDeviceZimFiles, !zimFiles.isEmpty, let zimFile = zimFiles.first {
                    self.rootViewController.openMainPage(zimFileID: zimFile.fileID)
                }
            })
            return
        }
        if context.url.isKiwixURL {
            rootViewController.openURL(context.url)
        } else if context.url.isFileURL {
            rootViewController.openFileURL(context.url, canOpenInPlace: context.options.openInPlace)
        }
    }
    
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        guard let shortcut = Shortcut(rawValue: shortcutItem.type),
              let navigationController = window?.rootViewController as? UINavigationController,
              let rootViewController = navigationController.topViewController as? RootViewController else { completionHandler(false); return }
        switch shortcut {
        case .bookmark:
            rootViewController.bookmarkButtonTapped()
        case .search:
            rootViewController.searchController.isActive = true
        }
        completionHandler(true)
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.requestPermission()
        }
    }
    
    func requestPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    // Tracking authorization dialog was shown and we are authorized
                    print("Authorized")
                    
                    // Now that we are authorized we can get the IDFA
                    print(ASIdentifierManager.shared().advertisingIdentifier)
                case .denied:
                    // Tracking authorization dialog was shown and permission is denied
                    print("Denied")
                case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("Not Determined")
                case .restricted:
                    print("Restricted")
                @unknown default:
                    print("Unknown")
                }
            }
        }
    }
}

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}
