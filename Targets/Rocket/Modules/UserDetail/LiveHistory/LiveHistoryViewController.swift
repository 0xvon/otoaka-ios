//
//  LiveHistoryViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/03/03.
//

import UIKit
import Endpoint
import Combine
import UIComponent

final class LiveHistoryViewController: UIViewController, Instantiable {
    typealias Input = LiveHistoryViewModel.Input
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: LiveHistoryViewModel
    private var collectionView: UICollectionView!
    private var cancellables: [AnyCancellable] = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = LiveHistoryViewModel(dependencyProvider: dependencyProvider, input: input)
        super.init(nibName: nil, bundle: nil)
        
        title = "ライブ履歴"
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
    
    func setup() {
        view.backgroundColor = .clear
        
        collectionView = UICollectionView(frame: CGRect(x: 16, y: 16, width: UIScreen.main.bounds.size.width - 32, height: UIScreen.main.bounds.size.height - 32), collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.registerCellClass(CollectionListCell.self)
        collectionView.registerCellClass(LiveHistoryHeader.self)
        collectionView.register(CollectionListHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionListHeader.identifier)
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.refreshControl = BrandRefreshControl()
        collectionView.refreshControl?.addTarget(
            self, action: #selector(refresh(sender:)), for: .valueChanged)
    }
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [unowned self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            switch sectionIndex {
            case 0: return headerSection()
            default: return section()
            }
        }
    }
    
    private func headerSection() -> NSCollectionLayoutSection {
        let verticalRectangleItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        )
        let verticalRectangleGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32)),
            subitem: verticalRectangleItem, count: 1
        )
        return NSCollectionLayoutSection(group: verticalRectangleGroup)
    }
    
    private func section() -> NSCollectionLayoutSection {
        let itemCount = 3
        let lineCount = itemCount - 1
        let itemSpacing: CGFloat = 16
        let itemLength = (self.collectionView.bounds.width - (itemSpacing * CGFloat(lineCount))) / CGFloat(itemCount)
        let itemHeight = itemLength * 16 / 9
        
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(itemLength), heightDimension: .absolute(itemHeight))
        )
        let items = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)),
            subitem: item, count: itemCount
        )
        items.interItemSpacing = .fixed(itemSpacing)
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(itemHeight)),
            subitems: [items]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = itemSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: itemSpacing, trailing: 0)
        let sectionHeaderItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [sectionHeaderItem]
        return section
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        viewModel.refresh()
        sender.endRefreshing()
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reload:
                collectionView.reloadData()
                setBackgroundView(isEmpty: viewModel.state.lives.isEmpty)
                collectionView.refreshControl?.endRefreshing()
            case .error(let error):
                collectionView.refreshControl?.endRefreshing()
                print(String(describing: error))
            }
        }
        .store(in: &cancellables)
    }
}

extension LiveHistoryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.state.sections.count + 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        default:
            let sectionTitle = viewModel.state.sections[section - 1]
            return viewModel.sectionItems(section: sectionTitle).count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(LiveHistoryHeader.self, input: (), for: indexPath)
            cell.listen { [unowned self] output in
                switch output {
                case .filterButtonTapped:
                    collectionView.refreshControl?.beginRefreshing()
                    viewModel.injectSequence()
                case .liveStyleFilterChanged(let filter):
                    viewModel.liveStyleFilter(filter: filter)
                }
            }
            return cell
        default:
            let sectionTitle = viewModel.state.sections[indexPath.section - 1]
            let sectionLives = viewModel.sectionItems(section: sectionTitle)
            let live = sectionLives[indexPath.item]
            let cell = collectionView.dequeueReusableCell(CollectionListCell.self, input: (live: live, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section > 0 {
            let sectionTitle = viewModel.state.sections[indexPath.section - 1]
            let sectionLives = viewModel.sectionItems(section: sectionTitle)
            let live = sectionLives[indexPath.item]
            
            let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: live.live)
            navigationController?.pushViewController(vc, animated: true)
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.willDisplay(itemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionTitle = viewModel.state.sections[indexPath.section - 1]
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CollectionListHeader.identifier,
            for: indexPath
        ) as! CollectionListHeader
        header.setTitle(sectionTitle)
        return header
    }
    
    func setBackgroundView(isEmpty: Bool = false) {
        let emptyCollectionView = EmptyCollectionView(emptyType: .pastLive, actionButtonTitle: "ライブを探す")
        emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
        emptyCollectionView.listen { [unowned self] in
            let vc = SearchLiveViewController(dependencyProvider: dependencyProvider)
            navigationController?.pushViewController(vc, animated: true)
        }
        if isEmpty {
            let back = UIView()
            back.translatesAutoresizingMaskIntoConstraints = false
            collectionView.backgroundView = back
            collectionView.addSubview(emptyCollectionView)
        } else {
            collectionView.backgroundView = nil
        }
        if collectionView.backgroundView != nil {
            NSLayoutConstraint.activate([
                emptyCollectionView.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: 32),
                emptyCollectionView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 32),
                emptyCollectionView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            ])
        }
    }
}

