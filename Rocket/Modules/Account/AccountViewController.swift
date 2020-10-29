//
//  AccountViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/29.
//

import UIKit

final class AccountViewController: UIViewController, Instantiable {
    typealias Input = Void
    
    var dependencyProvider: DependencyProvider!
    var items: [AccountSettingItem] = []
    
    private var tableView: UITableView!
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        
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
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.items = [
            AccountSettingItem(title: "プロフィール設定", image: UIImage(named: "profile"), action: self.setProfile),
            AccountSettingItem(title: "ログアウト", image: UIImage(named: "logout"), action: self.logout)
        ]
        
        self.view.backgroundColor = style.color.subBackground.get()
        tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = style.color.main.get()
        tableView.register(UINib(nibName: "AccountCell", bundle: nil), forCellReuseIdentifier: "AccountCell")
        self.view.addSubview(tableView)
        
        let constraints = [
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 48),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setProfile() {
        print("profile")
    }
    
    private func logout() {
        print("logout")
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
        let cell = tableView.reuse(AccountCell.self, input: (title: item.title, image: item.image), for: indexPath)
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
    let action: () -> ()
}
