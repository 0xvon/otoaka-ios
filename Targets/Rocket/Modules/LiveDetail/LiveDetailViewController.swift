//
//  LiveDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/24.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import UIKit

final class LiveDetailViewController: UIViewController, Instantiable {
    typealias Input = Live
    
    private lazy var headerView: LiveDetailHeaderView = {
        let headerView = LiveDetailHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    
    private lazy var verticalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
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
    
    private let participantsSummaryView = CountSummaryView()
    private let buyTicketButton: PrimaryButton = {
        let buyTicketButton = PrimaryButton(text: "￥----")
        buyTicketButton.setImage(UIImage(named: "ticket"), for: .normal)
        buyTicketButton.translatesAutoresizingMaskIntoConstraints = false
        buyTicketButton.layer.cornerRadius = 24
        return buyTicketButton
    }()
    private lazy var ticketStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 16.0
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private let feedSectionHeader = SummarySectionHeader(title: "FEED")
    // FIXME: Use a safe way to instantiate views from xib
    private lazy var feedCellContent: UserFeedCellContent = {
        let content = UINib(nibName: "UserFeedCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! UserFeedCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 300),
        ])
        return content
    }()
    private lazy var feedCellWrapper: UIView = Self.addPadding(to: self.feedCellContent)
    
    private let performersSectionHeader: SummarySectionHeader = {
        let view = SummarySectionHeader(title: "PERFORMERS")
        view.seeMoreButton.isHidden = true
        return view
    }()
    // FIXME: Use a safe way to instantiate views from xib
    private lazy var performersCellWrapper: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 16.0
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
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
    
