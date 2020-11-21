//
//  HomeViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import UIKit
import AWSCognitoAuth
import Endpoint

final class HomeViewController: UITabBarController, Instantiable {
    typealias Input = User
    var input: Input!
    
    var dependencyProvider: DependencyProvider!
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        super.init(nibName: nil, bundle: nil)
        
        self.input = input
        tab()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tab() {
        self.view.backgroundColor = style.color.background.get()
        
        let bandViewController = BandViewController(dependencyProvider: dependencyProvider, input: ())
        let vc1 = UINavigationController(rootViewController: bandViewController)
        vc1.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "musicIcon"), selectedImage: UIImage(named: "selectedMusicIcon"))
        vc1.navigationBar.tintColor = style.color.main.get()
        vc1.navigationBar.barTintColor = .clear
        
        let ticketViewController = TicketViewController(dependencyProvider: dependencyProvider, input: ())
        let vc2 = UINavigationController(rootViewController: ticketViewController)
        vc2.tabBarItem = UITabBarItem(title: "Ticket", image: UIImage(named: "ticketIcon"), selectedImage: UIImage(named: "selectedTicketIcon"))
        vc2.navigationBar.tintColor = style.color.main.get()
        vc2.navigationBar.barTintColor = .clear
        
        let tabBarList = [vc1, vc2]
        viewControllers = tabBarList
        self.tabBar.tintColor = style.color.main.get()
        self.tabBar.barTintColor = style.color.background.get()
        self.tabBar.backgroundColor = style.color.background.get()
    }
}
