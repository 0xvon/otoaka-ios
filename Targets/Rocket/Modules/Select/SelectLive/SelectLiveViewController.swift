//
//  SelectLiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/11.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import Foundation
import InternalDomain

final class SelectLiveViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    
    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
    lazy var searchController: UISearchController = {
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchResultsUpdater = self
        controller.delegate = self
        controller.searchBar.delegate = self
        return controller
    }()
    
    let viewModel: SelectLiveViewModel
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider  = dependencyProvider
        self.viewModel = SelectLiveViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "レポートを書くライブを選択"
        navigationItem.largeTitleDisplayMode = .never
        
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.registerCellClass(LiveCell.self)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        refreshControl = BrandRefreshControl()
        
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateSearchResult(let input):
                self.searchResultController.inject(input)
            case .reloadData:
                self.setTableViewBackgroundView(isDisplay: viewModel.state.lives.isEmpty)
                self.tableView.reloadData()
            case .isRefreshing(let value):
                if value {
                    self.setTableViewBackgroundView(isDisplay: false)
                } else {
                    self.refreshControl?.endRefreshing()
                }
            case .selectLive(let live):
                let vc = PostViewController(dependencyProvider: dependencyProvider, input: (live: live, post: nil))
                self.navigationController?.pushViewController(vc, animated: true)
            case .reportError(let error):
                print(error)
                showAlert()
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        searchResultController.listen { [unowned self] output in
            switch output {
            case .live(let live):
                viewModel.didSelectLive(at: live)
            default: break
            }
        }
    }
    
    @objc private func refresh() {
        guard let refreshControl = refreshControl, refreshControl.isRefreshing else { return }
        self.refreshControl?.beginRefreshing()
        viewModel.refresh()
    }
}

extension SelectLiveViewController: UISearchBarDelegate {
}

extension SelectLiveViewController: UISearchControllerDelegate {
}

extension SelectLiveViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchQuery(query: searchController.searchBar.text)
    }
}

extension SelectLiveViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let live = viewModel.state.lives[indexPath.row]
        let cell = tableView.dequeueReusableCell(LiveCell.self, input: (live: live, imagePipeline: dependencyProvider.imagePipeline, type: .review), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .selfTapped:
                let live = viewModel.state.lives[indexPath.row]
                viewModel.didSelectLive(at: live)
            default: break
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
    }
}
