//
//  AppDelegate.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/10/16.
//

import AWSCore
import Auth0

import UIKit
import Endpoint
import UserNotifications
import KeyboardGuide
import Combine
import SwiftyStoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var dependencyProvider: DependencyProvider!
    var cancellables: Set<AnyCancellable> = []

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 起動時はこっちが呼ばれる
        // Override point for customization after application launch.
        KeyboardGuide.shared.activate()
        setupIAP()
        
        let url: URL? = launchOptions?[.url] as? URL
        window = UIWindow(frame: UIScreen.main.bounds)
        dependencyProvider = .make(windowScene: window!.windowScene!, urlScheme: url)
        let viewController = RootViewController(dependencyProvider: dependencyProvider, input: ())
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }

    func application(
        _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // バックグラウンド動作中はこっちが呼ばれる
        if window != nil && dependencyProvider != nil {
            dependencyProvider.urlScheme = url
            let viewController = RootViewController(dependencyProvider: dependencyProvider, input: ())
            window?.rootViewController = viewController
            window?.makeKeyAndVisible()
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { (byte: UInt8) in String(format: "%02.2hhx", byte) }.joined()
        let req = RegisterDeviceToken.Request(deviceToken: token)
        let registerDeviceToken = Action(RegisterDeviceToken.self, httpClient: dependencyProvider.apiClient)
        
        registerDeviceToken.elements
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)
        
        registerDeviceToken.input((request: req, uri: RegisterDeviceToken.URI()))
    }
    
    func setupIAP() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    let downloads = purchase.transaction.downloads
                    if !downloads.isEmpty {
                        SwiftyStoreKit.start(downloads)
                    } else if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    print("\(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                case .failed, .purchasing, .deferred:
                    break
                @unknown default:
                    break
                }
            }
        }
        
        SwiftyStoreKit.updatedDownloadsHandler = { downloads in
            // contentURL is not nil if downloadState == .finished
            let contentURLs = downloads.compactMap { $0.contentURL }
            if contentURLs.count == downloads.count {
                print("Saving: \(contentURLs)")
                SwiftyStoreKit.finishTransaction(downloads[0].transaction)
            }
        }
    }

    //    // MARK: UISceneSession Lifecycle
    //
    //    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    //        // Called when a new scene session is being created.
    //        // Use this method to select a configuration to create the new scene with.
    //        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    //    }
    //
    //    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    //        // Called when the user discards a scene session.
    //        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    //        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    //    }

}
