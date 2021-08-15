//
//  FanListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/08.
//

import UIKit
import Endpoint
import Combine

final class UserListViewController: UIViewController, Instantiable {
    typealias Input = UserListViewModel.Input

    let dependencyProvider: LoggedInDependencyProvider
    private var fanTableView: UITableView!
    
    let viewModel: UserListViewModel
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = UserListViewModel(dependencyProvider: dependencyProvider, input: input)

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
    
    func inject(_ input: Input) {
        viewModel.inject(input)
    }
    
    private func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadTableView:
                self.fanTableView.reloadData()
                self.setTableViewBackgroundView(tableView: self.fanTableView)
            case .jumpToMessageRoom(let room):
                let vc = MessageRoomViewController(dependencyProvider: dependencyProvider, input: room)
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .error(let err):
                print(err)
                self.showAlert()
            }
        }
        .store(in: &cancellables)
    }
    
    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        navigationItem.largeTitleDisplayMode = .never
        
        fanTableView = UITableView()
        fanTableView.translatesAutoresizingMaskIntoConstraints = false
        fanTableView.showsVerticalScrollIndicator = false
        fanTableView.tableFooterView = UIView(frame: .zero)
        fanTableView.separatorStyle = .singleLine
        fanTableView.separatorColor = Brand.color(for: .background(.secondary))
        fanTableView.separatorInset = .zero
        fanTableView.backgroundColor = Brand.color(for: .background(.primary))
        fanTableView.delegate = self
        fanTableView.dataSource = self
        fanTableView.registerCellClass(FanCell.self)
        self.view.addSubview(fanTableView)
        
        NSLayoutConstraint.activate([
            fanTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            fanTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            fanTableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            fanTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
        ])
        
        fanTableView.refreshControl = BrandRefreshControl()
        fanTableView.refreshControl?.addTarget(
            self, action: #selector(refreshFan(sender:)), for: .valueChanged)
    }
    
    @objc private func refreshFan(sender: UIRefreshControl) {
        self.viewModel.refresh()
        sender.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        print("UserListVC.deinit")
    }
}

extension UserListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.state.users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = self.viewModel.state.users[indexPath.row]
        let cell = tableView.dequeueReusableCell(FanCell.self, input: (user: user, isMe: user.id == dependencyProvider.user.id, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .openMessageButtonTapped:
                viewModel.createMessageRoom(partner: user)
            case .userTapped:
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .userList, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = self.viewModel.state.users.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
}