extension LiveHistoryViewController: PageContent {
    var scrollView: UIScrollView {
        _ = view
        return self.collectionView
    }
}

class LiveHistoryHeader: UICollectionViewCell, ReusableCell {
    static var reusableIdentifier: String { "LiveHistoryHeader" }
    
    typealias Input = Void
    enum Output {
        case filterButtonTapped
        case liveStyleFilterChanged(LiveStyleFilter)
    }
    
    enum LiveStyleFilter {
        case all, oneman, battle, festival
    }
    private var liveStyleFilter: LiveStyleFilter = .all
    private let _contentView: SummarySectionHeader
    public let liveStyleFilterButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(liveStyleFilterButtonTapped), for: .touchUpInside)
        button.setTitle("全て", for: .normal)
        button.setImage(UIImage(systemName: "chevron.down")?.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal), for: .normal)
        button.imageView?.widthAnchor.constraint(equalToConstant: 12).isActive = true
        button.imageView?.heightAnchor.constraint(equalToConstant: 12).isActive = true
        button.titleLabel?.font = Brand.font(for: .mediumStrong)
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
        return button
    }()
    public let filterButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        button.setTitle("年", for: .normal)
        button.setTitle("アーティスト", for: .selected)
        button.setImage(UIImage(systemName: "arrow.left.arrow.right")?.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal), for: .normal)
        button.imageView?.widthAnchor.constraint(equalToConstant: 12).isActive = true
        button.imageView?.heightAnchor.constraint(equalToConstant: 12).isActive = true
        button.titleLabel?.font = Brand.font(for: .mediumStrong)
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
        return button
    }()
    override init(frame: CGRect) {
        _contentView = SummarySectionHeader(title: "ライブ履歴")
        super.init(frame: frame)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.isUserInteractionEnabled = true
        backgroundColor = .clear
        contentView.addSubview(_contentView)
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -16),
            _contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            _contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: -16),
            _contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        ])
        
        _contentView.seeMoreButton.isHidden = true
        _contentView.addArrangedSubview(liveStyleFilterButton)
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        _contentView.addArrangedSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(equalToConstant: 24),
        ])
        
        _contentView.addArrangedSubview(filterButton)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func inject(input: Input) {
    }
    
    func liveStyle() {
        switch liveStyleFilter {
        case .all:
            liveStyleFilterButton.setTitle("全て", for: .normal)
        case .oneman:
            liveStyleFilterButton.setTitle("ワンマン", for: .normal)
        case .battle:
            liveStyleFilterButton.setTitle("対バン", for: .normal)
        case .festival:
            liveStyleFilterButton.setTitle("フェス", for: .normal)
        }
    }
    
    @objc private func liveStyleFilterButtonTapped() {
        switch liveStyleFilter {
        case .all:
            liveStyleFilter = .oneman
        case .oneman:
            liveStyleFilter = .battle
        case .battle:
            liveStyleFilter = .festival
        case .festival:
            liveStyleFilter = .all
        }
        liveStyle()
        self.listener(.liveStyleFilterChanged(liveStyleFilter))
    }
    
    @objc private func filterButtonTapped() {
        filterButton.isSelected.toggle()
        self.listener(.filterButtonTapped)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
