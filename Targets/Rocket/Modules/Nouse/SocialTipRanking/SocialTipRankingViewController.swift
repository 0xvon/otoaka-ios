//
//  SocialTipRankingViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/30.
//

import UIKit
import Combine
import Parchment

final class SocialTipRankingViewController: UIViewController {
    let dependencyProvider: LoggedInDependencyProvider
    private var cancellables: [AnyCancellable] = []
    private let viewModel: SocialTipRankingViewModel
    
    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = SocialTipRankingViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ランキング"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Brand.color(for: .background(.primary))
        setPagingViewController()
        
        bind()
    }
    
    private func setPagingViewController() {
        let vc1 = UserRankingListViewController(dependencyProvider: dependencyProvider, input: .userTipFeed)
        let vc2 = GroupRankingListViewController(dependencyProvider: dependencyProvider, input: .entriedGroup)
        let pagingViewController = PagingViewController(viewControllers: [
            vc1,
            vc2,
        ])
        self.addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        pagingViewController.menuBackgroundColor = Brand.color(for: .background(.primary))
        pagingViewController.borderColor = .clear
        pagingViewController.selectedTextColor = Brand.color(for: .brand(.primary))
        pagingViewController.indicatorColor = Brand.color(for: .brand(.primary))
        pagingViewController.textColor = Brand.color(for: .text(.primary))
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagingViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            pagingViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pagingViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
    }
}
