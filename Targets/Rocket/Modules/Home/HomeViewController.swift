//
//  HomeViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/23.
//

import UIKit
import Combine
import Endpoint
import ImageViewer
import Parchment

final class HomeViewController: UIViewController {
    let dependencyProvider: LoggedInDependencyProvider
    
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ライブレポート"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        setPagingViewController()
        requestNotification()
        showWalkThrough()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    private func setPagingViewController() {
        let vc1 = PostListViewController(dependencyProvider: dependencyProvider, input: .trendPost)
        let vc2 = PostListViewController(dependencyProvider: dependencyProvider, input: .followingPost)
        let pagingViewController = PagingViewController(viewControllers: [
            vc1,
            vc2,
        ])
        self.addChild(pagingViewController)
        self.view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        pagingViewController.menuBackgroundColor = Brand.color(for: .background(.primary))
        pagingViewController.borderColor = .clear
        pagingViewController.selectedTextColor = Brand.color(for: .text(.toggle))
        pagingViewController.indicatorColor = Brand.color(for: .text(.toggle))
        pagingViewController.textColor = Brand.color(for: .text(.primary))
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagingViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            pagingViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pagingViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
    }
    
    private func requestNotification() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [
            .alert, .sound, .badge,
        ]) {
            granted, error in
            if let error = error {
                DispatchQueue.main.async {
                    print(error)
                    self.showAlert()
                }
                return
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func showWalkThrough() {
        let userDefaults = UserDefaults.standard
        let key = "walkThroughPresented+\(UUID().uuidString)"
        if !userDefaults.bool(forKey: key) {
            let vc = WalkThroughViewController(dependencyProvider: dependencyProvider)
            let nav = BrandNavigationController(rootViewController: vc)
            present(nav, animated: true, completion: nil)
            userDefaults.setValue(true, forKey: key)
            userDefaults.synchronize()
        }
    }
}

extension HomeViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
}


