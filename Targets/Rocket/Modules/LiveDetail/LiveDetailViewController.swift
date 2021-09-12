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
import ImageViewer

final class LiveDetailViewController: UIViewController, Instantiable {
    typealias Input = LiveFeed
    
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
    
    private let likeCountSummaryView = CountSummaryView()
    private let postCountSummaryView = CountSummaryView()
    private let buyTicketButton: PrimaryButton = {
        let buyTicketButton = PrimaryButton(text: "チケット申込")
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
        stackView.spacing = 4
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private let postSectionHeader = SummarySectionHeader(title: "このライブのレポート")
    // FIXME: Use a safe way to instantiate views from xib
    private lazy var postCellContent: PostCellContent = {
        let content = UINib(nibName: "PostCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! PostCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            content.heightAnchor.constraint(equalToConstant: 300),
//        ])
        return content
    }()
    private lazy var postCellWrapper: UIView = Self.addPadding(to: self.postCellContent)
    
    private let performersSectionHeader: SummarySectionHeader = {
        let view = SummarySectionHeader(title: "出演アーティスト")
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
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = LiveDetailViewModel(
            dependencyProvider: dependencyProvider,
            live: input
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
        
        ticketStackView.addArrangedSubview(likeCountSummaryView)
        ticketStackView.addArrangedSubview(postCountSummaryView)
        ticketStackView.addArrangedSubview(buyTicketButton)
        NSLayoutConstraint.activate([
            buyTicketButton.heightAnchor.constraint(equalToConstant: 48),
            buyTicketButton.widthAnchor.constraint(equalToConstant: 200),
        ])
        ticketStackView.addArrangedSubview(UIView()) // Spacer
        
        scrollStackView.addArrangedSubview(ticketStackView)
        
        scrollStackView.addArrangedSubview(performersSectionHeader)
        NSLayoutConstraint.activate([
            performersSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        performersCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(performersCellWrapper)
        
        scrollStackView.addArrangedSubview(postSectionHeader)
        NSLayoutConstraint.activate([
            postSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        postCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(postCellWrapper)
        
        let bottomSpacer = UIView()
        scrollStackView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 64),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        navigationItem.setRightBarButton(
//            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(createShare)),
//            animated: false
//        )
        bind()
        
    }
    
    func bind() {
        buyTicketButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: { [unowned self] in
                if let url = viewModel.state.live.live.piaEventUrl {
                    openUrl(url: url)
                }
            })
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didGetLiveDetail(let liveDetail):
                self.title = liveDetail.live.title
                headerView.update(input: (live: liveDetail, imagePipeline: dependencyProvider.imagePipeline))
                likeCountSummaryView.update(input: (title: "行きたい", count: liveDetail.likeCount))
                buyTicketButton.isHidden = liveDetail.live.piaEventUrl == nil
                postCountSummaryView.update(input: (title: "レポート", count: viewModel.state.live.postCount))
                refreshControl.endRefreshing()
            case .updatePerformers(let performers):
                self.setupPerformersContents(performers: performers)
            case .updatePostSummary(let post):
                let isHidden = post == nil
                self.postSectionHeader.isHidden = isHidden
                self.postCellWrapper.isHidden = isHidden
                if let post = post {
                    self.postCellContent.inject(
                        input: (
                            post: post,
                            user: dependencyProvider.user,
                            imagePipeline: dependencyProvider.imagePipeline
                        )
                    )
                }
            case .didDeletePost:
                viewModel.refresh()
            case .didInstagramButtonTapped(let post):
                sharePostWithInstagram(post: post.post)
            case .reportError(let error):
                print(error)
                self.showAlert()
            case .pushToPostList(let input):
                let vc = PostListViewController(
                    dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPlayTrack(let input):
                let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToTrackList(let input):
                let vc = TrackListViewController(dependencyProvider: dependencyProvider, input: input)
                navigationController?.pushViewController(vc, animated: true)
            case .openURLInBrowser(let url):
                openUrl(url: url)
            case .pushToGroup(let group):
                let vc = BandDetailViewController(
                    dependencyProvider: dependencyProvider, input: group)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToUser(let user):
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToCommentList(let input):
                let vc = CommentListViewController(
                    dependencyProvider: dependencyProvider, input: input)
                let nav = BrandNavigationController(rootViewController: vc)
                self.present(nav, animated: true, completion: nil)
            case .didToggleLikeLive, .didToggleLikePost:
                viewModel.refresh()
            case .didDeletePostButtonTapped(let post):
                let alertController = UIAlertController(
                    title: "レポートを削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
                let acceptAction = UIAlertAction(
                    title: "OK", style: UIAlertAction.Style.default,
                    handler: { [unowned self] action in
                        viewModel.deletePost(post: post)
                    })
                let cancelAction = UIAlertAction(
                    title: "キャンセル", style: UIAlertAction.Style.cancel,
                    handler: { action in })
                alertController.addAction(acceptAction)
                alertController.addAction(cancelAction)
                alertController.popoverPresentationController?.sourceView = self.view
                alertController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                self.present(alertController, animated: true, completion: nil)
            case .pushToPost(let input):
                let vc = PostViewController(dependencyProvider: dependencyProvider, input: input)
                navigationController?.pushViewController(vc, animated: true)
            case .didTwitterButtonTapped(let post):
                shareWithTwitter(type: .post(post.post))
            case .openImage(let content):
                let galleryController = GalleryViewController(startIndex: 0, itemsDataSource: content.self, configuration: [.deleteButtonMode(.none), .seeAllCloseButtonMode(.none), .thumbnailsButtonMode(.none)])
                self.present(galleryController, animated: true, completion: nil)
            case .pushToUserList(let input):
                let vc = UserListViewController(dependencyProvider: dependencyProvider, input: input)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        .store(in: &cancellables)
        
        refreshControl.controlEventPublisher(for: .valueChanged)
            .sink { [viewModel] _ in
                viewModel.refresh()
            }
            .store(in: &cancellables)
        
        headerView.listen { [unowned self] output in
            switch output {
            case .likeButtonTapped:
                if let isLiked = viewModel.state.liveDetail?.isLiked {
                    isLiked ? viewModel.unlikeLive(live: viewModel.state.live.live) : viewModel.likeLive(live: viewModel.state.live.live)
                }
            }
        }
        
        postCellContent.listen { [unowned self] output in
            self.viewModel.postCellEvent(event: output)
        }
        
        postSectionHeader.listen { [unowned self] in
            self.viewModel.didTapSeeMore(at: .post)
        }
        
        likeCountSummaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(likeCountTapped))
        )
        
        postCountSummaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(postCountTapped))
        )
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
    
    @objc private func numOfParticipantsButtonTapped() {
        let vc = UserListViewController(dependencyProvider: dependencyProvider, input: .liveParticipants(viewModel.state.live.live.id))
        vc.title = "予約者"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func downloadButtonTapped(feed: UserFeedSummary) {
        if let thumbnail = feed.ogpUrl {
            let image = UIImage(url: thumbnail)
            downloadImage(image: image)
        }
    }
    
    @objc private func likeCountTapped() {
        viewModel.likeCountTapped()
    }
    
    @objc private func postCountTapped() {
        viewModel.postCountTapped()
    }
    
    private func openUrl(url: URL) {
        let safari = SFSafariViewController(url: url)
        safari.dismissButtonStyle = .close
        present(safari, animated: true, completion: nil)
    }
    
    private func groupBannerTapped(cellIndex: Int) {
        let group = viewModel.state.live.live.performers[cellIndex]
        viewModel.didSelectRow(at: .performers(group))
    }
}