    private let refreshControl = BrandRefreshControl()
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: LiveDetailViewModel
    let reserveTicketViewModel: ReserveTicketViewModel
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = LiveDetailViewModel(
            dependencyProvider: dependencyProvider,
            live: input
        )
        self.reserveTicketViewModel = ReserveTicketViewModel(
            live: input,
            apiClient: dependencyProvider.apiClient
        )
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
        view.backgroundColor = Brand.color(for: .background(.primary))
        view.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: scrollStackView.topAnchor),
            view.bottomAnchor.constraint(equalTo: scrollStackView.bottomAnchor),
            view.leftAnchor.constraint(equalTo: scrollStackView.leftAnchor),
            view.rightAnchor.constraint(equalTo: scrollStackView.rightAnchor),
        ])
        
        scrollStackView.addArrangedSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: 250),
            headerView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        ticketStackView.addArrangedSubview(participantsSummaryView)
        ticketStackView.addArrangedSubview(buyTicketButton)
        NSLayoutConstraint.activate([
            buyTicketButton.heightAnchor.constraint(equalToConstant: 48),
            buyTicketButton.widthAnchor.constraint(equalToConstant: 150),
        ])
        ticketStackView.addArrangedSubview(UIView()) // Spacer
        
        scrollStackView.addArrangedSubview(ticketStackView)
        
        scrollStackView.addArrangedSubview(performersSectionHeader)
        NSLayoutConstraint.activate([
            performersSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        performersCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(performersCellWrapper)
        
        scrollStackView.addArrangedSubview(feedSectionHeader)
        NSLayoutConstraint.activate([
            feedSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        feedCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(feedCellWrapper)
        
        let bottomSpacer = UIView()
        scrollStackView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 64),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.setRightBarButton(
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(createShare)),
            animated: false
        )
        setupViews()
        bind()
        
        reserveTicketViewModel.viewDidLoad()
    }
    
    func bind() {
        reserveTicketViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateHasTicket(let text):
                self.buyTicketButton.setTitle(text, for: .normal)
            case .updateIsButtonEnabled(let isEnabled):
                self.buyTicketButton.isEnabled = isEnabled
            case .updateParticipantsCount(let count):
                participantsSummaryView.update(input: (title: "予約者", count: count))
            case .reportError(let error):
                print(error)
                self.showAlert()
            }
        }
        .store(in: &cancellables)
        
        buyTicketButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: reserveTicketViewModel.didButtonTapped)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didGetLiveDetail(let liveDetail):
                self.title = liveDetail.live.title
                self.reserveTicketViewModel.didGetLiveDetail(ticket: liveDetail.ticket, participantsCount: liveDetail.participants)
                headerView.update(input: (live: liveDetail.live, imagePipeline: dependencyProvider.imagePipeline))
                refreshControl.endRefreshing()
            case .updatePerformers(let performers):
                self.setupPerformersContents(performers: performers)
            case .didGetDisplayType(let displayType):
                self.setupFloatingItems(displayType: displayType)
            case .updateFeedSummary(.none):
                self.feedSectionHeader.isHidden = true
                self.feedCellWrapper.isHidden = true
            case .updateFeedSummary(.some(let feed)):
                self.feedSectionHeader.isHidden = false
                self.feedCellWrapper.isHidden = false
                self.feedCellContent.inject(
                    input: (user: dependencyProvider.user, feed: feed, imagePipeline: dependencyProvider.imagePipeline)
                )
            case .didDeleteFeedButtonTapped(let feed):
                let alertController = UIAlertController(
                    title: "フィードを削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

                let acceptAction = UIAlertAction(
                    title: "OK", style: UIAlertAction.Style.default,
                    handler: { [unowned self] action in
                        viewModel.deleteFeed(feed: feed)
                    })
                let cancelAction = UIAlertAction(
                    title: "キャンセル", style: UIAlertAction.Style.cancel,
                    handler: { action in })
                alertController.addAction(acceptAction)
                alertController.addAction(cancelAction)

                self.present(alertController, animated: true, completion: nil)
            case .didDeleteFeed:
                viewModel.refresh()
            case .didShareFeedButtonTapped(let feed):
                shareWithTwitter(type: .feed(feed))
            case .didDownloadButtonTapped(let feed):
                self.downloadButtonTapped(feed: feed)
            case .didInstagramButtonTapped(let feed):
                self.instagramButtonTapped(feed: feed)
            case .reportError(let error):
                print(error)
                self.showAlert()
            case .pushToGroupFeedList(let input):
                let vc = FeedListViewController(
                    dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPlayTrack(let input):
                let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .openURLInBrowser(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
                present(safari, animated: true, completion: nil)
            case .pushToPerformerDetail(let group):
                let vc = BandDetailViewController(
                    dependencyProvider: dependencyProvider, input: group)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToFeedAuthor(let user):
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
                self.navigationController?.pushViewController(vc, animated: true)
            case .presentCommentList(let input):
                let vc = CommentListViewController(
                    dependencyProvider: dependencyProvider, input: input)
                let nav = BrandNavigationController(rootViewController: vc)
                self.present(nav, animated: true, completion: nil)
            }
        }
        .store(in: &cancellables)
        
        refreshControl.controlEventPublisher(for: .valueChanged)
            .sink { [viewModel] _ in
                viewModel.refresh()
            }
            .store(in: &cancellables)
        
        feedCellContent.listen { [unowned self] output in
            self.viewModel.feedCellEvent(event: output)
        }
        
        feedSectionHeader.listen { [unowned self] in
            self.viewModel.didTapSeeMore(at: .feed)
        }
        
        feedCellContent.addTarget(self, action: #selector(feedCellTaped), for: .touchUpInside)
        
        participantsSummaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(numOfParticipantsButtonTapped))
        )
    }
    
    func setupViews() {
        headerView.update(input: (live: viewModel.state.live, imagePipeline: dependencyProvider.imagePipeline))
    }
    
    func setupPerformersContents(performers: [Group]) {
        performersCellWrapper.arrangedSubviews.forEach {
            performersCellWrapper.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        performers.enumerated().forEach { (cellIndex, performer) in
            let cellContent = GroupBannerCell()
            cellContent.update(input: (group: performer, imagePipeline: dependencyProvider.imagePipeline))
            cellContent.listen { [unowned self] in
                groupBannerTapped(cellIndex: cellIndex)
            }
            performersCellWrapper.addArrangedSubview(cellContent)
        }
        performersCellWrapper.isHidden = performers.isEmpty
        performersSectionHeader.isHidden = performers.isEmpty
    }
    
    private func setupFloatingItems(displayType: LiveDetailViewModel.DisplayType) {
        let items: [FloatingButtonItem]
        switch displayType {
        case .host:
            let createEditView = FloatingButtonItem(icon: UIImage(named: "edit")!)
            createEditView.addTarget(self, action: #selector(editLive), for: .touchUpInside)
            items = [createEditView]
        case .group:
            items = []
        case .fan:
            items = []
        }
        let floatingController = dependencyProvider.viewHierarchy.floatingViewController
        floatingController.setFloatingButtonItems(items)
    }
    
    @objc private func numOfParticipantsButtonTapped() {
        let vc = UserListViewController(dependencyProvider: dependencyProvider, input: .liveParticipants(viewModel.state.live.id))
        vc.title = "予約者"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func editLive() {
        let vc = EditLiveViewController(
            dependencyProvider: dependencyProvider, input: viewModel.state.live)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func createShare(_ sender: UIBarButtonItem) {
        let live = viewModel.state.live
        shareWithTwitter(type: .live(live))
    }
    
    private func downloadButtonTapped(feed: UserFeedSummary) {
        if let thumbnail = feed.ogpUrl {
            let image = UIImage(url: thumbnail)
            downloadImage(image: image)
        }
    }
    
    private func instagramButtonTapped(feed: UserFeedSummary) {
        shareFeedWithInstagram(feed: feed)
    }
    
    @objc private func feedCellTaped() { viewModel.didSelectRow(at: .feed) }
    
    private func groupBannerTapped(cellIndex: Int) {
        let group = viewModel.state.live.performers[cellIndex]
        viewModel.didSelectRow(at: .performers(group))
    }
}
