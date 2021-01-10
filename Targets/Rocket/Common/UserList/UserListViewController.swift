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
                    self.setTableViewBackgroundView(tableView: self.fanTableView)
                    self.fanTableView.reloadData()
                }
            case .refreshFollowers(let users):
                DispatchQueue.main.async {
                    self.users = users
                    self.setTableViewBackgroundView(tableView: self.fanTableView)
                    self.fanTableView.reloadData()
                }
            case .getParticipants(let users):
                DispatchQueue.main.async {
                    self.users += users
                    self.setTableViewBackgroundView(tableView: self.fanTableView)
                    self.fanTableView.reloadData()
                }
            case .refreshParticipants(let users):
                DispatchQueue.main.async {
                    self.users = users
                    self.setTableViewBackgroundView(tableView: self.fanTableView)
                    self.fanTableView.reloadData()
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
        
        fanTableView = UITableView()
        fanTableView.translatesAutoresizingMaskIntoConstraints = false
        fanTableView.showsVerticalScrollIndicator = false
        fanTableView.tableFooterView = UIView(frame: .zero)
        fanTableView.separatorStyle = .none
        fanTableView.backgroundColor = Brand.color(for: .background(.primary))
        fanTableView.delegate = self
        fanTableView.dataSource = self
        fanTableView.registerCellClass(FanCell.self)
        self.view.addSubview(fanTableView)
        
        fanTableView.refreshControl = BrandRefreshControl()
        fanTableView.refreshControl?.addTarget(
            self, action: #selector(refreshFan(sender:)), for: .valueChanged)
        self.getUsers()
        
        let constraints: [NSLayoutConstraint] = [
            fanTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            fanTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            fanTableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            fanTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func getUsers() {
        switch input {
        case .followers(_):
            viewModel.getFollowers()
        case .tickets(_):
            viewModel.getParticipants()
        case .none:
            break
        }
    }
    
    func refreshUsers() {
        switch input {
        case .followers(_):
            viewModel.refreshFollowers()
        case .tickets(_):
            viewModel.refreshParticipants()
        case .none:
            break
        }
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = self.users[indexPath.section]
        let cell = tableView.dequeueReusableCell(FanCell.self, input: (user: user, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
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
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .userList, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = self.users.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
}
