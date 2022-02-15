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
import Instructions

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
    
    private let likeCountSummaryView = CountSummaryView()
    private let postCountSummaryView = CountSummaryView()
    private let liveActionButton: PrimaryButton = {
        let button = PrimaryButton(text: "")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 24
        button.isHidden = true
        return button
    }()
    private lazy var likeButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 24
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()
    private lazy var ticketStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private let postSectionHeader = SummarySectionHeader(title: "みんなの感想")
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
    
    private let participatingFriendSectionHeader = SummarySectionHeader(title: "参戦する友達")
    private lazy var participatingFriendContent: StoryCollectionView = {
        let content = StoryCollectionView(dataSource: .users([]), imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 120),
        ])
        return content
    }()
    private lazy var participatingFriendWrapper: UIView = Self.addPadding(to: self.participatingFriendContent)
    
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
        stackView.spacing = 0
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
    
    private let coachMarksController = CoachMarksController()
    private lazy var coachSteps: [CoachStep] = [
        CoachStep(view: likeButton, hint: "行く/行ったライブをチェックしよう！チェックしたライブはプロフィールに記録されます！", next: "ok"),
        CoachStep(view: likeCountSummaryView, hint: "ライブに行く予定の友達がひと目で分かるよ！", next: "ok"),
    ]
    private let refreshControl = BrandRefreshControl()
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: LiveDetailViewModel
    let postActionViewModel: PostActionViewModel
    let openMessageViewModel: OpenMessageRoomViewModel
    let pointViewModel: PointViewModel
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        print(input.id)
        self.dependencyProvider = dependencyProvider
        self.viewModel = LiveDetailViewModel(
            dependencyProvider: dependencyProvider,
            live: input
        )
        self.postActionViewModel = PostActionViewModel(dependencyProvider: dependencyProvider)
        self.openMessageViewModel = OpenMessageRoomViewModel(dependencyProvider: dependencyProvider)
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if PRODUCTION
        let userDefaults = UserDefaults.standard
        let key = "LiveDetailVCPresented_v3.2.0.t"
        if !userDefaults.bool(forKey: key) {
            coachMarksController.start(in: .currentWindow(of: self))
            userDefaults.setValue(true, forKey: key)
            userDefaults.synchronize()
        }
        #else
        coachMarksController.start(in: .currentWindow(of: self))
        #endif
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
        ticketStackView.addArrangedSubview(liveActionButton)
        
        NSLayoutConstraint.activate([
            liveActionButton.heightAnchor.constraint(equalToConstant: 48),
            liveActionButton.widthAnchor.constraint(equalToConstant: 136),
        ])
        ticketStackView.addArrangedSubview(likeButton)
        NSLayoutConstraint.activate([
            likeButton.widthAnchor.constraint(equalToConstant: 120)
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
        
        scrollStackView.addArrangedSubview(participatingFriendSectionHeader)
        NSLayoutConstraint.activate([
            participatingFriendSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        participatingFriendWrapper.isHidden = true
        scrollStackView.addArrangedSubview(participatingFriendWrapper)
        
        let bottomSpacer = UIView()
        scrollStackView.addArrangedSubview(bottomSpacer) // Spacer
        NSLayoutConstraint.activate([
            bottomSpacer.heightAnchor.constraint(equalToConstant: 64),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.setRightBarButtonItems([
            UIBarButtonItem(
                image: UIImage(systemName: "ellipsis")!.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal),
                style: .plain,
                target: self,
                action: #selector(settingButtonTapped(_:))
            ),
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(createShare)),
        ], animated: true)
        bind()
        
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        
        headerView.update(input: (live: viewModel.state.live, imagePipeline: dependencyProvider.imagePipeline))
        setupPerformersContents(performers: viewModel.state.live.performers)
    }
    
    func bind() {
        liveActionButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: { [unowned self] in
                if viewModel.isLivePast() {
                    let vc = PostViewController(dependencyProvider: dependencyProvider, input: (live: viewModel.state.live, post: nil))
                    self.navigationController?.pushViewController(vc, animated: true)
                } else if let url = viewModel.state.live.piaEventUrl {
                    openUrl(url: url)
                }
            })
            .store(in: &cancellables)
        
        postActionViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didSettingTapped(let post):
                let alertController = UIAlertController(
                    title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
                let shareTwitterAction = UIAlertAction(
                    title: "Twitterでシェア", style: UIAlertAction.Style.default,
                    handler: { [unowned self] action in
                        shareWithTwitter(type: .post(post.post))
                    })
                let shareInstagramAction = UIAlertAction(
                    title: "インスタでシェア", style: UIAlertAction.Style.default,
                    handler: { [unowned self] action in
                        sharePostWithInstagram(post: post.post)
                    })
                let postAction = UIAlertAction(title: "このライブのレポートを書く", style: .default, handler: { [unowned self] action in
                    guard let live = post.live else { return }
                    let vc = PostViewController(dependencyProvider: dependencyProvider, input: (live: live, post: nil))
                    self.navigationController?.pushViewController(vc, animated: true)
                })
                let cancelAction = UIAlertAction(
                    title: "キャンセル", style: UIAlertAction.Style.cancel,
                    handler: { action in })
                alertController.addAction(shareTwitterAction)
                alertController.addAction(shareInstagramAction)
                alertController.addAction(postAction)
                if post.author.id == dependencyProvider.user.id {
                    let editPostAction = UIAlertAction(title: "編集", style: .default, handler:  { [unowned self] action in
                        if let live = post.live {
                            let vc = PostViewController(dependencyProvider: dependencyProvider, input: (live: live, post: post.post))
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    })
                    let deletePostAction = UIAlertAction(title: "削除", style: .destructive, handler: { [unowned self] action in
                        postActionViewModel.deletePost(post: post)
                    })
                    alertController.addAction(editPostAction)
                    alertController.addAction(deletePostAction)
                }
                alertController.addAction(cancelAction)
                alertController.popoverPresentationController?.sourceView = self.view
                alertController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                self.present(alertController, animated: true, completion: nil)
            case .didDeletePost:
                viewModel.refresh()
            case .didToggleLikePost:
                viewModel.refresh()
            case .pushToCommentList(let input):
                let vc = CommentListViewController(
                    dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToDM(let author):
                openMessageViewModel.createMessageRoom(partner: author)
            case .pushToPlayTrack(let input):
                let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPostAuthor(let user):
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPostDetail(let post):
                let vc = PostDetailViewController(dependencyProvider: dependencyProvider, input: post.post)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToLiveDetail(let live):
                let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: live)
                self.navigationController?.pushViewController(vc, animated: true)
            case .reportError(let err):
                print(String(describing: err))
//                showAlert()
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
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didGetLiveDetail(let liveDetail):
                self.title = liveDetail.live.title
                headerView.update(input: (live: liveDetail.live, imagePipeline: dependencyProvider.imagePipeline))
                likeCountSummaryView.update(input: (title: "参戦", count: liveDetail.likeCount))
                postCountSummaryView.update(input: (title: "感想", count: liveDetail.postCount))
                likeButton.isSelected = liveDetail.isLiked
                likeButton.isEnabled = true
                refreshControl.endRefreshing()
                if viewModel.isLivePast() {
                    liveActionButton.isHidden = false
                    liveActionButton.setTitle("感想を書く", for: .normal)
                    likeButton.setTitle("行った", for: .normal)
                    likeButton.setTitle("参戦済", for: .selected)
                } else if viewModel.state.live.piaEventUrl != nil {
                    liveActionButton.isHidden = false
                    liveActionButton.setTitle("チケット申込", for: .normal)
                    likeButton.setTitle("行く", for: .normal)
                    likeButton.setTitle("参戦予定", for: .selected)
                } else {
                    liveActionButton.isHidden = true
                    likeButton.setTitle("行く", for: .normal)
                    likeButton.setTitle("参戦予定", for: .selected)
                }
                
                participatingFriendSectionHeader.isHidden = false
                participatingFriendWrapper.isHidden = false
                participatingFriendContent.inject(dataSource: .users(liveDetail.participatingFriends))
            case .updatePostSummary(let post):
                let isHidden = post == nil || !viewModel.isLivePast()
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
            case .reportError(let error):
                print(error)
//                self.showAlert()
            case .pushToPostList(let input):
                let vc = PostListViewController(
                    dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .openURLInBrowser(let url):
                openUrl(url: url)
            case .pushToGroup(let group):
                let vc = BandDetailViewController(
                    dependencyProvider: dependencyProvider, input: group)
                self.navigationController?.pushViewController(vc, animated: true)
            case .didToggleLikeLive:
                viewModel.refresh()
            case .openImage(let content):
                let galleryController = GalleryViewController(startIndex: 0, itemsDataSource: content.self, configuration: [.deleteButtonMode(.none), .seeAllCloseButtonMode(.none), .thumbnailsButtonMode(.none)])
                self.present(galleryController, animated: true, completion: nil)
            case .pushToUserList(let input):
                let vc = UserListViewController(dependencyProvider: dependencyProvider, input: input)
                navigationController?.pushViewController(vc, animated: true)
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
        
        postCellContent.listen { [unowned self] output in
            guard let post = viewModel.state.posts.first else { return }
            self.postActionViewModel.postCellEvent(post, event: output)
        }
        
        postSectionHeader.listen { [unowned self] in
            self.viewModel.didTapSeeMore(at: .post)
        }
        
        participatingFriendSectionHeader.listen { [unowned self] in
            let vc = UserListViewController(dependencyProvider: dependencyProvider, input: .users(viewModel.state.liveDetail?.participatingFriends ?? []))
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        participatingFriendContent.listen { [unowned self] output in
            if case let .user(user) = output {
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
                self.navigationController?.pushViewController(vc, animated: true)
            }
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
        let vc = UserListViewController(dependencyProvider: dependencyProvider, input: .liveParticipants(viewModel.state.live.id))
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
    
    @objc private func likeButtonTapped() {
        guard let isLiked = viewModel.state.liveDetail?.isLiked else { return }
        isLiked
            ? pointViewModel.usePoint(point: 100)
            : pointViewModel.addPoint(point: 100)
        likeButton.isEnabled = false
        viewModel.likeButtonTapped()
    }
    
    @objc private func createShare() {
        shareWithTwitter(type: .live(viewModel.state.live)) { [unowned self] isOK in
            if isOK {
                pointViewModel.addPoint(point: 50)
            } else {
                showAlert(title: "シェアできません", message: "Twitterアプリをインストールするとシェアできるようになります！")
            }
        }
    }
    
    @objc private func settingButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "設定", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let editProfileAction = UIAlertAction(title: "編集", style: .default, handler: { [unowned self] _ in
            guard let live = viewModel.state.liveDetail?.live else { return }
            let vc = EditLiveViewController(dependencyProvider: dependencyProvider, input: live)
            navigationController?.pushViewController(vc, animated: true)
        })
        let cancelAction = UIAlertAction(
            title: "キャンセル", style: UIAlertAction.Style.cancel,
            handler: { _ in })
        let actions = [
            editProfileAction,
            cancelAction,
        ]
        actions.forEach { alertController.addAction($0) }
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.barButtonItem = sender
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func openUrl(url: URL) {
        let safari = SFSafariViewController(url: url)
        safari.dismissButtonStyle = .close
        present(safari, animated: true, completion: nil)
    }
    
    private func groupBannerTapped(cellIndex: Int) {
        let group = viewModel.state.live.performers[cellIndex]
        viewModel.didSelectRow(at: .performers(group))
    }
    
    deinit {
        print("LiveDetailVC.deinit")
    }
}

extension LiveDetailViewController: CoachMarksControllerDelegate, CoachMarksControllerDataSource {
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return coachSteps.count
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        return coachMarksController.helper.makeCoachMark(for: coachSteps[index].view)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: (UIView & CoachMarkBodyView), arrowView: (UIView & CoachMarkArrowView)?) {
        let coachStep = self.coachSteps[index]
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        coachViews.bodyView.hintLabel.text = coachStep.hint
        coachViews.bodyView.nextLabel.text = coachStep.next
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}
