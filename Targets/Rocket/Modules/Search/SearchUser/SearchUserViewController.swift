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

final class SearchUserViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: SearchUserViewModel
    private var cancellables: [AnyCancellable] = []
    
    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: dependencyProvider)
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
        self.viewModel = SearchUserViewModel(dependencyProvider: dependencyProvider)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadData:
                tableView.reloadData()
            case .isRefreshing(let value):
                if value {
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .updateSearchResult(let input):
                self.searchResultController.inject(input)
            case .reportError(let err):
                print(err)
                showAlert()
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedLayoutIncludesOpaqueBars = true
        title = "ユーザー検索"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Brand.color(for: .background(.secondary))
        tableView.separatorInset = .zero
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCellClass(FanCell.self)
        refreshControl = BrandRefreshControl()
        
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    @objc private func refresh() {
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
        self.refreshControl?.beginRefreshing()
        viewModel.refresh()
    }
}

extension SearchUserViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    }
}

extension SearchUserViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
    }
    func willDismissSearchController(_ searchController: UISearchController) {
    }
}

extension SearchUserViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
//        viewModel.updateSearchQuery.send(searchController.searchBar.text)
        viewModel.updateSearchQuery(query: searchController.searchBar.text)
    }
}

extension SearchUserViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = viewModel.state.users[indexPath.row]
        let cell = tableView.dequeueReusableCell(FanCell.self, input: (user: user, isMe: user.id == dependencyProvider.user.id, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .userTapped:
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .openMessageButtonTapped: break
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
        
    }
}
