//
//  SearchFriendsViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/05/08.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import Foundation
import InternalDomain

final class SearchFriendsViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: SearchFriendsViewModel
    typealias Input = Void
    private var cancellables: [AnyCancellable] = []
    
    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
    lazy var searchController: UISearchController = {
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchBar.returnKeyType = .search
        controller.searchResultsUpdater = self
        controller.delegate = self
        controller.searchBar.delegate = self
        controller.searchBar.placeholder = "検索"
        controller.searchBar.scopeButtonTitles = viewModel.scopes.map(\.description)
        return controller
    }()
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = SearchFriendsViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "探す"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCellClass(GroupCell.self)
        tableView.registerCellClass(LiveCell.self)
        tableView.registerCellClass(FanCell.self)
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
            case .isRefreshing(let value):
                if value {
                    self.setTableViewBackgroundView(isDisplay: false)
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .reloadData:
                tableView.reloadData()
                
                switch viewModel.state.scope {
                case .fan:
                    self.setTableViewBackgroundView(isDisplay: viewModel.state.fans.isEmpty)
                case .live:
                    self.setTableViewBackgroundView(isDisplay: viewModel.state.lives.isEmpty)
                case .group:
                    self.setTableViewBackgroundView(isDisplay: viewModel.state.groups.isEmpty)
                }
            case .updateSearchResult(let input):
                searchResultController.inject(input)
            case .jumpToMessageRoom(let room):
                let vc = MessageRoomViewController(dependencyProvider: dependencyProvider, input: room)
                self.navigationController?.pushViewController(vc, animated: true)
            case .reportError(let err):
                print(err)
                showAlert()
            case .didToggleLikeLive:
                viewModel.refresh()
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @objc private func refresh() {
        self.refreshControl?.beginRefreshing()
        viewModel.refresh()
    }
}

extension SearchFriendsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        viewModel.updateScope(selectedScope)
        viewModel.updateSearchQuery(query: searchController.searchBar.text)
    }
}

extension SearchFriendsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchQuery(query: searchController.searchBar.text)
    }
}

extension SearchFriendsViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
    }
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsScopeBar = true
    }
}

extension SearchFriendsViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.state.scope {
        case .fan: return viewModel.state.fans.count
        case .live: return viewModel.state.lives.count
        case .group: return viewModel.state.groups.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.state.scope {
        case .fan:
            let fan = viewModel.state.fans[indexPath.row]
            let cell = tableView.dequeueReusableCell(FanCell.self, input: (user: fan, isMe: fan.id == dependencyProvider.user.id, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
            cell.listen { [unowned self] output in
                switch output {
                case .openMessageButtonTapped:
                    viewModel.createMessageRoom(partner: fan)
                case .userTapped:
                    let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: fan)
                    navigationController?.pushViewController(vc, animated: true)
                    tableView.deselectRow(at: indexPath, animated: true)
                }
            }
            return cell
        case .live:
            let live = viewModel.state.lives[indexPath.row]
            let cell = tableView.dequeueReusableCell(LiveCell.self, input: (live: live, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
            cell.listen { [unowned self] output in
                switch output {
                case .buyTicketButtonTapped:
                    guard let url = live.live.piaEventUrl else { return }
                    let safari = SFSafariViewController(
                        url: url)
                    safari.dismissButtonStyle = .close
                    present(safari, animated: true, completion: nil)
                case .likeButtonTapped:
                    viewModel.likeLiveButtonTapped(liveFeed: live)
                case .numOfLikeTapped:
                    let vc = UserListViewController(dependencyProvider: dependencyProvider, input: .liveLikedUsers(live.live.id))
                    self.navigationController?.pushViewController(vc, animated: true)
                case .reportButtonTapped:
                    let vc = PostViewController(dependencyProvider: dependencyProvider, input: live.live)
                    self.navigationController?.pushViewController(vc, animated: true)
                case .numOfReportTapped:
                    let vc = PostListViewController(dependencyProvider: dependencyProvider, input: .livePost(live.live))
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            return cell
        case .group:
            let group = viewModel.state.groups[indexPath.row]
            let cell = tableView.dequeueReusableCell(GroupCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.state.scope {
        case .group:
            let group = viewModel.state.groups[indexPath.row]
            let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group)
            self.navigationController?.pushViewController(vc, animated: true)
        default: break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        switch viewModel.state.scope {
        case .fan:
            let emptyCollectionView: EmptyCollectionView = {
                let emptyCollectionView = EmptyCollectionView(emptyType: .userList, actionButtonTitle: nil)
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
        case .live:
            let emptyCollectionView: EmptyCollectionView = {
                let emptyCollectionView = EmptyCollectionView(emptyType: .live, actionButtonTitle: nil)
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
        case .group:
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
}
