//
//  BandListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/28.
//

import UIKit
import Endpoint

final class BandListViewController: UIViewController, Instantiable {
    typealias Input = BandListType
    
    enum BandListType {
        case memberships
        case followingGroups
        case searchResults(String)
    }

    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input!
    var groups: [Group] = []
    private var groupTableView: UITableView!

    lazy var viewModel = BandListViewModel(
        apiClient: dependencyProvider.apiClient,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .memberships(let groups):
                DispatchQueue.main.async {
                    self.groups = groups
                    self.groupTableView.reloadData()
                }
            case .followingGroups(let groups):
                DispatchQueue.main.async {
                    self.groups = groups
                    self.groupTableView.reloadData()
                }
            case .searchGroups(let groups):
                DispatchQueue.main.async {
                    self.groups = groups
                    self.groupTableView.reloadData()
                }
            case .error(let error):
                print(error)
            }
        }
    )

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
        
    func setup() {
        view.backgroundColor = style.color.background.get()
        
        groupTableView = UITableView()
        groupTableView.translatesAutoresizingMaskIntoConstraints = false
        groupTableView.showsVerticalScrollIndicator = false
        groupTableView.tableFooterView = UIView(frame: .zero)
        groupTableView.separatorStyle = .none
        groupTableView.backgroundColor = style.color.background.get()
        groupTableView.delegate = self
        groupTableView.dataSource = self
        groupTableView.register(
            UINib(nibName: "BandCell", bundle: nil), forCellReuseIdentifier: "BandCell")
        self.view.addSubview(groupTableView)
        
        groupTableView.refreshControl = UIRefreshControl()
        groupTableView.refreshControl?.addTarget(
            self, action: #selector(refreshBand(sender:)), for: .valueChanged)
        self.getGroups()
        
        let constraints: [NSLayoutConstraint] = [
            groupTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            groupTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            groupTableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 32),
            groupTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func getGroups() {
        switch self.input {
        case .memberships:
            viewModel.getMemberships(userId: dependencyProvider.user.id)
        case .followingGroups:
            viewModel.getFollowingGroups()
        case .searchResults(let query):
            viewModel.searchGroups(query: query)
        case .none:
            break
        }
    }
    
    @objc private func refreshBand(sender: UIRefreshControl) {
        self.getGroups()
        sender.endRefreshing()
    }
}

extension BandListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.groups.count
        
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
        return 250
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let band = self.groups[indexPath.section]
        let cell = tableView.reuse(BandCell.self, input: band, for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let band = self.groups[indexPath.section]
        let vc = BandDetailViewController(
            dependencyProvider: self.dependencyProvider, input: band)
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
