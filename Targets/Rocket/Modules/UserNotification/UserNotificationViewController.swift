//
//  UserNotificationViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/06.
//

import UIKit
import Foundation
import UserNotifications
import SafariServices
import UIComponent
import Endpoint
import Combine

final class UserNotificationViewControlelr: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: UserNotificationViewModel
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = UserNotificationViewModel(dependencyProvider: dependencyProvider)
        
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "通知"
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .singleLine
        tableView.registerCellClass(UserNotificationCell.self)
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
                refreshControl?.endRefreshing()
                self.tableView.reloadData()
                self.setTableViewBackgroundView(isDisplay: viewModel.state.notifications.isEmpty)
            case .read: break
            case .selectCell(let notification):
                switch notification.notificationType {
                case let .follow(user):
                    let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
                    navigationController?.pushViewController(vc, animated: true)
                case .likePost(let like):
                    let vc = PostDetailViewController(dependencyProvider: dependencyProvider, input: like.post)
                    navigationController?.pushViewController(vc, animated: true)
                case .postComment(let comment):
                    let vc = PostDetailViewController(dependencyProvider: dependencyProvider, input: comment.post)
                    navigationController?.pushViewController(vc, animated: true)
                default:
                    break
                }
            case let .didPushToPlayTrack(input):
                let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: input)
                navigationController?.pushViewController(vc, animated: true)
            case .error(let error):
                print(error)
                showAlert()
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @objc private func refresh() {
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
        self.refreshControl?.beginRefreshing()
        viewModel.refresh()
    }
}

extension UserNotificationViewControlelr {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.notifications.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notification = viewModel.state.notifications[indexPath.row]
        let cell = tableView.dequeueReusableCell(UserNotificationCell.self, input: (notification: notification, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.read(cellIndex: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .notification, actionButtonTitle: nil)
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
}
