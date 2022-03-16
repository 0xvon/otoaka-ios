//
//  GroupCollectionListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/03/16.
//

import UIKit
import Endpoint
import Combine
import UIComponent

final class GroupCollectionListViewController: UIViewController, Instantiable {
    typealias Input = GroupCollectionViewModel.Input
    let dependencyProvider: LoggedInDependencyProvider
    private var collectionView: UICollectionView!
    let viewModel: GroupCollectionViewModel
    private var cancellables: [AnyCancellable] = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = GroupCollectionViewModel(dependencyProvider: dependencyProvider, input: input)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.title = "snack"
        super.viewDidLoad()
        setup()
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func inject(_ input: Input) {
        viewModel.inject(input)
    }
    
    private func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reload:
                collectionView.reloadData()
            case .error(let err):
                collectionView.refreshControl?.endRefreshing()
                print(String(describing: err))
            }
        }
        .store(in: &cancellables)
    }
    
    private func setup() {
        view.backgroundColor = .clear
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        
        collectionView = UICollectionView(
            frame: CGRect(x: 16, y: 16, width: UIScreen.main.bounds.size.width - 32, height: UIScreen.main.bounds.size.height - 32),
            collectionViewLayout: layout
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.registerCellClass(GroupCollectionCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        collectionView.refreshControl = BrandRefreshControl()
        collectionView.refreshControl?.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        self.viewModel.refresh()
        sender.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension GroupCollectionListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.state.groups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let group = viewModel.state.groups[indexPath.item]
        let cell = collectionView.dequeueReusableCell(GroupCollectionCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.viewModel.willDisplay(rowAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let group = viewModel.state.groups[indexPath.item]
        let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group.group)
        let nav = self.navigationController ?? presentingViewController?.navigationController
        nav?.pushViewController(vc, animated: true)
    }
}

extension GroupCollectionListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize = UIScreen.main.bounds.width - 48
        return CGSize(width: screenSize / 2.0, height: screenSize / 2.0)
      }
}
