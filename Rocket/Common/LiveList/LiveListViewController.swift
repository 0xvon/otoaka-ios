//
//  LiveListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import Endpoint

final class LiveListViewController: UIViewController, Instantiable {
    typealias Input = Group

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
        group: input,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getLives(let lives):
                DispatchQueue.main.async {
                    self.lives = lives
                    self.liveTableView.reloadData()
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
        
        liveTableView = UITableView()
        liveTableView.translatesAutoresizingMaskIntoConstraints = false
        liveTableView.showsVerticalScrollIndicator = false
        liveTableView.tableFooterView = UIView(frame: .zero)
        liveTableView.separatorStyle = .none
        liveTableView.backgroundColor = style.color.background.get()
        liveTableView.delegate = self
        liveTableView.dataSource = self
        liveTableView.register(
            UINib(nibName: "LiveCell", bundle: nil), forCellReuseIdentifier: "LiveCell")
        self.view.addSubview(liveTableView)
        
        liveTableView.refreshControl = UIRefreshControl()
        liveTableView.refreshControl?.addTarget(
            self, action: #selector(refreshBand(sender:)), for: .valueChanged)
        self.getLives()
        
        let constraints: [NSLayoutConstraint] = [
            liveTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            liveTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            liveTableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 32),
            liveTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func getLives() {
        viewModel.getLives()
    }
    
    @objc private func refreshBand(sender: UIRefreshControl) {
        self.getLives()
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
        let cell = tableView.reuse(LiveCell.self, input: live, for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let live = self.lives[indexPath.section]
        let vc = LiveDetailViewController(dependencyProvider: self.dependencyProvider, input: live)
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

