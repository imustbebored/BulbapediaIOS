//
//  AppDelegate.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import Defaults
import RealmSwift
import Firebase
import FirebaseAnalytics
import UserNotifications
import FirebaseMessaging
import AppTrackingTransparency
import AdSupport
import StoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DirectoryMonitorDelegate {
    var window: UIWindow?
    let fileMonitor = DirectoryMonitor(url: URL.documentDirectory)
    
    // MARK: - Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        Realm.Configuration.defaultConfiguration = Realm.defaultConfig
        
        FirebaseApp.configure()
        
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        Messaging.messaging().subscribe(toTopic: "test_bulba") { error in
            print("Subscribed to test_bulba topic")
        }
        
        restoreIAPDayWise()
        
        setReviewDialog()
                
        print("Document Directory URL: \(URL.documentDirectory)")
        
        DownloadService.shared.restorePreviousState()
        LibraryService().applyAutoUpdateSetting()
        
        fileMonitor.delegate = self
        fileMonitor.start()
        
        let operation = LibraryScanOperation(url: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(operation)
        
        application.shortcutItems = [
            UIApplicationShortcutItem(type: Shortcut.bookmark.rawValue, localizedTitle: NSLocalizedString("Bookmark", comment: "3D Touch Menu Title")),
            UIApplicationShortcutItem(type: Shortcut.search.rawValue, localizedTitle: NSLocalizedString("Search", comment: "3D Touch Menu Title"))
        ]
        
        Defaults.migrate()

        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.requestPermission()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        UserDefaults.standard.set(false, forKey: "Is_Active_Session")
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.UD_IsPurchased)
        UserDefaults.standard.synchronize()
        fileMonitor.stop()
    }
    
    // MARK: - Directory Monitoring
    
    func directoryContentDidChange(url: URL) {
        let scan = LibraryScanOperation(directoryURL: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(scan)
    }
    
    // MARK: - Background
    
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        DownloadService.shared.backgroundEventsProcessingCompletionHandler = completionHandler
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let operation = OPDSRefreshOperation()
        operation.completionBlock = {
            if operation.error != nil {
                completionHandler(operation.hasUpdates ? .newData : .noData)
            } else {
                completionHandler(.failed)
            }
        }
        LibraryOperationQueue.shared.addOperation(operation)
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
    
    func restoreIAPDayWise() {
        if let lastAlertDate = UserDefaults.standard.object(forKey: UserDefaultKeys.UD_HasRestoredToday) as? Date {
            if Calendar.current.isDateInToday(lastAlertDate) {
                print("IAP has restored once today !")
            } else {
                restorePurchase()
            }
        } else {
            restorePurchase()
        }
    }
    
    func restorePurchase() {
        UserDefaults.standard.set(Date(), forKey: UserDefaultKeys.UD_HasRestoredToday)
        IAPHandler.shared.restorePurchase()
    }
    
    func setReviewDialog() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {

        }
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([[.banner, .sound]])
        } else {
            // Fallback on earlier versions
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let tokenDict = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: tokenDict)
    }
}

// MARK: - Type Definition

enum Shortcut: String {
    case search, bookmark
}
