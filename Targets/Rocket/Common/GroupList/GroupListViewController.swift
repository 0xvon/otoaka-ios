//
//  BandListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/28.
//

import UIKit
import Endpoint
import Combine

final class GroupListViewController: UIViewController, Instantiable {
    typealias Input = GroupListViewModel.Input


    let dependencyProvider: LoggedInDependencyProvider
    private var groupTableView: UITableView!

    let viewModel: GroupListViewModel
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = GroupListViewModel(
            apiClient: dependencyProvider.apiClient,
            input: input,
            auth: dependencyProvider.auth
        )

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
                print(output)
                self.groupTableView.reloadData()
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
        .store(in: &cancellables)
    }
    private func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        groupTableView = UITableView()
        groupTableView.translatesAutoresizingMaskIntoConstraints = false
        groupTableView.showsVerticalScrollIndicator = false
        groupTableView.tableFooterView = UIView(frame: .zero)
        groupTableView.separatorStyle = .none
        groupTableView.backgroundColor = Brand.color(for: .background(.primary))
        groupTableView.delegate = self
        groupTableView.dataSource = self
        groupTableView.register(
            UINib(nibName: "BandCell", bundle: nil), forCellReuseIdentifier: "BandCell")
        self.view.addSubview(groupTableView)
        
        groupTableView.refreshControl = BrandRefreshControl()
        groupTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)

        let constraints: [NSLayoutConstraint] = [
            groupTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            groupTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            groupTableView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            groupTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func inject(_ input: Input) {
        print(input)
        viewModel.inject(input)
    }
    @objc private func refreshGroups(sender: UIRefreshControl) {
        viewModel.refresh()
        sender.endRefreshing()
    }
}

extension GroupListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.state.groups.count
        
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
        return 250
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let band = self.viewModel.state.groups[indexPath.section]
        let cell = tableView.dequeueReusableCell(BandCell.self, input: band, for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let band = self.viewModel.state.groups[indexPath.section]
        let vc = BandDetailViewController(
            dependencyProvider: self.dependencyProvider, input: band)
        let nav = self.navigationController ?? presentingViewController?.navigationController
        nav?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.willDisplay(rowAt: indexPath)
    }
}
