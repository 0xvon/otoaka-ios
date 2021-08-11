//
//  LiveListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import Endpoint
import Combine
import SafariServices

final class LiveListViewController: UIViewController, Instantiable {
    typealias Input = LiveListViewModel.Input

    let dependencyProvider: LoggedInDependencyProvider
    private var liveTableView: UITableView!

    let viewModel: LiveListViewModel
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = LiveListViewModel(
            apiClient: dependencyProvider.apiClient,
            input: input,
            auth: dependencyProvider.auth
        )

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }

    private func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadTableView:
                self.setTableViewBackgroundView(tableView: liveTableView)
                self.liveTableView.reloadData()
            case .didToggleLikeLive:
                self.viewModel.refresh()
            case .error(let error):
                print(error)
                self.showAlert()
            }
        }
        .store(in: &cancellables)
    }

    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        liveTableView = UITableView()
        liveTableView.translatesAutoresizingMaskIntoConstraints = false
        liveTableView.showsVerticalScrollIndicator = false
        liveTableView.tableFooterView = UIView(frame: .zero)
        liveTableView.separatorStyle = .none
        liveTableView.backgroundColor = Brand.color(for: .background(.primary))
        liveTableView.delegate = self
        liveTableView.dataSource = self
        liveTableView.registerCellClass(LiveCell.self)
        self.view.addSubview(liveTableView)
        
        liveTableView.refreshControl = BrandRefreshControl()
        liveTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)
        
        let constraints: [NSLayoutConstraint] = [
            liveTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            liveTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            liveTableView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            liveTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    func inject(_ input: Input) {
        viewModel.inject(input)
    }
    
    @objc private func refreshGroups(sender: UIRefreshControl) {
        self.viewModel.refresh()
        sender.endRefreshing()
    }
    
    private var listener: (LiveFeed) -> Void = { _ in }
    func listen(_ listener: @escaping (LiveFeed) -> Void) {
        self.listener = listener
    }
}

extension LiveListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.lives.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let live = self.viewModel.state.lives[indexPath.row]
        var cellType: LiveCellContent.LiveCellContentType
        switch viewModel.dataSource {
        case .searchResultToSelect(_):
            cellType = .review
        default:
            cellType = .normal
        }
        
        let cell = tableView.dequeueReusableCell(LiveCell.self, input: (live: live, imagePipeline: dependencyProvider.imagePipeline, type: cellType), for: indexPath)
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
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .reportButtonTapped:
                let vc = PostViewController(dependencyProvider: dependencyProvider, input: live.live)
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .numOfReportTapped:
                let vc = PostListViewController(dependencyProvider: dependencyProvider, input: .livePost(live.live))
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let live = self.viewModel.state.lives[indexPath.row]
        self.listener(live)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .liveList, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = self.viewModel.state.lives.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
}

