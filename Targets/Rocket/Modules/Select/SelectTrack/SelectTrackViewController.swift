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
    typealias Input = [Track]
    
    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
    lazy var searchController: UISearchController = {
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchBar.returnKeyType = .search
        controller.searchResultsUpdater = self
        controller.delegate = self
        controller.searchBar.delegate = self
        controller.searchBar.placeholder = "ロケバンにいるアーティストから検索"
        controller.searchBar.scopeButtonTitles = viewModel.scopes.map(\.description)
        return controller
    }()
    lazy var selectButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        button.titleLabel?.textColor = Brand.color(for: .text(.link))
        button.titleLabel?.font = Brand.font(for: .mediumStrong)
        
        return button
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
        extendedLayoutIncludesOpaqueBars = true
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
            case .addTrack:
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: selectButton)
                let cancelButton = searchController.searchBar.value(forKey: "cancelButton") as? UIButton
                cancelButton?.setTitle("\(viewModel.state.selected.count)曲", for: .normal)
                selectButton.setTitle("\(viewModel.state.selected.count)曲選択", for: .normal)
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
    
    @objc private func selectButtonTapped() {
        self.listener(viewModel.state.selected)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func refresh() {
        self.refreshControl?.beginRefreshing()
        viewModel.refresh()
    }
    
    private var listener: ([Track]) -> Void = { _  in }
    func listen(_ listener: @escaping ([Track]) -> Void) {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = self.viewModel.state.groups[indexPath.row]
        let cell = tableView.dequeueReusableCell(GroupCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline, type: .select), for: indexPath)
        cell.listen { [unowned self] _ in
            searchController.searchBar.text = group.group.name
            viewModel.updateSearchQuery(query: group.group.name)
            searchController.searchBar.becomeFirstResponder()
        }
        return cell
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
