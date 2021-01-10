//
//  LiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit
import DomainEntity
import UIComponent
import Combine

final class LiveViewController: UITableViewController {
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
    lazy var createButton: UIButton = {
        let button = UIButton()
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = Brand.font(for: .xxlargeStrong)
        button.addTarget(self, action: #selector(createLive), for: .touchUpInside)
        return button
    }()
    
    let viewModel: LiveViewModel
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = LiveViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ライブ"
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.registerCellClass(LiveCell.self)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        refreshControl = BrandRefreshControl()
        if case .artist = dependencyProvider.user.role  {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: createButton)
        }
        
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
                self.setTableViewBackgroundView(isDisplay: viewModel.lives.isEmpty)
                self.tableView.reloadData()
            case .isRefreshing(let value):
                if value {
                    self.setTableViewBackgroundView(isDisplay: false)
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .reportError(let error):
                self.showAlert(title: "エラー", message: error.localizedDescription)
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @objc private func refresh() {
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
        self.refreshControl?.beginRefreshing()
        viewModel.refresh.send(())
    }
    
    @objc func createLive() {
        let vc = CreateLiveViewController(dependencyProvider: self.dependencyProvider, input: ())
        let nav = BrandNavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
}

extension LiveViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        viewModel.updateScope.send(selectedScope)
    }
}

extension LiveViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchQuery.send(searchController.searchBar.text)
    }
}


extension LiveViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = false
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = true
    }
}

extension LiveViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let live = viewModel.lives[indexPath.row]
        let cell = tableView.dequeueReusableCell(LiveCell.self, input: (live: live, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.lives.count
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplayCell.send(indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 332
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let live = viewModel.lives[indexPath.row]
        let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: live)
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = searchController.searchBar.selectedScopeButtonIndex == 0 ? EmptyCollectionView(emptyType: .live, actionButtonTitle: "バンドを探す") : EmptyCollectionView(emptyType: .ticket, actionButtonTitle: "ライブを探す")
            emptyCollectionView.listen { [unowned self] in
                if searchController.searchBar.selectedScopeButtonIndex == 0 {
                    let vc = SearchResultViewController(dependencyProvider: dependencyProvider)
                    vc.inject(.group(""))
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    searchController.searchBar.selectedScopeButtonIndex = 0
                    viewModel.updateScope.send(0)
                }
            }
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
