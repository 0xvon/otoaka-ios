//
//  SocialTipListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/29.
//

import UIKit
import Endpoint
import Combine
import UIComponent

final class SocialTipListViewController: UIViewController, Instantiable {
    typealias Input = SocialTipListViewModel.Input
    
    let dependencyProvider: LoggedInDependencyProvider

    var tableView: UITableView!
    private lazy var _contentView: SummarySectionHeader = {
        let _contentView = SummarySectionHeader(title: "snack履歴")
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.seeMoreButton.isHidden = true
//        _contentView.addArrangedSubview(filterButton)
//        NSLayoutConstraint.activate([
//            _contentView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
//        ])
        return _contentView
    }()
    public lazy var filterButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        button.setTitle("時系列", for: .normal)
        button.setTitle("アーティスト", for: .selected)
        button.setImage(UIImage(systemName: "arrow.left.arrow.right")?.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal), for: .normal)
        button.titleLabel?.font = Brand.font(for: .mediumStrong)
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        return button
    }()
    
    let viewModel: SocialTipListViewModel
    private var cancellables: [AnyCancellable] = []
    
//    private lazy var header: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
//        ])
//
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = Brand.font(for: .largeStrong)
//        label.textColor = Brand.color(for: .text(.primary))
//        label.text = "公式アーティスト"
//        view.addSubview(label)
//        NSLayoutConstraint.activate([
//            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
//            label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
//        ])
//
//        view.addSubview(entriedGroupContent)
//        NSLayoutConstraint.activate([
//            entriedGroupContent.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
//            entriedGroupContent.leftAnchor.constraint(equalTo: view.leftAnchor),
//            entriedGroupContent.rightAnchor.constraint(equalTo: view.rightAnchor),
//            entriedGroupContent.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            entriedGroupContent.heightAnchor.constraint(equalToConstant: 120),
//        ])
//        return view
//    }()
//    private lazy var entriedGroupContent: StoryCollectionView = {
//        let content = StoryCollectionView(dataSource: .groups([]), imagePipeline: dependencyProvider.imagePipeline)
//        content.translatesAutoresizingMaskIntoConstraints = false
//        return content
//    }()
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = SocialTipListViewModel(
            dependencyProvider: dependencyProvider,
            input: input
        )

        super.init(nibName: nil, bundle: nil)
        
        switch input {
        case .myTip(_):
            view.backgroundColor = .clear
        default:
            view.backgroundColor = Brand.color(for: .background(.primary))
        }
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
    
    @objc private func filterButtonTapped() {
        filterButton.isSelected.toggle()
    }
    
    private func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadTableView:
                self.setTableViewBackgroundView(tableView: self.tableView)
                self.tableView.reloadData()
//            case .getEntriedGroups(let groups):
//                entriedGroupContent.inject(dataSource: .groups(groups))
//                self.tableView.reloadData()
            case .error(let error):
                print(String(describing: error))
//                self.showAlert()
            }
        }
        .store(in: &cancellables)
        
//        entriedGroupContent.listen { [unowned self] output in
//            if case let .group(group) = output {
//                let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group)
//                navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }
    
    private func setup() {
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
        switch viewModel.dataSource {
        case .myTip: return 32
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch viewModel.dataSource {
        case .myTip: return _contentView
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tip = viewModel.state.tips[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            SocialTipCell.self,
            input: (tip: tip, imagePipeline: dependencyProvider.imagePipeline),
            for: indexPath
        )
        cell.listen { [unowned self] output in
            switch output {
            case .cellTapped:
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: tip.user)
                navigationController?.pushViewController(vc, animated: true)
            case .artworkTapped:
                switch tip.type {
                case .group(let group):
                    let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group)
                    navigationController?.pushViewController(vc, animated: true)
                case .live(let live):
                    let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: live)
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .tip, actionButtonTitle: nil)
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

extension SocialTipListViewController: PageContent {
    var scrollView: UIScrollView {
        _ = view
        return self.tableView
    }
}
