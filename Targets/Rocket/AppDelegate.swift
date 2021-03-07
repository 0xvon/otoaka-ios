//
//  AppDelegate.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/10/16.
//

import AWSCognitoAuth
import AWSCore
import Endpoint
import UIKit
import UserNotifications
import KeyboardGuide
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var dependencyProvider: DependencyProvider!
    var cancellables: Set<AnyCancellable> = []

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.
        KeyboardGuide.shared.activate()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        dependencyProvider = .make(windowScene: window!.windowScene!)
        let viewController = RootViewController(dependencyProvider: dependencyProvider, input: ())
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // TODO: Deep Link for custom URL schemes
        return true
    }

    func application(
        _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return dependencyProvider.auth.application(app, open: url, options: options)
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
