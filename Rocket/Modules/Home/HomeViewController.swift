//
//  HomeViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import UIKit
import AWSCognitoAuth

final class HomeViewController: UITabBarController, Instantiable {
    typealias Input = Void
    var input: Input
    
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
        let liveViewController = LiveViewController(dependencyProvider: dependencyProvider, input: ())
        let vc1 = UINavigationController(rootViewController: liveViewController)
        vc1.tabBarItem = UITabBarItem(title: "Live", image: UIImage(named: "guitarIcon"), selectedImage: UIImage(named: "selectedGuitarIcon"))
        vc1.navigationBar.tintColor = style.color.main.get()
        vc1.navigationBar.barTintColor = .clear
        
        let bandViewController = BandViewController(dependencyProvider: dependencyProvider, input: ())
        let vc2 = UINavigationController(rootViewController: bandViewController)
        vc2.tabBarItem = UITabBarItem(title: "Band", image: UIImage(named: "musicIcon"), selectedImage: UIImage(named: "selectedMusicIcon"))
        vc2.navigationBar.tintColor = style.color.main.get()
        vc2.navigationBar.barTintColor = .clear
        
        let ticketViewController = TicketViewController(dependencyProvider: dependencyProvider, input: ())
        let vc3 = UINavigationController(rootViewController: ticketViewController)
        vc3.tabBarItem = UITabBarItem(title: "Ticket", image: UIImage(named: "ticketIcon"), selectedImage: UIImage(named: "selectedTicketIcon"))
        vc3.navigationBar.tintColor = style.color.main.get()
        vc3.navigationBar.barTintColor = .clear
        
        let tabBarList = [vc1, vc2, vc3]
        viewControllers = tabBarList
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().barTintColor = .black
        
    }
}
