//
//  SelectTrackViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/03.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import Foundation
import InternalDomain

final class SelectTrackViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    typealias Input = Void
    
    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
    lazy var searchController: UISearchController = {
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchBar.returnKeyType = .search
        controller.searchResultsUpdater = self
        controller.delegate = self
        controller.searchBar.delegate = self
        controller.searchBar.placeholder = "ロケバンにいるバンドから検索"
        controller.searchBar.scopeButtonTitles = viewModel.scopes.map(\.description)
        return controller
    }()
    
    let viewModel: SelectTrackViewModel
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = SelectTrackViewModel(dependencyProvider: dependencyProvider, input: input)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "楽曲選択"
        navigationItem.largeTitleDisplayMode = .never
        
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCellClass(GroupCell.self)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        refreshControl = BrandRefreshControl()
        
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.showsScopeBar = true
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateSearchResult(let input):
                self.searchResultController.inject(input)
            case .reloadData:
                self.setTableViewBackgroundView(isDisplay: viewModel.state.groups.isEmpty)
                self.tableView.reloadData()
            case .isRefreshing(let value):
                if value {
                    self.setTableViewBackgroundView(isDisplay: false)
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .selectTrack(let track):
                listener(track)
                self.dismiss(animated: true, completion: nil)
            case .reportError(let error):
                print(error)
                showAlert()
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        searchResultController.listen { [unowned self] output in
            switch output {
            case .track(let track):
                viewModel.didSelectTrack(at: track)
            default: break
            }
        }
    }
    
    @objc private func refresh() {
        self.refreshControl?.beginRefreshing()
        viewModel.refresh()
    }
    
    private var listener: (Track) -> Void = { _  in }
    func listen(_ listener: @escaping (Track) -> Void) {
        self.listener = listener
    }
}

extension SelectTrackViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        viewModel.updateScope(selectedScope)
        viewModel.updateSearchQuery(query: searchController.searchBar.text)
    }
}

extension SelectTrackViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchQuery(query: searchController.searchBar.text)
    }
}

extension SelectTrackViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
    }
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = true
    }
}

extension SelectTrackViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.groups.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 282
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = self.viewModel.state.groups[indexPath.row]
        let cell = tableView.dequeueReusableCell(GroupCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let band = self.viewModel.state.groups[indexPath.row]
        searchController.searchBar.text = band.name
        viewModel.updateSearchQuery(query: band.name)
        searchController.searchBar.becomeFirstResponder()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .followingGroup, actionButtonTitle: nil)
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
