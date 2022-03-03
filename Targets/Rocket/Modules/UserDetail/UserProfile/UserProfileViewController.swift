//
//  UserProfileViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/01.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import InternalDomain
import ImageViewer
import TagListView

final class UserProfileViewController: UIViewController, Instantiable {
    typealias Input = User
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: UserProfileViewModel
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var verticalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    public lazy var scrollStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    
    public let followingSectionHeader = SummarySectionHeader(title: "スキなアーティスト")
    private lazy var followingCellWrapper: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private let liveScheduleSectionHeader = SummarySectionHeader(title: "参戦予定")
    private lazy var liveScheduleTableView: LiveScheduleTableView = {
        let content = LiveScheduleTableView(liveFeeds: [], imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.isScrollEnabled = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 76 * 3),
        ])
        return content
    }()
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = UserProfileViewModel(dependencyProvider: dependencyProvider, input: input)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        viewModel.viewDidLoad()
    }
    
    override func loadView() {
        view = verticalScrollView
        view.backgroundColor = .clear
        view.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: scrollStackView.topAnchor),
            view.bottomAnchor.constraint(equalTo: scrollStackView.bottomAnchor),
            view.leftAnchor.constraint(equalTo: scrollStackView.leftAnchor),
            view.rightAnchor.constraint(equalTo: scrollStackView.rightAnchor),
        ])
        
        scrollStackView.addArrangedSubview(followingSectionHeader)
        NSLayoutConstraint.activate([
            followingSectionHeader.heightAnchor.constraint(equalToConstant: 64),
            followingSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        followingCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(followingCellWrapper)
        
        scrollStackView.addArrangedSubview(liveScheduleSectionHeader)
        NSLayoutConstraint.activate([
            liveScheduleSectionHeader.heightAnchor.constraint(equalToConstant: 64),
            liveScheduleSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        liveScheduleTableView.isHidden = true
        scrollStackView.addArrangedSubview(liveScheduleTableView)
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        scrollStackView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 64),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    func setupFollowingContents(rankings: [GroupTip]) {
        followingCellWrapper.arrangedSubviews.forEach {
            followingCellWrapper.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        rankings.enumerated().forEach { (cellIndex, ranking) in
            let cellContent = GroupRankingCellContent()
            cellContent.inject(input: (
                group: ranking.group,
                count: ranking.tip,
                unit: "pts",
                imagePipeline: dependencyProvider.imagePipeline
            ))
            cellContent.listen { [unowned self] _ in
                groupBannerTapped(cellIndex: cellIndex)
            }
            followingCellWrapper.addArrangedSubview(cellContent)
            
            if cellIndex == (rankings.count - 1) {
                let transparentView = transparentView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 92))
                cellContent.addSubview(transparentView)
            }
        }
        
        func transparentView(frame: CGRect) -> UIView {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            let gradientLayer = CAGradientLayer()
            let topColor = UIColor.clear.withAlphaComponent(0.0).cgColor
            let bottomColor = Brand.color(for: .background(.primary)).withAlphaComponent(1.0).cgColor
            gradientLayer.colors = [topColor, bottomColor]
            gradientLayer.frame = frame
            view.layer.insertSublayer(gradientLayer, at: 0)
            return view
        }
        
        if rankings.isEmpty {
            let emptyView = EmptyCollectionView(emptyType: .groupList, actionButtonTitle: "スキなアーティストにsnackしよう！！")
            emptyView.listen { [unowned self] in
                let vc = SearchGroupViewController(dependencyProvider: dependencyProvider)
                navigationController?.pushViewController(vc, animated: true)
            }
            followingCellWrapper.addArrangedSubview(emptyView)
        }
        followingCellWrapper.isHidden = false
    }
    
    func groupBannerTapped(cellIndex: Int) {
        let group = viewModel.state.rankings[cellIndex]
        let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group.group)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] output in
            switch output {
            case .didGetRanking(let rankings):
                setupFollowingContents(rankings: rankings)
            case .didGetLiveSchedule(let liveFeeds):
                liveScheduleTableView.isHidden = false
                liveScheduleTableView.inject(liveFeeds: liveFeeds)
            case .reportError(let err):
                print(String(describing: err))
//                showAlert()
            }
        })
        .store(in: &cancellables)
        
        followingSectionHeader.listen { [unowned self] in
            let vc = GroupRankingListViewController(dependencyProvider: dependencyProvider, input: .socialTip(viewModel.state.user.id))
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        liveScheduleSectionHeader.listen { [unowned self] in
            let vc = LiveListViewController(dependencyProvider: dependencyProvider, input: .likedFutureLive(viewModel.state.user.id))
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        liveScheduleTableView.listen { [unowned self] live in
            let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: live.live)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension UserProfileViewController: PageContent {
    var scrollView: UIScrollView {
        _ = view
        return self.verticalScrollView
    }
}
