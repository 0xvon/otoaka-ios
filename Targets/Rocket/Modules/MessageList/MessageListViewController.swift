//
//  MessageListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/05/10.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import Foundation
import InternalDomain

final class MessageListViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: MessageListViewModel
    typealias Input = Void
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = MessageListViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "メッセージ"
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Brand.color(for: .background(.secondary))
        tableView.separatorInset = .zero
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCellClass(MessageListCell.self)
        tableView.tableFooterView = UIView(frame: .zero)
        refreshControl = BrandRefreshControl()
        
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
                tableView.reloadData()
                self.setTableViewBackgroundView(isDisplay: viewModel.state.messageRooms.isEmpty)
            case .isRefreshing(let value):
                if value {
                    self.setTableViewBackgroundView(isDisplay: false)
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .deletedRoom:
                viewModel.refresh()
            case .reportError(let err):
                print(err)
                showAlert()
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @objc private func refresh() {
        self.refreshControl?.beginRefreshing()
        viewModel.refresh()
    }
}

extension MessageListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.messageRooms.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let room = viewModel.state.messageRooms[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            MessageListCell.self,
            input: (
                room: room,
                user: dependencyProvider.user,
                imagePipeline: dependencyProvider.imagePipeline
            ),
            for: indexPath
        )
        cell.listen { [unowned self] output in
            switch output {
            case .userTapped:
                let user = (room.members + [room.owner])
                    .filter { $0.id != dependencyProvider.user.id }.first!
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
                self.navigationController?.pushViewController(vc, animated: true)
            case .roomTapped:
                let vc = MessageRoomViewController(dependencyProvider: dependencyProvider, input: room)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        return cell
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .messageList, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = isDisplay ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 32),
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor, constant: -32),
                backgroundView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            ])
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
}
