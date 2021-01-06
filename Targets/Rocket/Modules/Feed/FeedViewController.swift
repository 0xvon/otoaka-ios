//
//  FeedViewController.swift
//  InternalDomain
//
//  Created by Masato TSUTSUMI on 2021/01/06.
//

import UIKit
import UIComponent
import DomainEntity
import Combine
import SafariServices

final class FeedViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider

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
        title = "ホーム"
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.registerCellClass(ArtistFeedCell.self)
        refreshControl = BrandRefreshControl()
        
        bind()
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadData:
                self.tableView.reloadData()
                self.setTableViewBackgroundView(isDisplay: self.viewModel.feeds.isEmpty)
            case .isRefreshing(let value):
                if value {
                    self.refreshControl?.beginRefreshing()
                    self.setTableViewBackgroundView(isDisplay: false)
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .reportError(let error):
                self.showAlert(title: "エラー", message: error.localizedDescription)
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @objc private func refresh() {
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
        viewModel.refresh.send(())
    }
}

extension FeedViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let feed = viewModel.feeds[indexPath.row]
        let cell = tableView.dequeueReusableCell(ArtistFeedCell.self, input: feed, for: indexPath)
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
                self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers![1]
            }
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = isDisplay ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
                backgroundView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
                backgroundView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ])
        }
    }
}