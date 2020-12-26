//
//  BandContentsListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import SafariServices
import Endpoint

final class GroupFeedListViewController: UIViewController, Instantiable {
    typealias Input = Group

    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input!
    var feeds: [ArtistFeedSummary] = []
    private var contentsTableView: UITableView!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var viewModel = GroupFeedListViewModel(
        apiClient: dependencyProvider.apiClient,
        group: input,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getGroupFeeds(let feeds):
                DispatchQueue.main.async {
                    self.feeds += feeds
                    self.contentsTableView.reloadData()
                }
            case .refreshGroupFeeds(let feeds):
                DispatchQueue.main.async {
                    self.feeds = feeds
                    self.contentsTableView.reloadData()
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
        
    func setup() {
        view.backgroundColor = style.color.background.get()
        
        contentsTableView = UITableView()
        contentsTableView.translatesAutoresizingMaskIntoConstraints = false
        contentsTableView.showsVerticalScrollIndicator = false
        contentsTableView.tableFooterView = UIView(frame: .zero)
        contentsTableView.separatorStyle = .none
        contentsTableView.backgroundColor = style.color.background.get()
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        contentsTableView.register(
            UINib(nibName: "BandContentsCell", bundle: nil), forCellReuseIdentifier: "BandContentsCell")
        self.view.addSubview(contentsTableView)
        
        contentsTableView.refreshControl = UIRefreshControl()
        contentsTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)
        viewModel.getGroupFeeds()
        
        let constraints: [NSLayoutConstraint] = [
            contentsTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            contentsTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            contentsTableView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            contentsTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc private func refreshGroups(sender: UIRefreshControl) {
        viewModel.refreshGroupFeeds()
        sender.endRefreshing()
    }
}

extension GroupFeedListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.feeds.count
        
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
        return 300
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let content = self.feeds[indexPath.section]
        let cell = tableView.reuse(BandContentsCell.self, input: content, for: indexPath)
        cell.comment { [weak self] _ in
            self?.feedCommentButtonTapped(cellIndex: indexPath.section)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let content = self.feeds[indexPath.section]
        switch content.feedType {
        case .youtube(let url):
            let safari = SFSafariViewController(url: url)
            safari.dismissButtonStyle = .close
            present(safari, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (self.feeds.count - indexPath.section) == 2 && self.feeds.count % per == 0 {
            self.viewModel.getGroupFeeds()
        }
    }
    
    private func feedCommentButtonTapped(cellIndex: Int) {
        let feed = self.feeds[cellIndex]
        let vc = CommentListViewController(dependencyProvider: dependencyProvider, input: .feedComment(feed))
        present(vc, animated: true, completion: nil)
    }
}
