//
//  LiveListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import Endpoint

final class LiveListViewController: UIViewController, Instantiable {
    typealias Input = ListType
    
    enum ListType {
        case groupLive(Group)
        case searchResult(String)
    }

    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input!
    var lives: [Live] = []
    private var liveTableView: UITableView!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var viewModel = LiveListViewModel(
        apiClient: dependencyProvider.apiClient,
        type: input,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getGroupLives(let lives):
                DispatchQueue.main.async {
                    self.lives += lives
                    self.liveTableView.reloadData()
                }
            case .refreshGroupLives(let lives):
                DispatchQueue.main.async {
                    self.lives = lives
                    self.liveTableView.reloadData()
                }
            case .searchLive(let lives):
                DispatchQueue.main.async {
                    self.lives += lives
                    self.liveTableView.reloadData()
                }
            case .refreshSearchLive(let lives):
                DispatchQueue.main.async {
                    self.lives = lives
                    self.liveTableView.reloadData()
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
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        liveTableView = UITableView()
        liveTableView.translatesAutoresizingMaskIntoConstraints = false
        liveTableView.showsVerticalScrollIndicator = false
        liveTableView.tableFooterView = UIView(frame: .zero)
        liveTableView.separatorStyle = .none
        liveTableView.backgroundColor = Brand.color(for: .background(.primary))
        liveTableView.delegate = self
        liveTableView.dataSource = self
        liveTableView.register(
            UINib(nibName: "LiveCell", bundle: nil), forCellReuseIdentifier: "LiveCell")
        self.view.addSubview(liveTableView)
        
        liveTableView.refreshControl = UIRefreshControl()
        liveTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)
        self.getLives()
        
        let constraints: [NSLayoutConstraint] = [
            liveTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            liveTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            liveTableView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            liveTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func getLives() {
        switch input {
        case .groupLive(_):
            self.viewModel.getGroupLives()
        case .searchResult(_):
            self.viewModel.searchLive()
        case .none:
            break
        }
    }
    
    func refreshLives() {
        switch input {
        case .groupLive(_):
            self.viewModel.refreshGroupLives()
        case .searchResult(_):
            self.viewModel.refreshSearchLive()
        case .none:
            break
        }
    }
    
    @objc private func refreshGroups(sender: UIRefreshControl) {
        self.refreshLives()
        sender.endRefreshing()
    }
}

extension LiveListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.lives.count
        
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
        let live = self.lives[indexPath.section]
        let cell = tableView.dequeueReusableCell(LiveCell.self, input: live, for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let live = self.lives[indexPath.section]
        let vc = LiveDetailViewController(dependencyProvider: self.dependencyProvider, input: (live: live, ticket: nil))
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (self.lives.count - indexPath.section) == 2 && self.lives.count % per == 0 {
            self.getLives()
        }
    }
}

