//
//  OrganizeRecentlyFollowingViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/15.
//

import Endpoint
import UIKit
import Combine
import UIComponent

final class OrganizeRecentlyFollowingViewController: UIViewController, Instantiable {
    typealias Input = OrganizeRecentlyFollowingViewModel.Input
    let dependencyProvider: LoggedInDependencyProvider

    var tableView: UITableView!
    private lazy var partyContent: PartyCollectionView = {
        let content = PartyCollectionView(items: [], imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 92),
            content.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
        ])
        return content
    }()
    private lazy var postButton: UIButton = {
        let postButton = UIButton()
        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.setTitleColor(Brand.color(for: .brand(.primary)), for: .normal)
        postButton.setTitle("OK", for: .normal)
        postButton.titleLabel?.font = Brand.font(for: .largeStrong)
        postButton.addTarget(self, action: #selector(postButtonTapped), for: .touchUpInside)
        return postButton
    }()
    let viewModel: OrganizeRecentlyFollowingViewModel
    private var cancellables: [AnyCancellable] = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = OrganizeRecentlyFollowingViewModel(dependencyProvider: dependencyProvider, input: input)
        
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        viewModel.refresh()
    }
    
    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCellClass(GroupCell.self)
        
        tableView.refreshControl = BrandRefreshControl()
        tableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)
        self.view.addSubview(tableView)
        
        let constraints: [NSLayoutConstraint] = [
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        
        navigationItem.setRightBarButton(UIBarButtonItem(customView: postButton), animated: true)
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .completed:
                self.navigationController?.popViewController(animated: true)
            case .reloadTableView:
                tableView.reloadData()
                setTableViewBackgroundView(tableView: tableView)
            case .updateParty:
                partyContent.inject(items: viewModel.state.party)
                tableView.reloadData()
            case .partyIsFull:
                showAlert(title: "これ以上選択できません", message: "最近好きなアーティストは最大5組までです")
            case .error(let error):
                postButton.isEnabled = true
                print(String(describing: error))
            }
        }
        .store(in: &cancellables)
        
        partyContent.listen { [unowned self] group in
            viewModel.groupTapped(group)
        }
    }
    
    @objc private func refreshGroups(sender: UIRefreshControl) {
        viewModel.refresh()
        sender.endRefreshing()
    }
    
    @objc private func postButtonTapped() {
        postButton.isEnabled = false
        viewModel.registerButtonTapped()
    }
}

extension OrganizeRecentlyFollowingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.state.followingGroups.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 92
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return partyContent
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = self.viewModel.state.followingGroups[indexPath.row]
        let cell = tableView.dequeueReusableCell(GroupCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline, type: .select), for: indexPath)
        if viewModel.state.party.map({ $0.group.id }).contains(group.group.id) {
            cell.contentView.alpha = 0.3
        } else {
            cell.contentView.alpha = 1.0
        }
        cell.listen { [unowned self] _ in
            viewModel.groupTapped(group)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .followingGroup, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = self.viewModel.state.followingGroups.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 32),
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor, constant: -32),
                backgroundView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            ])
        }
    }
}
