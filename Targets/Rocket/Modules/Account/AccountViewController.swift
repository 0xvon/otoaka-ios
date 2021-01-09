//
//  AccountViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/29.
//

import UIKit
import DomainEntity

final class AccountViewController: UIViewController, Instantiable {
    typealias Input = Void
    var input: Input

    var dependencyProvider: LoggedInDependencyProvider!
    var items: [AccountSettingItem] = []
    var pendingRequestCount = 0

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = Brand.color(for: .background(.cellSelected))
        tableView.register(
            UINib(nibName: "AccountCell", bundle: nil), forCellReuseIdentifier: "AccountCell")
        return tableView
    }()
    private lazy var profileSettingItem: AccountSettingItem = {
        return AccountSettingItem(
            title: "ユーザー編集", image: UIImage(named: "profile"), action: self.setProfile,
            hasNotification: false)
    }()
    private lazy var seeRequestsItem: AccountSettingItem = {
        return AccountSettingItem(
            title: "出演リクエスト一覧", image: UIImage(named: "mail"), action: self.seeRequests,
            hasNotification: self.pendingRequestCount > 0)
    }()
    private lazy var inputInvitationItem: AccountSettingItem = {
        AccountSettingItem(
            title: "招待コードを入力してバンドに参加", image: UIImage(systemName: "person.3.fill")!.withTintColor(.white, renderingMode: .alwaysOriginal), action: self.joinBand, hasNotification: false)
    }()
    private lazy var membershipItem: AccountSettingItem = {
        AccountSettingItem(
            title: "所属バンド一覧", image: UIImage(named: "people"), action: self.memberships, hasNotification: false)
    }()
    private lazy var logoutItem: AccountSettingItem = {
        AccountSettingItem(
            title: "ログアウト", image: UIImage(named: "logout"), action: self.logout,
            hasNotification: false)
    }()
    
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

    lazy var viewModel = AccountViewModel(
        apiClient: dependencyProvider.apiClient,
        user: dependencyProvider.user,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getRequestCount(let count):
                DispatchQueue.main.async {
                    self.pendingRequestCount = count
                    self.seeRequestsItem.hasNotification = count > 0
                    self.tableView.reloadData()
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        
        title = "アカウント設定"
        setAccountSetting()
        viewModel.getPerformanceRequest()
        
        self.view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 48),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])
    }

    private func setAccountSetting() {
        switch dependencyProvider.user.role {
        case .artist(_):
            self.items = [
                profileSettingItem,
                membershipItem,
                seeRequestsItem,
                inputInvitationItem,
                logoutItem,
            ]
        case .fan(_):
            self.items = [
                profileSettingItem,
                logoutItem,
            ]
        }
    }

    private func setProfile() {
        let vc = EditUserViewController(dependencyProvider: dependencyProvider, input: ())
        vc.listen { [unowned self] in
            self.listener(.editUser)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func seeRequests() {
        let vc = PerformanceRequestViewController(dependencyProvider: dependencyProvider, input: ())
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func memberships() {
        let vc = GroupListViewController(dependencyProvider: dependencyProvider, input: .memberships(dependencyProvider.user.id))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func joinBand() {
        let vc = InvitationViewController(dependencyProvider: dependencyProvider, input: ())
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func logout() {
        dependencyProvider.auth.signOut(self) { error in
            if let error = error {
                self.showAlert(title: "エラー", message: String(describing: error))
            }
            self.listener(.signout)
        }
    }
    
    enum ListenerOutput {
        case editUser
        case signout
        case searchGroup
    }
    
    private var listener: (ListenerOutput) -> Void = { _ in }
    func listen(_ listener: @escaping (ListenerOutput) -> Void) {
        self.listener = listener
    }
}

extension AccountViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            AccountCell.self,
            input: (title: item.title, image: item.image, hasNotif: item.hasNotification),
            for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.action()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

struct AccountSettingItem {
    let title: String
    let image: UIImage?
    let action: () -> Void
    var hasNotification: Bool
}
