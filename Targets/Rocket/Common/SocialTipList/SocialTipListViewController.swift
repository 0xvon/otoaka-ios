//
//  SocialTipListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/29.
//

import UIKit
import Endpoint
import Combine

final class SocialTipListViewController: UIViewController, Instantiable {
    typealias Input = SocialTipListViewModel.Input
    
    let dependencyProvider: LoggedInDependencyProvider

    var tableView: UITableView!
    let viewModel: SocialTipListViewModel
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = SocialTipListViewModel(
            dependencyProvider: dependencyProvider,
            input: input
        )

        super.init(nibName: nil, bundle: nil)
        
        title = "snack"
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
                self.setTableViewBackgroundView(tableView: self.tableView)
                self.tableView.reloadData()
            case .error(let error):
                print(String(describing: error))
                self.showAlert()
            }
        }
        .store(in: &cancellables)
    }
    
    private func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCellClass(SocialTipCell.self)
        
        tableView.refreshControl = BrandRefreshControl()
        tableView.refreshControl?.addTarget(
            self, action: #selector(refresh(sender:)), for: .valueChanged)
        self.view.addSubview(tableView)
        
        let constraints: [NSLayoutConstraint] = [
            tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func inject(_ input: Input) {
        viewModel.inject(input)
    }
    @objc private func refresh(sender: UIRefreshControl) {
        viewModel.refresh()
        sender.endRefreshing()
    }
}

extension SocialTipListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.tips.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tip = viewModel.state.tips[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            SocialTipCell.self,
            input: (tip: tip, imagePipeline: dependencyProvider.imagePipeline),
            for: indexPath
        )
//        cell.listen { [unowned self] output in
//            switch output {
//            case .cellTapped: break
////                let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: item.user)
////                navigationController?.pushViewController(vc, animated: true)
//            }
//        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .userList, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = self.viewModel.state.tips.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 32),
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor, constant: -32),
                backgroundView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            ])
        }
    }
}
