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
import Endpoint
import Combine

final class FeedViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    
    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
    lazy var searchController: UISearchController = {
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchResultsUpdater = self
        controller.delegate = self
        controller.searchBar.delegate = self
        controller.searchBar.searchTextField.placeholder = "ユーザー検索"
        controller.searchBar.scopeButtonTitles = viewModel.scopes.map(\.description)
        return controller
    }()

    let viewModel: FeedViewModel
    private var cancellables: [AnyCancellable] = []
    
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
        title = "フィード"
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.registerCellClass(UserFeedCell.self)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        refreshControl = BrandRefreshControl()
        
        bind()
        requestNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.showsScopeBar = true
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: true)
        setupFloatingItems(userRole: dependencyProvider.user.role)
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
            case .updateSearchResult(let input):
                self.searchResultController.inject(input)
            case .didDeleteFeed:
                viewModel.refresh.send(())
            case .didToggleLikeFeed:
                viewModel.refresh.send(())
            case .reportError(let error):
                print(error)
                self.showAlert()
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
                    print(error)
                    self.showAlert()
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
    
    private func setupFloatingItems(userRole: RoleProperties) {
        let items: [FloatingButtonItem]
        let createFeedView = FloatingButtonItem(icon: UIImage(named: "post")!)
        createFeedView.addTarget(self, action: #selector(createFeed), for: .touchUpInside)
        items = [createFeedView]
        let floatingController = dependencyProvider.viewHierarchy.floatingViewController
        floatingController.setFloatingButtonItems(items)
    }
    
    @objc func createFeed() {
//        let vc = PostViewController(dependencyProvider: self.dependencyProvider, input: ())
//        navigationController?.pushViewController(vc, animated: true)
    }
}

extension FeedViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        viewModel.updateScope.send(selectedScope)
    }
}

extension FeedViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = false
        searchController.searchResultsController?.view.isHidden = false
    }
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = true
    }
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchResultsController?.view.isHidden = false
    }
}

extension FeedViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchQuery.send(searchController.searchBar.text)
        searchController.searchResultsController?.view.isHidden = false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        viewModel.updateSearchQuery.send(searchController.searchBar.text)
    }
}

extension FeedViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let feed = viewModel.feeds[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            UserFeedCell.self,
            input: (user: dependencyProvider.user, feed: feed, imagePipeline: dependencyProvider.imagePipeline),
            for: indexPath
        )
        cell.listen { [weak self] output in
            switch output {
            case .commentButtonTapped:
                self?.feedCommentButtonTapped(cellIndex: indexPath.row)
            case .deleteFeedButtonTapped:
                self?.deleteFeedButtonTapped(cellIndex: indexPath.row)
            case .likeFeedButtonTapped:
                self?.viewModel.likeFeed(cellIndex: indexPath.row)
            case .unlikeFeedButtonTapped:
                self?.viewModel.unlikeFeed(cellIndex: indexPath.row)
            case .shareButtonTapped:
                self?.createShare(cellIndex: indexPath.row)
            case .downloadButtonTapped:
                self?.downloadButtonTapped(cellIndex: indexPath.row)
            case .instagramButtonTapped:
                self?.instagramButtonTapped(cellIndex: indexPath.row)
            case .userTapped:
                self?.userTapped(cellIndex: indexPath.row)
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
        return 300
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let feed = viewModel.feeds[indexPath.row]
        let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: .userFeed(feed))
        self.navigationController?.pushViewController(vc, animated: true)
//        switch feed.feedType {
//        case .youtube(let url):
//            let safari = SFSafariViewController(url: url)
//            safari.dismissButtonStyle = .close
//            present(safari, animated: true, completion: nil)
//        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .feed, actionButtonTitle: "フィードを投稿してみる")
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
    
    private func createShare(cellIndex: Int) {
    }
    
    private func downloadButtonTapped(cellIndex: Int) {
        let feed = self.viewModel.feeds[cellIndex]
        if let thumbnail = feed.ogpUrl {
            let image = UIImage(url: thumbnail)
            downloadImage(image: image)
        }
    }
    
    private func instagramButtonTapped(cellIndex: Int) {
    }
    
    private func userTapped(cellIndex: Int) {
        let feed = self.viewModel.feeds[cellIndex]
        let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: feed.author)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func deleteFeedButtonTapped(cellIndex: Int) {
        let alertController = UIAlertController(
            title: "フィードを削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let acceptAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default,
            handler: { [unowned self] action in
                let feed = self.viewModel.feeds[cellIndex]
                viewModel.deleteFeed(feed: feed)
            })
        let cancelAction = UIAlertAction(
            title: "キャンセル", style: UIAlertAction.Style.cancel,
            handler: { action in })
        alertController.addAction(acceptAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension FeedViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
