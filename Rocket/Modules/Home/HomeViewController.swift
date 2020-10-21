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
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tab() {
        let liveViewController = LiveViewController(dependencyProvider: dependencyProvider, input: ())
        liveViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .bookmarks, tag: 0)
        
        let bandViewController = BandViewController(dependencyProvider: dependencyProvider, input: ())
        bandViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .contacts, tag: 1)
        
        let ticketViewController = TicketViewController(dependencyProvider: dependencyProvider, input: ())
        ticketViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .featured, tag: 2)
        
        let tabBarList = [liveViewController, bandViewController, ticketViewController]
        viewControllers = tabBarList
    }
}
