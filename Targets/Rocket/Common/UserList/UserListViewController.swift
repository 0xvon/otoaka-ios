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
    
    private func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadTableView:
                self.fanTableView.reloadData()
                self.setTableViewBackgroundView(tableView: self.fanTableView)
            case .error(let err):
                self.showAlert(title: "エラー", message: String(describing: err))
            }
        }
        .store(in: &cancellables)
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
        
        let constraints: [NSLayoutConstraint] = [
            fanTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            fanTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            fanTableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            fanTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc private func refreshFan(sender: UIRefreshControl) {
        self.viewModel.refresh()
        sender.endRefreshing()
    }
}

extension UserListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.state.users.count
        
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
        let user = self.viewModel.state.users[indexPath.section]
        let cell = tableView.dequeueReusableCell(FanCell.self, input: (user: user, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let fan = self.fans[indexPath.section]
        tableView.deselectRow(at: indexPath, animated: true)
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
