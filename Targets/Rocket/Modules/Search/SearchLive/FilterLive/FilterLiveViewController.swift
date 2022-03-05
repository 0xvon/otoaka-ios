//
//  FilterLiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/09/12.
//

import UIKit
import DomainEntity
import UIComponent
import Combine
import SafariServices

final class FilterLiveViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: FilterLiveViewModel
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

    init(dependencyProvider: LoggedInDependencyProvider, groupId: Group.ID?, fromDate: Date?, toDate: Date?) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = FilterLiveViewModel(
            dependencyProvider: dependencyProvider,
            groupId: groupId,
            fromDate: fromDate, toDate: toDate
        )
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedLayoutIncludesOpaqueBars = true
        title = "ライブ検索結果"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCellClass(LiveCell.self)
        refreshControl = BrandRefreshControl()
        
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.showsScopeBar = false
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }

    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateSearchResult(let input):
                self.searchResultController.inject(input)
            case .reloadData:
                self.tableView.reloadData()
                setTableViewBackgroundView(isDisplay: viewModel.state.lives.isEmpty)
            case .isRefreshing(let value):
                if value {
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .didToggleLikeLive: break
            case .reportError(let err):
                print(String(describing: err))
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
}

extension FilterLiveViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        viewModel.updateSearchQuery(query: searchController.searchBar.text)
    }
}

extension FilterLiveViewController: UISearchControllerDelegate {
}

extension FilterLiveViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
    }
}

extension FilterLiveViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var live = viewModel.state.lives[indexPath.row]
        let cell = tableView.dequeueReusableCell(LiveCell.self, input: (live: live, imagePipeline: dependencyProvider.imagePipeline, type: .normal), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .buyTicketButtonTapped:
                guard let url = live.live.piaEventUrl else { return }
                let safari = SFSafariViewController(
                    url: url)
                safari.dismissButtonStyle = .close
                present(safari, animated: true, completion: nil)
            case .likeButtonTapped:
//                live.isLiked
//                   ? pointViewModel.usePoint(point: 100)
//                   : pointViewModel.addPoint(point: 100)
                if live.isLiked {
                    DispatchQueue.main.async { [unowned self] in
                        showConfirmAlert(title: "参戦をやめる", message: "本当に参戦履歴から削除しますか？", callback: { [unowned self] in
                            viewModel.likeLiveButtonTapped(liveFeed: live)
                            live.isLiked.toggle()
                            viewModel.updateLive(live: live)
                            cell.inject(input: (
                                live: live,
                                imagePipeline: dependencyProvider.imagePipeline,
                                type: .normal
                            ))
                        })
                    }
                } else {
                    viewModel.likeLiveButtonTapped(liveFeed: live)
                    live.isLiked.toggle()
                    viewModel.updateLive(live: live)
                    cell.inject(input: (
                        live: live,
                        imagePipeline: dependencyProvider.imagePipeline,
                        type: .normal
                    ))
                }
            case .numOfLikeTapped:
                let vc = UserListViewController(dependencyProvider: dependencyProvider, input: .liveLikedUsers(live.live.id))
                self.navigationController?.pushViewController(vc, animated: true)
            case .reportButtonTapped:
                let vc = PostViewController(dependencyProvider: dependencyProvider, input: (live: live.live, post: nil))
                self.navigationController?.pushViewController(vc, animated: true)
            case .numOfReportTapped:
                let vc = PostListViewController(dependencyProvider: dependencyProvider, input: .livePost(live.live))
                self.navigationController?.pushViewController(vc, animated: true)
            case .selfTapped:
                let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: live.live)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.lives.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .liveList, actionButtonTitle: "ライブ追加する")
            emptyCollectionView.listen { [unowned self] in
                let vc = CreateLiveViewController(dependencyProvider: dependencyProvider, input: ())
                navigationController?.pushViewController(vc, animated: true)
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

