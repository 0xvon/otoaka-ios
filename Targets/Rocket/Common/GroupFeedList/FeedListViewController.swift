//
//  BandContentsListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import SafariServices
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
            case .error(let err):
                showAlert(title: "エラー", message: String(describing: err))
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
        feedTableView.registerCellClass(ArtistFeedCell.self)
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
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.state.feeds.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 332
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let content = self.viewModel.state.feeds[indexPath.section]
        let cell = tableView.dequeueReusableCell(
            ArtistFeedCell.self,
            input: (user: dependencyProvider.user, feed: content, imagePipeline: dependencyProvider.imagePipeline),
            for: indexPath
        )
        cell.listen { [weak self] output in
            switch output {
            case .commentButtonTapped:
                self?.feedCommentButtonTapped(cellIndex: indexPath.row)
            case .deleteFeedButtonTapped:
                self?.deleteFeedButtonTapped(cellIndex: indexPath.row)
            case .shareButtonTapped:
                self?.createShare(cellIndex: indexPath.row)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let content = self.viewModel.state.feeds[indexPath.section]
        switch content.feedType {
        case .youtube(let url):
            let safari = SFSafariViewController(url: url)
            safari.dismissButtonStyle = .close
            present(safari, animated: true, completion: nil)
        }
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
        
        switch feed.feedType {
        case .youtube(let url):
            let shareLiveText: String = "\(feed.text.prefix(20))\n\n by \(feed.author.name)\n\n\(url.absoluteString) via @wooruobudesu #ロック好きならロケバン"
            let shareUrl = URL(string: "https://apps.apple.com/jp/app/rocket-for-bands-ii/id1550896325")!

            let activityItems: [Any] = [shareLiveText, shareUrl]
            let activityViewController = UIActivityViewController(
                activityItems: activityItems, applicationActivities: [])

            activityViewController.completionWithItemsHandler = { [dependencyProvider] _, _, _, _ in
                dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: true)
            }
            activityViewController.popoverPresentationController?.permittedArrowDirections = .up
            dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
            self.present(activityViewController, animated: true, completion: nil)
        }
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

        self.present(alertController, animated: true, completion: nil)
    }
}
