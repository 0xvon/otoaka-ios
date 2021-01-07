//
//  HomeViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import AWSCognitoAuth
import Endpoint
import UIKit

final class RootViewController: UITabBarController, Instantiable {
    typealias Input = Void

    let dependencyProvider: DependencyProvider
    private var isFirstViewDidAppear = true

    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.tabBar.tintColor = Brand.color(for: .text(.primary))
        self.tabBar.barTintColor = Brand.color(for: .background(.primary))
        self.tabBar.backgroundColor = Brand.color(for: .background(.primary))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        dependencyProvider.auth.delegate = self
        if isFirstViewDidAppear {
            isFirstViewDidAppear = false
            checkSignupStatus()
        }
    }
    
    func checkSignupStatus() {
        if dependencyProvider.auth.isSignedIn {
            dependencyProvider.apiClient.request(SignupStatus.self) { [unowned self] result in
                switch result {
                case .success(let res):
                    if res.isSignedup {
                        makeViewFromUserInfo()
                    } else {
                        DispatchQueue.main.async {
                            presentRegistrationScreen()
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.promptAlertViewController(with: String(describing: error))
                    }
                }
            }
        } else {
            presentRegistrationScreen()
        }
    }
    
    private func presentRegistrationScreen() {
        let vc = RegistrationViewController(dependencyProvider: dependencyProvider) { [unowned self] in
            self.makeViewFromUserInfo()
        }
        let nav = DismissionSubscribableNavigationController(rootViewController: vc)
        nav.subscribeDismission {
            self.checkSignupStatus()
        }
        self.present(nav, animated: true)
    }
    
    func makeViewFromUserInfo() {
        dependencyProvider.apiClient.request(GetUserInfo.self) { [unowned self] result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    self.setViewControllers(instantiateTabs(with: user), animated: false)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.promptAlertViewController(with: String(describing: error))
                }
            }
        }
    }
    
    func instantiateTabs(with user: User) -> [UIViewController] {
        let loggedInProvider = LoggedInDependencyProvider(provider: dependencyProvider, user: user)
        let homeVC = BrandNavigationController(rootViewController: FeedViewController(dependencyProvider: loggedInProvider))
        homeVC.tabBarItem = UITabBarItem(
            title: "ホーム", image: UIImage(named: "musicIcon"),
            selectedImage: UIImage(named: "selectedMusicIcon"))
        let groupVC = BrandNavigationController(
            rootViewController: GroupViewController(dependencyProvider: loggedInProvider)
        )
        groupVC.tabBarItem = UITabBarItem(
            title: "バンド", image: UIImage(systemName: "person.3"),
            selectedImage: UIImage(systemName: "person.3.fill"))
        let liveVC = BrandNavigationController(rootViewController: LiveViewController(dependencyProvider: loggedInProvider))
        liveVC.tabBarItem = UITabBarItem(
            title: "ライブ",
            image: UIImage(named: "guitarIcon"),
            selectedImage: UIImage(named: "selectedGuitarIcon")
        )
        let accountVC = AccountViewController(dependencyProvider: loggedInProvider, input: ())
        let accountNav = BrandNavigationController(
            rootViewController: accountVC
        )
        accountNav.tabBarItem = UITabBarItem(
            title: "アカウント設定",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
        accountVC.listen { [unowned self] output in
            switch output {
            case .signout:
                self.checkSignupStatus()
            case .editUser: break
            case .searchGroup:
                self.selectedViewController = groupVC
            }
        }
        return [homeVC, groupVC, liveVC, accountNav]
    }
    private func promptAlertViewController(with message: String) {
        let alertController = UIAlertController(
            title: "エラー", message: message, preferredStyle: UIAlertController.Style.alert
        )
        let ok = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(ok)
        self.present(alertController, animated: true)
    }
}

extension RootViewController: AWSCognitoAuthDelegate {
    func getViewController() -> UIViewController {
        return self
    }
}
