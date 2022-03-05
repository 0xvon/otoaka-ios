//
//  PickupViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/01.
//

import UIKit
import Endpoint
import UIComponent
import Combine
import SafariServices

final class PickupViewController: UIViewController, Instantiable {
    typealias Input = Void
    private let refreshControl = BrandRefreshControl()
    private lazy var verticalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        scrollView.refreshControl = self.refreshControl
        return scrollView
    }()
    private lazy var scrollStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private let socialTipEventSectionHeader = SummarySectionHeader(title: "snack event")
    private lazy var socialTipEventContent: SocialTipEventCardCollectionView = {
        let content = SocialTipEventCardCollectionView(socialTipEvents: [], imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    
    private let recommendedGroupSectionHeader = SummarySectionHeader(title: "おすすめアーティスト")
    private lazy var recommendedGroupCollectionView: GroupCollectionView = {
        let content = GroupCollectionView(groups: [], imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    
    private let groupRankingSectionHeader = SummarySectionHeader(title: "デイリーランキング")
    private lazy var groupRankingCollectionView: GroupTipRankingCollectionView = {
        let content = GroupTipRankingCollectionView(tip: [], imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    private lazy var groupRankingCollectionViewWrapper: UIView = Self.addPadding(to: groupRankingCollectionView)
    
    private let upcomingLiveSectionHeader = SummarySectionHeader(title: "直近のライブ")
    private lazy var upcomingLiveCollectionView: LiveCollectionView = {
        let content = LiveCollectionView(lives: [], imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    
    private static func addPadding(to view: UIView) -> UIView {
        let paddingView = UIView()
        paddingView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: paddingView.leftAnchor, constant: 16),
            paddingView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 16),
            view.topAnchor.constraint(equalTo: paddingView.topAnchor),
            view.bottomAnchor.constraint(equalTo: paddingView.bottomAnchor),
        ])
        return paddingView
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: PickupViewModel
    let pointViewModel: PointViewModel
    let postActionViewModel: PostActionViewModel
    let openMessageViewModel: OpenMessageRoomViewModel
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = PickupViewModel(dependencyProvider: dependencyProvider)
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)
        self.postActionViewModel = PostActionViewModel(dependencyProvider: dependencyProvider)
        self.openMessageViewModel = OpenMessageRoomViewModel(dependencyProvider: dependencyProvider)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        self.view.addSubview(verticalScrollView)
        NSLayoutConstraint.activate([
            verticalScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            verticalScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            verticalScrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            verticalScrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        
        verticalScrollView.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            verticalScrollView.topAnchor.constraint(equalTo: scrollStackView.topAnchor),
            verticalScrollView.bottomAnchor.constraint(equalTo: scrollStackView.bottomAnchor),
            verticalScrollView.leftAnchor.constraint(equalTo: scrollStackView.leftAnchor),
            verticalScrollView.rightAnchor.constraint(equalTo: scrollStackView.rightAnchor),
        ])
        
        scrollStackView.addArrangedSubview(socialTipEventSectionHeader)
        NSLayoutConstraint.activate([
            socialTipEventSectionHeader.heightAnchor.constraint(equalToConstant: 52),
            socialTipEventSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        socialTipEventSectionHeader.isHidden = true
        socialTipEventSectionHeader.seeMoreButton.isHidden = true
        socialTipEventContent.isHidden = true
        scrollStackView.addArrangedSubview(socialTipEventContent)
        NSLayoutConstraint.activate([
            socialTipEventContent.heightAnchor.constraint(equalToConstant: 192),
        ])
        
        scrollStackView.addArrangedSubview(groupRankingSectionHeader)
        NSLayoutConstraint.activate([
            groupRankingSectionHeader.heightAnchor.constraint(equalToConstant: 52),
            groupRankingSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        groupRankingSectionHeader.isHidden = true
        groupRankingCollectionViewWrapper.isHidden = true
        scrollStackView.addArrangedSubview(groupRankingCollectionViewWrapper)
        NSLayoutConstraint.activate([
            groupRankingCollectionView.heightAnchor.constraint(equalToConstant: 213),
        ])
        
        let middleSpacer = UIView()
        middleSpacer.translatesAutoresizingMaskIntoConstraints = false
        scrollStackView.addArrangedSubview(middleSpacer)
        NSLayoutConstraint.activate([
            middleSpacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        scrollStackView.addArrangedSubview(recommendedGroupSectionHeader)
        NSLayoutConstraint.activate([
            recommendedGroupSectionHeader.heightAnchor.constraint(equalToConstant: 52),
            recommendedGroupSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        recommendedGroupSectionHeader.isHidden = true
        recommendedGroupCollectionView.isHidden = true
        scrollStackView.addArrangedSubview(recommendedGroupCollectionView)
        NSLayoutConstraint.activate([
            recommendedGroupCollectionView.heightAnchor.constraint(equalToConstant: 232),
        ])
        
        scrollStackView.addArrangedSubview(upcomingLiveSectionHeader)
        NSLayoutConstraint.activate([
            upcomingLiveSectionHeader.heightAnchor.constraint(equalToConstant: 52),
            upcomingLiveSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        upcomingLiveSectionHeader.isHidden = true
        upcomingLiveCollectionView.isHidden = true
        scrollStackView.addArrangedSubview(upcomingLiveCollectionView)
        NSLayoutConstraint.activate([
            upcomingLiveCollectionView.heightAnchor.constraint(equalToConstant: 332),
        ])
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        scrollStackView.addArrangedSubview(bottomSpacer)
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 64),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        viewModel.refresh()
        setup()
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didGetSocialTipEvents:
                refreshControl.endRefreshing()
                socialTipEventSectionHeader.isHidden = false
                socialTipEventContent.isHidden = false
                socialTipEventContent.inject(socialTipEvents: viewModel.state.socialTipEvents)
            case .didGetRecommendedGroups:
                refreshControl.endRefreshing()
                recommendedGroupSectionHeader.isHidden = false
                recommendedGroupCollectionView.isHidden = false
                recommendedGroupCollectionView.inject(groups: viewModel.state.recommendedGroups)
            case .didGetUpcomingLives:
                refreshControl.endRefreshing()
                upcomingLiveSectionHeader.isHidden = false
                upcomingLiveCollectionView.isHidden = false
                upcomingLiveCollectionView.inject(lives: viewModel.state.upcomingLives)
            case .didGetGroupRanking:
                refreshControl.endRefreshing()
                groupRankingSectionHeader.isHidden = false
                groupRankingCollectionViewWrapper.isHidden = false
                groupRankingCollectionView.inject(tip: viewModel.state.groupRanking)
            case .reportError(let error):
                print(String(describing: error))
            }
        }
        .store(in: &cancellables)
        
        openMessageViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didCreateMessageRoom(let room):
                let vc = MessageRoomViewController(dependencyProvider: dependencyProvider, input: room)
                self.navigationController?.pushViewController(vc, animated: true)
            case .reportError(let err):
                print(String(describing: err))
//                showAlert()
            }
        }
        .store(in: &cancellables)
        
        pointViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .addPoint(_):
                self.showSuccessToGetPoint(100)
            default: break
            }
        }
        .store(in: &cancellables)
        
        refreshControl.controlEventPublisher(for: .valueChanged)
            .sink { [viewModel] _ in
                viewModel.refresh()
            }
            .store(in: &cancellables)
        
        recommendedGroupSectionHeader.listen { [unowned self] in
            let vc = GroupListViewController(dependencyProvider: dependencyProvider, input: .allGroup)
            let nav = self.navigationController ?? presentingViewController?.navigationController
            nav?.pushViewController(vc, animated: true)
        }
        
        recommendedGroupCollectionView.listen { [unowned self] output, group in
            switch output {
            case .selfTapped:
                let vc = BandDetailViewController(
                    dependencyProvider: self.dependencyProvider, input: group.group)
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .likeButtonTapped:
//                group.isFollowing
//                   ? pointViewModel.usePoint(point: 100)
//                   : pointViewModel.addPoint(point: 100)
                viewModel.followButtonTapped(group: group)
            case .listenButtonTapped: break
            }
        }
        
        socialTipEventContent.listen { [unowned self] event in
            let vc = SocialTipEventDetailViewController(dependencyProvider: dependencyProvider, input: event)
            let nav = self.navigationController ?? presentingViewController?.navigationController
            nav?.pushViewController(vc, animated: true)
        }
        
        groupRankingSectionHeader.listen { [unowned self] in
            let vc = GroupRankingTermViewController(dependencyProvider: dependencyProvider)
            let nav = self.navigationController ?? presentingViewController?.navigationController
            nav?.pushViewController(vc, animated: true)
        }
        
        groupRankingCollectionView.listen { [unowned self] group in
            let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group)
            let nav = self.navigationController ?? presentingViewController?.navigationController
            nav?.pushViewController(vc, animated: true)
        }
        
        upcomingLiveSectionHeader.listen { [unowned self] in
            let vc = LiveListViewController(dependencyProvider: dependencyProvider, input: .upcoming(dependencyProvider.user))
            let nav = self.navigationController ?? presentingViewController?.navigationController
            nav?.pushViewController(vc, animated: true)
        }
        
        upcomingLiveCollectionView.listen { [unowned self] output, live in
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
                viewModel.likeLiveButtonTapped(liveFeed: live)
            case .numOfLikeTapped:
                let vc = UserListViewController(dependencyProvider: dependencyProvider, input: .liveLikedUsers(live.live.id))
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .reportButtonTapped:
                let vc = PostViewController(dependencyProvider: dependencyProvider, input: (live: live.live, post: nil))
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .numOfReportTapped:
                let vc = PostListViewController(dependencyProvider: dependencyProvider, input: .livePost(live.live))
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .selfTapped:
                let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: live.live)
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            }
        }
    }
}
