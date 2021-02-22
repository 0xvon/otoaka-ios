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
            dependencyProvider: dependencyProvider,
            input: input
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    private func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadTableView:
                self.setTableViewBackgroundView(tableView: self.groupTableView)
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
        groupTableView.registerCellClass(GroupCell.self)
        self.view.addSubview(groupTableView)
        
        groupTableView.refreshControl = BrandRefreshControl()
        groupTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)

        let constraints: [NSLayoutConstraint] = [
            groupTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            groupTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            groupTableView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            groupTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func inject(_ input: Input) {
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
        return 282
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = self.viewModel.state.groups[indexPath.section]
        let cell = tableView.dequeueReusableCell(GroupCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
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
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .groupList, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = self.viewModel.state.groups.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
}
