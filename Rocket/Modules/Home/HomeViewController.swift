//
//  HomeViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import AWSCognitoAuth
import Endpoint
import UIKit

final class HomeViewController: UITabBarController, Instantiable {
    typealias Input = Void
    var input: Input!

    var dependencyProvider: DependencyProvider!

    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        super.init(nibName: nil, bundle: nil)

        self.input = input
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.view.backgroundColor = style.color.background.get()
        self.tabBar.tintColor = style.color.main.get()
        self.tabBar.barTintColor = style.color.background.get()
        self.tabBar.backgroundColor = style.color.background.get()
        self.navigationController?.navigationBar.tintColor = style.color.main.get()
        self.navigationController?.navigationBar.barTintColor = .clear

        if dependencyProvider.auth.isSignedIn {
            dependencyProvider.apiClient.request(SignupStatus.self) { [unowned self] result in
                switch result {
                case .success(let res):
                    if res.isSignedup {
                        makeViewFromUserInfo()
                    } else {
                        DispatchQueue.main.async {
                            makeAuth()
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.promptAlertViewController(with: String(describing: error))
                    }
                }
            }
        } else {
            makeAuth()
        }
    }
    
    func makeAuth() {
        let vc = AuthViewController(dependencyProvider: dependencyProvider) { [unowned self] in
            self.makeViewFromUserInfo()
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.tintColor = style.color.main.get()
        nav.navigationBar.barTintColor = .clear
        self.present(nav, animated: true)
    }

    func makeViewFromUserInfo() {
        dependencyProvider.apiClient.request(GetUserInfo.self) { [unowned self] result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    self.setViewControllers(instantiateTabs(with: user), animated: true)
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
        let bandViewController = BandViewController(
            dependencyProvider: loggedInProvider, input: self.input)
        let vc1 = UINavigationController(rootViewController: bandViewController)
        vc1.tabBarItem = UITabBarItem(
            title: "Home", image: UIImage(named: "musicIcon"),
            selectedImage: UIImage(named: "selectedMusicIcon"))
        vc1.navigationBar.tintColor = style.color.main.get()
        vc1.navigationBar.barTintColor = .clear

        let ticketViewController = TicketViewController(
            dependencyProvider: loggedInProvider, input: ())
        let vc2 = UINavigationController(rootViewController: ticketViewController)
        vc2.tabBarItem = UITabBarItem(
            title: "Ticket", image: UIImage(named: "ticketIcon"),
            selectedImage: UIImage(named: "selectedTicketIcon"))
        vc2.navigationBar.tintColor = style.color.main.get()
        vc2.navigationBar.barTintColor = .clear
        return [vc1, vc2]
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
