//
//  TrackListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/03.
//

import UIKit
import Endpoint
import Combine
import InternalDomain

final class TrackListViewController: UIViewController, Instantiable {
    typealias Input = TrackListViewModel.Input
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: TrackListViewModel
    private var cancellables: [AnyCancellable] = []
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.backgroundColor = Brand.color(for: .background(.primary))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCellClass(TrackCell.self)
        
        tableView.refreshControl = BrandRefreshControl()
        tableView.refreshControl?.addTarget(
            self, action: #selector(refresh(sender:)), for: .valueChanged)
        
        return tableView
    }()
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = TrackListViewModel(dependencyProvider: dependencyProvider, input: input)
        
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
    
    func inject(_ input: Input, isToSelect: Bool = false) {
        viewModel.inject(input, isToSelect: isToSelect)
    }
    
    private func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadTableView:
                self.tableView.reloadData()
                setTableViewBackgroundView(isDisplay: viewModel.state.tracks.isEmpty)
            case .error(let err):
                print(err)
                self.showAlert()
            }
        }
        .store(in: &cancellables)
    }
    
    func setup() {
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        self.viewModel.refresh()
        sender.endRefreshing()
    }
    
    private var listener: (Track) -> Void = { _ in }
    func listen(_ listener: @escaping (Track) -> Void) {
        self.listener = listener
    }
}

extension TrackListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = viewModel.state.tracks[indexPath.row]
        let cell = tableView.dequeueReusableCell(TrackCell.self, input: (track: track, isEdittable: false, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .playButtonTapped:
                let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: .track(track))
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .groupTapped: break
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = viewModel.state.tracks[indexPath.row]
        if viewModel.state.isToSelect {
            self.listener(track)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .chartList, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = isDisplay ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
}
