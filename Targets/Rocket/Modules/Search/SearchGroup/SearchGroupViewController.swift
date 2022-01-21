//
//  GroupViewController.swift
//  Rocket
//
//  Created by kateinoigakukun on 2021/01/05.
//

import UIKit
import DomainEntity
import UIComponent
import Combine

final class SearchGroupViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: SearchGroupViewModel
    let pointViewModel: PointViewModel
    private var cancellables: [AnyCancellable] = []

    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
    lazy var searchController: UISearchController = {
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchResultsUpdater = self
        controller.delegate = self
        controller.searchBar.delegate = self
        controller.searchBar.showsScopeBar = false
        return controller
    }()

    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = SearchGroupViewModel(dependencyProvider: dependencyProvider)
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedLayoutIncludesOpaqueBars = true
        title = "アーティスト検索"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCellClass(GroupCell.self)
        refreshControl = BrandRefreshControl()
        
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.showsScopeBar = false
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        setupFloatingItems(userRole: dependencyProvider.user.role)
    }

    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateSearchResult(let input):
                self.searchResultController.inject(input)
            case .reloadData:
                self.tableView.reloadData()
            case .isRefreshing(let value):
                if value {
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .didToggleFollowGroup: break
            case .reportError(let err):
                print(err)
//                showAlert()
            }
        }.store(in: &cancellables)
        
        pointViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .addPoint(_):
                self.showSuccessToGetPoint(100)
            default: break
            }
        }
        .store(in: &cancellables)

        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    @objc private func refresh() {
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
        self.refreshControl?.beginRefreshing()
        viewModel.refresh()
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

extension SearchGroupViewController: UISearchBarDelegate {
}

extension SearchGroupViewController: UISearchControllerDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        viewModel.updateSearchQuery(
            query: searchController.searchBar.text
        )
    }
}

extension SearchGroupViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
    }
}

extension SearchGroupViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var group = viewModel.state.groups[indexPath.row]
        let cell = tableView.dequeueReusableCell(GroupCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline, type: .normal), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .selfTapped:
                let vc = BandDetailViewController(
                    dependencyProvider: self.dependencyProvider, input: group.group)
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .likeButtonTapped:
                group.isFollowing
                   ? pointViewModel.usePoint(point: 100)
                   : pointViewModel.addPoint(point: 100)
                viewModel.followButtonTapped(group: group)
                group.isFollowing.toggle()
                viewModel.updateGroup(group: group)
            case .listenButtonTapped: break
            }
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.groups.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = viewModel.state.groups[indexPath.row]
        let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group.group)
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
