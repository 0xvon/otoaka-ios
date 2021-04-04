//
//  BandContentsListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import Endpoint
import Combine

final class FeedListViewController: UIViewController, Instantiable {
    typealias Input = FeedListViewModel.Input

    var dependencyProvider: LoggedInDependencyProvider
    private var feedTableView: UITableView!
    let viewModel: FeedListViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = FeedListViewModel(dependencyProvider: dependencyProvider, input: input)
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadData:
                feedTableView.reloadData()
            case .didDeleteFeed:
                viewModel.refresh()
            case .didToggleLikeFeed:
                viewModel.refresh()
            case .error(let err):
                print(err)
                showAlert()
            }
        }
        .store(in: &cancellables)
    }
    
    func inject(_ input: Input) {
        viewModel.inject(input)
    }
        
    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        feedTableView = UITableView()
        feedTableView.translatesAutoresizingMaskIntoConstraints = false
        feedTableView.showsVerticalScrollIndicator = false
        feedTableView.tableFooterView = UIView(frame: .zero)
        feedTableView.separatorStyle = .none
        feedTableView.backgroundColor = Brand.color(for: .background(.primary))
        feedTableView.delegate = self
        feedTableView.dataSource = self
        feedTableView.registerCellClass(UserFeedCell.self)
        self.view.addSubview(feedTableView)
        
        feedTableView.refreshControl = BrandRefreshControl()
        feedTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)
        
        let constraints: [NSLayoutConstraint] = [
            feedTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            feedTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            feedTableView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            feedTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc private func refreshGroups(sender: UIRefreshControl) {
        viewModel.refresh()
        sender.endRefreshing()
    }
}

extension FeedListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.state.feeds.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let content = self.viewModel.state.feeds[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            UserFeedCell.self,
            input: (user: dependencyProvider.user, feed: content, imagePipeline: dependencyProvider.imagePipeline),
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let content = self.viewModel.state.feeds[indexPath.row]
        let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: .userFeed(content))
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    private func feedCommentButtonTapped(cellIndex: Int) {
        let feed = self.viewModel.state.feeds[cellIndex]
        let vc = CommentListViewController(dependencyProvider: dependencyProvider, input: .feedComment(feed))
        let nav = BrandNavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
    
    private func createShare(cellIndex: Int) {
        let feed = self.viewModel.state.feeds[cellIndex]
        shareWithTwitter(type: .feed(feed))
    }
    
    private func downloadButtonTapped(cellIndex: Int) {
        let feed = self.viewModel.state.feeds[cellIndex]
        if let thumbnail = feed.ogpUrl {
            let image = UIImage(url: thumbnail)
            downloadImage(image: image)
        }
    }
    
    private func instagramButtonTapped(cellIndex: Int) {
        let feed = self.viewModel.state.feeds[cellIndex]
        shareFeedWithInstagram(feed: feed)
    }
    
    private func userTapped(cellIndex: Int) {
        let feed = self.viewModel.state.feeds[cellIndex]
        let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: feed.author)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func deleteFeedButtonTapped(cellIndex: Int) {
        let alertController = UIAlertController(
            title: "フィードを削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let acceptAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default,
            handler: { [unowned self] action in
                viewModel.deleteFeed(cellIndex: cellIndex)
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
