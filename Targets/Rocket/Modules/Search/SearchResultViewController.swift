//
//  SearchResultViewController.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/31.
//

import UIKit
import DomainEntity
import Endpoint
import InternalDomain

final class SearchResultViewController: UIViewController {
    enum Input {
        case none
        case live(String, Group.ID?, Date?, Date?)
        case liveToSelect(String)
        case group(String)
        case groupToSelect(String)
        case track(String)
        case appleMusicToSelect(String)
        case youtubeToSelect(String)
        case user(String)
    }
    
    enum Output {
        case group(GroupFeed)
        case track(Track)
        case live(LiveFeed)
    }
    
    typealias State = Input

    private lazy var liveListViewController: LiveListViewController = {
        let controller = LiveListViewController(dependencyProvider: dependencyProvider, input: .none)
        controller.view.isHidden = true
        return controller
    }()
    private lazy var groupListViewController: GroupListViewController = {
        let controller = GroupListViewController(dependencyProvider: dependencyProvider, input: .none)
        controller.view.isHidden = true
        return controller
    }()
    private lazy var userListViewController: UserListViewController = {
        let controller = UserListViewController(dependencyProvider: dependencyProvider, input: .none)
        controller.view.isHidden = true
        return controller
    }()
    private lazy var trackListViewController: TrackListViewController = {
        let controller = TrackListViewController(dependencyProvider: dependencyProvider, input: .none)
        controller.view.isHidden = true
        return controller
    }()

    private var state: State {
        didSet {
            switch state {
            case .group(let query):
                groupListViewController.view.isHidden = false
                liveListViewController.view.isHidden = true
                userListViewController.view.isHidden = true
                trackListViewController.view.isHidden = true
                groupListViewController.inject(.searchResults(query))
            case .groupToSelect(let query):
                groupListViewController.view.isHidden = false
                liveListViewController.view.isHidden = true
                userListViewController.view.isHidden = true
                trackListViewController.view.isHidden = true
                groupListViewController.inject(.searchResultsToSelect(query))
                groupListViewController.listen { [unowned self] group in
                    self.listener(.group(group))
                }
            case .live(let query, let groupId, let fromDate, let toDate):
                groupListViewController.view.isHidden = true
                liveListViewController.view.isHidden = false
                userListViewController.view.isHidden = true
                trackListViewController.view.isHidden = true
                liveListViewController.inject(.searchResult(query, groupId, fromDate, toDate))
            case .liveToSelect(let query):
                groupListViewController.view.isHidden = true
                liveListViewController.view.isHidden = false
                userListViewController.view.isHidden = true
                trackListViewController.view.isHidden = true
                liveListViewController.inject(.searchResultToSelect(query))
                liveListViewController.listen { [unowned self] live in
                    self.listener(.live(live))
                }
            case .user(let query):
                groupListViewController.view.isHidden = true
                liveListViewController.view.isHidden = true
                userListViewController.view.isHidden = false
                trackListViewController.view.isHidden = true
                if query == "" {
                    userListViewController.inject(.recommendedUsers(dependencyProvider.user.id))
                } else {
                    userListViewController.inject(.searchResults(query))
                }
            case .track(let query):
                groupListViewController.view.isHidden = true
                liveListViewController.view.isHidden = true
                userListViewController.view.isHidden = true
                trackListViewController.view.isHidden = false
                trackListViewController.inject(.searchAppleMusicResults(query))
            case .appleMusicToSelect(let query):
                groupListViewController.view.isHidden = true
                liveListViewController.view.isHidden = true
                userListViewController.view.isHidden = true
                trackListViewController.view.isHidden = false
                trackListViewController.inject(.searchAppleMusicResults(query), isToSelect: true)
                trackListViewController.listen { [unowned self] track in
                    self.listener(.track(track))
                }
            case .youtubeToSelect(let query):
                groupListViewController.view.isHidden = true
                liveListViewController.view.isHidden = true
                userListViewController.view.isHidden = true
                trackListViewController.view.isHidden = false
                trackListViewController.inject(.searchYouTubeResults(query), isToSelect: true)
                trackListViewController.listen { [unowned self] track in
                    self.listener(.track(track))
                }
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

        let children = [
            liveListViewController,
            userListViewController,
            groupListViewController,
            trackListViewController
        ]
        
        for child in children {
            addChild(child)
            view.addSubview(child.view)
            child.didMove(toParent: self)
        }
    }

    func inject(_ input: Input) {
        self.state = input
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
