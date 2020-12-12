//
//  FanListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/08.
//

import UIKit
import Endpoint

final class UserListViewController: UIViewController, Instantiable {
    typealias Input = InputType
    
    enum InputType {
        case followers(Group.ID)
        case tickets(Live.ID)
        case comments(Group.ID)
    }

    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input!
    var users: [User] = []
    private var fanTableView: UITableView!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var viewModel = UserListViewModel(
        apiClient: dependencyProvider.apiClient,
        input: input,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getFollowers(let users):
                DispatchQueue.main.async {
                    self.users += users
                    self.fanTableView.reloadData()
                }
            case .refreshFollowers(let users):
                DispatchQueue.main.async {
                    self.users = users
                    self.fanTableView.reloadData()
                }
            case .error(let error):
                print(error)
            }
        }
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        view.backgroundColor = style.color.background.get()
        
        fanTableView = UITableView()
        fanTableView.translatesAutoresizingMaskIntoConstraints = false
        fanTableView.showsVerticalScrollIndicator = false
        fanTableView.tableFooterView = UIView(frame: .zero)
        fanTableView.separatorStyle = .none
        fanTableView.backgroundColor = style.color.background.get()
        fanTableView.delegate = self
        fanTableView.dataSource = self
        fanTableView.register(
            UINib(nibName: "FanCell", bundle: nil), forCellReuseIdentifier: "FanCell")
        self.view.addSubview(fanTableView)
        
        fanTableView.refreshControl = UIRefreshControl()
        fanTableView.refreshControl?.addTarget(
            self, action: #selector(refreshFan(sender:)), for: .valueChanged)
        self.getUsers()
        
        let constraints: [NSLayoutConstraint] = [
            fanTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            fanTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            fanTableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 32),
            fanTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func getUsers() {
        viewModel.getFollowers()
    }
    
    func refreshUsers() {
        viewModel.refreshFollowers()
    }
    
    @objc private func refreshFan(sender: UIRefreshControl) {
        self.refreshUsers()
        sender.endRefreshing()
    }
}

extension UserListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.users.count
        
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
        let user = self.users[indexPath.section]
        let cell = tableView.reuse(FanCell.self, input: user, for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let fan = self.fans[indexPath.section]
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (self.users.count - indexPath.section) == 2 && self.users.count % per == 0 {
            self.getUsers()
        }
    }
}
