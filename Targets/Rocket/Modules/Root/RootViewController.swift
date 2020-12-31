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
    var input: Input!
    private var shouldSetTabViewControllers = true

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

        dependencyProvider.auth.delegate = self
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.tabBar.tintColor = Brand.color(for: .text(.primary))
        self.tabBar.barTintColor = Brand.color(for: .background(.primary))
        self.tabBar.backgroundColor = Brand.color(for: .background(.primary))
        self.navigationController?.navigationBar.tintColor = Brand.color(for: .text(.primary))
        self.navigationController?.navigationBar.barTintColor = .clear
        checkSignupStatus()
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
        let vc = RegistrationViewController(dependencyProvider: dependencyProvider) { [unowned self] in
            self.makeViewFromUserInfo()
        }
        let nav = ModalNavigationController(rootViewController: vc)
        nav.navigationBar.tintColor = Brand.color(for: .text(.primary))
        nav.navigationBar.barTintColor = .clear
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
                    guard self.shouldSetTabViewControllers else { return }
                    self.shouldSetTabViewControllers = false
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
        let bandViewController = HomeViewController(
            dependencyProvider: loggedInProvider, input: self.input)
        let bandVC = BrandNavigationController(rootViewController: bandViewController)
        bandVC.tabBarItem = UITabBarItem(
            title: "Home", image: UIImage(named: "musicIcon"),
            selectedImage: UIImage(named: "selectedMusicIcon"))
        bandViewController.signout {
            self.checkSignupStatus()
        }
        
        let searchViewCotnroller = SearchViewController_V1(dependencyProvider: loggedInProvider, input: ())
        let searchVC = BrandNavigationController(rootViewController: searchViewCotnroller)
        searchVC.tabBarItem = UITabBarItem(
            title: "Search", image: UIImage(named: "searchIcon"),
            selectedImage: UIImage(named: "selectedSearchIcon"))

        let ticketViewController = TicketViewController(
            dependencyProvider: loggedInProvider, input: ())
        let ticketVC = BrandNavigationController(rootViewController: ticketViewController)
        ticketVC.tabBarItem = UITabBarItem(
            title: "Ticket", image: UIImage(named: "ticketIcon"),
            selectedImage: UIImage(named: "selectedTicketIcon"))
        return [bandVC, ticketVC, searchVC]
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
