//
//  BandContentsListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import SafariServices
import Endpoint

final class BandContentsListViewController: UIViewController, Instantiable {
    typealias Input = Group

    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input!
    var contents: [GroupFeed] = []
    private var contentsTableView: UITableView!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var viewModel = BandContentsListViewModel(
        apiClient: dependencyProvider.apiClient,
        group: input,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getContents(let contents):
                DispatchQueue.main.async {
                    self.contents = contents
                    self.contentsTableView.reloadData()
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
        
        contentsTableView = UITableView()
        contentsTableView.translatesAutoresizingMaskIntoConstraints = false
        contentsTableView.showsVerticalScrollIndicator = false
        contentsTableView.tableFooterView = UIView(frame: .zero)
        contentsTableView.separatorStyle = .none
        contentsTableView.backgroundColor = style.color.background.get()
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        contentsTableView.register(
            UINib(nibName: "BandContentsCell", bundle: nil), forCellReuseIdentifier: "BandContentsCell")
        self.view.addSubview(contentsTableView)
        
        contentsTableView.refreshControl = UIRefreshControl()
        contentsTableView.refreshControl?.addTarget(
            self, action: #selector(refreshBand(sender:)), for: .valueChanged)
        self.getContents()
        
        let constraints: [NSLayoutConstraint] = [
            contentsTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            contentsTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            contentsTableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 32),
            contentsTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func getContents() {
        viewModel.getContents()
    }
    
    @objc private func refreshBand(sender: UIRefreshControl) {
        self.getContents()
        sender.endRefreshing()
    }
}

extension BandContentsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 10
        
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
        return 200
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let content = self.contents[indexPath.section]
        let cell = tableView.reuse(BandContentsCell.self, input: content, for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let content = self.contents[indexPath.section]
        switch content.feedType {
        case .youtube(let url):
            let safari = SFSafariViewController(url: url)
            present(safari, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
