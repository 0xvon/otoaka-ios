//
//  UserViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import UIKit
import DomainEntity
import UIComponent
import Combine

final class UserViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: UserViewModel
    private var cancellables: [AnyCancellable] = []
    
    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: dependencyProvider)
    }()
    
    lazy var searchController: UISearchController = {
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchResultsUpdater = self
        controller.delegate = self
        controller.searchBar.delegate = self
        return controller
    }()
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = UserViewModel(dependencyProvider: dependencyProvider)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadData: break
            case .isRefreshing(_): break
            case .updateSearchResult(let input):
                self.searchResultController.inject(input)
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "ユーザー検索"
        
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCellClass(GroupCell.self)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        refreshControl = BrandRefreshControl()
        
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.showsScopeBar = true
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    @objc private func refresh() {
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
//        self.refreshControl?.beginRefreshing()
    }
}

extension UserViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
//        viewModel.updateScope.send(selectedScope)
    }
}

extension UserViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
//        searchController.searchBar.showsScopeBar = false
    }
    func willDismissSearchController(_ searchController: UISearchController) {
//        searchController.searchBar.showsScopeBar = true
    }
}

extension UserViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
//        viewModel.updateSearchQuery.send(searchController.searchBar.text)
        viewModel.updateSearchQuery(query: searchController.searchBar.text)
    }
}
