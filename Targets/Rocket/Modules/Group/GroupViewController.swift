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

final class GroupViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider

    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
    lazy var searchController: UISearchController = {
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchResultsUpdater = self
        controller.delegate = self
        controller.searchBar.delegate = self
        controller.searchBar.scopeButtonTitles = viewModel.scopes.map(\.description)
        return controller
    }()

    let viewModel: GroupViewModel
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = GroupViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "バンド"
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.register(UINib(nibName: "BandCell", bundle: nil), forCellReuseIdentifier: "BandCell")
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        refreshControl = BrandRefreshControl()
        bind()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.showsScopeBar = true
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
                    self.refreshControl?.beginRefreshing()
                } else {
                    self.refreshControl?.endRefreshing()
                }
            }
        }.store(in: &cancellables)

        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    @objc private func refresh() {
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
        viewModel.refresh.send(())
    }
}

extension GroupViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        viewModel.updateScope.send(selectedScope)
    }
}

extension GroupViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = false
    }
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = true
    }
}

extension GroupViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchQuery.send(searchController.searchBar.text)
    }
}

extension GroupViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = viewModel.groups[indexPath.row]
        let cell = tableView.dequeueReusableCell(BandCell.self, input: group, for: indexPath)
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.groups.count
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplayCell.send(indexPath)
    }
}
