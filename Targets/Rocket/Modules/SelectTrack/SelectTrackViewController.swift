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
    typealias Input = Group
    
    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
    lazy var searchController: UISearchController = {
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchBar.returnKeyType = .search
        controller.delegate = self
        controller.searchBar.delegate = self
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
        title = "動画選択"
        navigationItem.largeTitleDisplayMode = .never
        
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCellClass(TrackCell.self)
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
                self.setTableViewBackgroundView(isDisplay: viewModel.state.tracks.isEmpty)
                self.tableView.reloadData()
            case .isRefreshing(let value):
                if value {
                    self.setTableViewBackgroundView(isDisplay: false)
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .selectTrack(let track):
                listener(viewModel.state.group, track)
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
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
        self.refreshControl?.beginRefreshing()
        viewModel.refresh()
    }
    
    private var listener: (Group, InternalDomain.ChannelDetail.ChannelItem) -> Void = { _, _  in }
    func listen(_ listener: @escaping (Group, InternalDomain.ChannelDetail.ChannelItem) -> Void) {
        self.listener = listener
    }
}

extension SelectTrackViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        viewModel.updateSearchQuery(query: searchController.searchBar.text)
    }
}

extension SelectTrackViewController: UISearchControllerDelegate {
}

extension SelectTrackViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.tracks.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 92
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = viewModel.state.tracks[indexPath.row]
        let cell = tableView.dequeueReusableCell(TrackCell.self, input: (track: track, group: viewModel.state.group, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .playButtonTapped:
                guard let videoId = track.id.videoId else { return }
                let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: .youtubeVideo(videoId))
                self.navigationController?.pushViewController(vc, animated: true)
            case .groupTapped: break
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = viewModel.state.tracks[indexPath.row]
        viewModel.didSelectTrack(at: track)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .chart, actionButtonTitle: nil)
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
