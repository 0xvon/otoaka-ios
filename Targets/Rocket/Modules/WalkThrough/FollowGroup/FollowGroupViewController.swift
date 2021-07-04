//
//  FollowGroupViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/07/04.
//

import UIKit
import DomainEntity
import UIComponent
import Combine

final class FollowGroupViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider

    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
//    lazy var searchController: UISearchController = {
//        let controller = BrandSearchController(searchResultsController: self.searchResultController)
//        controller.searchResultsUpdater = self
//        controller.delegate = self
//        controller.searchBar.delegate = self
//        controller.searchBar.scopeButtonTitles = viewModel.scopes.map(\.description)
//        return controller
//    }()
    
    private lazy var skipButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.setTitleColor(Brand.color(for: .text(.toggle)), for: .highlighted)
        button.setTitle("スキップ", for: .normal)
        button.titleLabel?.font = Brand.font(for: .largeStrong)
        return button
    }()

    let viewModel: FollowGroupViewModel
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = FollowGroupViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "おすすめアーティスト"
        
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCellClass(GroupCell.self)
//        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        refreshControl = BrandRefreshControl()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: skipButton)
        
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        searchController.searchBar.showsScopeBar = false
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        setupFloatingItems(userRole: dependencyProvider.user.role)
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }

    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateSearchResult(let input):
                self.searchResultController.inject(input)
            case .reloadData:
                self.refreshControl?.endRefreshing()
                self.setTableViewBackgroundView(isDisplay: viewModel.state.groups.isEmpty)
                self.tableView.reloadData()
            case .isRefreshing(let value):
                if value {
                    self.setTableViewBackgroundView(isDisplay: false)
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .error(let err):
                print(err)
                showAlert()
            }
        }.store(in: &cancellables)

        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        skipButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: skipButtonTapped)
            .store(in: &cancellables)
    }

    @objc private func refresh() {
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
        viewModel.refresh()
//        self.refreshControl?.endRefreshing()
    }
    
    @objc private func skipButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setupFloatingItems(userRole: RoleProperties) {
        let items: [FloatingButtonItem]
        switch userRole {
        case .artist(_):
            let createGroupView = FloatingButtonItem(icon: UIImage(systemName: "person.3.fill")!.withTintColor(.white, renderingMode: .alwaysOriginal))
            createGroupView.addTarget(self, action: #selector(createBand), for: .touchUpInside)
            items = [createGroupView]
        case .fan(_):
            items = []
        }
        let floatingController = dependencyProvider.viewHierarchy.floatingViewController
        floatingController.setFloatingButtonItems(items)
    }
    
    @objc private func createBand() {
        let vc = CreateBandViewController(dependencyProvider: dependencyProvider, input: ())
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension FollowGroupViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = viewModel.state.groups[indexPath.row]
        let cell = tableView.dequeueReusableCell(GroupCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.groups.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 282
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.followGroup(index: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .group, actionButtonTitle: nil)
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
