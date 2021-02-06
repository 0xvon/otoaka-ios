//
//  FeedViewController.swift
//  InternalDomain
//
//  Created by Masato TSUTSUMI on 2021/01/06.
//

import UIKit
import UserNotifications
import SafariServices
import UIComponent
import DomainEntity
import Combine

final class FeedViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider

    let viewModel: FeedViewModel
    private var cancellables: [AnyCancellable] = []
    
    lazy var createButton: UIButton = {
        let button = UIButton()
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = Brand.font(for: .xxlargeStrong)
        button.addTarget(self, action: #selector(createFeed), for: .touchUpInside)
        return button
    }()
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = FeedViewModel(dependencyProvider: dependencyProvider)
        
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ホーム"
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.registerCellClass(ArtistFeedCell.self)
        refreshControl = BrandRefreshControl()
        if case .artist = dependencyProvider.user.role  {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: createButton)
        }
        
        bind()
        requestNotification()
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadData:
                self.tableView.reloadData()
                self.setTableViewBackgroundView(isDisplay: self.viewModel.feeds.isEmpty)
            case .isRefreshing(let value):
                if value {
                    self.setTableViewBackgroundView(isDisplay: false)
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .didDeleteFeed:
                viewModel.refresh.send(())
            case .reportError(let error):
                self.showAlert(title: "エラー", message: error.localizedDescription)
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @objc private func refresh() {
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
        self.refreshControl?.beginRefreshing()
        viewModel.refresh.send(())
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
                    self.showAlert(title: "エラー", message: error.localizedDescription)
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
    
    @objc func createFeed() {
        let vc = PostViewController(dependencyProvider: self.dependencyProvider, input: ())
        let nav = BrandNavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
}

extension FeedViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let feed = viewModel.feeds[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            ArtistFeedCell.self,
            input: (user: dependencyProvider.user, feed: feed, imagePipeline: dependencyProvider.imagePipeline),
            for: indexPath
        )
        cell.listen { [weak self] output in
            switch output {
            case .commentButtonTapped:
                self?.feedCommentButtonTapped(cellIndex: indexPath.row)
            case .deleteFeedButtonTapped:
                self?.deleteFeedButtonTapped(cellIndex: indexPath.row)
            }
            
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.feeds.count
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplayCell.send(indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 332
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let feed = viewModel.feeds[indexPath.row]
        switch feed.feedType {
        case .youtube(let url):
            let safari = SFSafariViewController(url: url)
            safari.dismissButtonStyle = .close
            present(safari, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .feed, actionButtonTitle: "バンドを探す")
            emptyCollectionView.listen { [unowned self] in
                let vc = SearchResultViewController(dependencyProvider: dependencyProvider)
                vc.inject(.group(""))
                self.navigationController?.pushViewController(vc, animated: true)
            }
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = isDisplay ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 32),
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor, constant: -32),
                backgroundView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            ])
        }
    }
    
    private func feedCommentButtonTapped(cellIndex: Int) {
        let feed = self.viewModel.feeds[cellIndex]
        let vc = CommentListViewController(dependencyProvider: dependencyProvider, input: .feedComment(feed))
        let nav = BrandNavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
    
    private func deleteFeedButtonTapped(cellIndex: Int) {
        let feed = self.viewModel.feeds[cellIndex]
        viewModel.deleteFeed(feed: feed)
    }
}

extension FeedViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
