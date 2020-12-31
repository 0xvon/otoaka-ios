//
//  SearchResultViewController.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/31.
//

import UIKit

final class SearchResultViewController: UIViewController {
    enum Input {
        case none
        case live(String)
        case group(String)
    }
    
    typealias State = Input

    private lazy var liveListViewController: LiveListViewController = {
        let controller = LiveListViewController(dependencyProvider: dependencyProvider, input: .searchResult(""))
        controller.view.isHidden = true
        return controller
    }()
    private lazy var groupListViewController: GroupListViewController = {
        let controller = GroupListViewController(dependencyProvider: dependencyProvider, input: .none)
        controller.view.isHidden = true
        return controller
    }()

    private var state: State {
        didSet {
            switch state {
            case .group(let query):
                groupListViewController.view.isHidden = false
                liveListViewController.view.isHidden = true
                groupListViewController.inject(.searchResults(query))
            case .live(let query):
                groupListViewController.view.isHidden = true
                liveListViewController.view.isHidden = false
            case .none:
                groupListViewController.view.isHidden = true
                liveListViewController.view.isHidden = true
            }
        }
    }
    let dependencyProvider: LoggedInDependencyProvider
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.state = .none
        self.dependencyProvider = dependencyProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let children = [liveListViewController, groupListViewController]
        for child in children {
            addChild(child)
            view.addSubview(child.view)
            child.didMove(toParent: self)
        }
    }

    func inject(_ input: Input) {
        self.state = input
    }
}
