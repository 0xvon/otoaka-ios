//
//  BandDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import InternalDomain
import ImageViewer
import Instructions

final class BandDetailViewController: UIViewController, Instantiable {
    typealias Input = Group

    private lazy var headerView: BandDetailHeaderView = {
        let headerView = BandDetailHeaderView()
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

    private let followersSummaryView = CountSummaryView()
    private let followButton: ToggleButton = {
        let followButton = ToggleButton()
        followButton.setTitle("フォローする", selected: false)
        followButton.setTitle("フォロー中", selected: true)
        followButton.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)
        return followButton
    }()
    private let socialTipButton: PrimaryButton = {
        let button = PrimaryButton(text: "")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("snack", for: .normal)
        button.layer.cornerRadius = 24
        button.isHidden = true
        return button
    }()
    private lazy var followStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private let liveSectionHeader = SummarySectionHeader(title: "ライブ")
//     FIXME: Use a safe way to instantiate views from xib
    private lazy var liveCellContent: LiveCellContent = {
        let content = UINib(nibName: "LiveCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! LiveCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 300),
        ])
        return content
    }()
    private lazy var liveCellWrapper: UIView = Self.addPadding(to: self.liveCellContent)

    private let postSectionHeader = SummarySectionHeader(title: "ライブレポート")
    private lazy var postCellContent: PostCellContent = {
        let content = UINib(nibName: "PostCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! PostCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    private lazy var postCellWrapper: UIView = Self.addPadding(to: self.postCellContent)
    
    private let socialTipSectionHeader = SummarySectionHeader(title: "snack")
    private lazy var socialTipContent: SocialTipCellContent = {
        let content = SocialTipCellContent()
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    private lazy var socialTipContentWrapper: UIView = Self.addPadding(to: self.socialTipContent)
    
    private let userTipSectionHeader = SummarySectionHeader(title: "snackランキング")
    private lazy var userTipContent: UserTipRankingCollectionView = {
        let content = UserTipRankingCollectionView(tip: [], imagePipeline: dependencyProvider.imagePipeline)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 210)
        ])
        return content
    }()
    private lazy var userTipContentWrapper: UIView = Self.addPadding(to: self.userTipContent)
    
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
        CoachStep(view: followButton, hint: "好きなアーティストをフォローしよう！フォローするといいことがたくさんあります！", next: "ok"),
        CoachStep(view: socialTipButton, hint: "アーティストにsnackしよう！snackをするとあなたがアーティストを宣伝・応援できます！", next: "ok"),
    ]
    
    private let refreshControl = BrandRefreshControl()

    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: BandDetailViewModel
    let postActionViewModel: PostActionViewModel
    let openMessageViewModel: OpenMessageRoomViewModel
    let followingViewModel: FollowingViewModel
    let pointViewModel: PointViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = BandDetailViewModel(
            dependencyProvider: dependencyProvider,
            group: input
        )
        self.postActionViewModel = PostActionViewModel(dependencyProvider: dependencyProvider)
        self.openMessageViewModel = OpenMessageRoomViewModel(dependencyProvider: dependencyProvider)
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)
        self.followingViewModel = FollowingViewModel(
            group: input.id, apiClient: dependencyProvider.apiClient
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if PRODUCTION
        let userDefaults = UserDefaults.standard
        let key = "BandDetailVCPresented_v3.2.0.t"
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

        followStackView.addArrangedSubview(followersSummaryView)
        
        followStackView.addArrangedSubview(socialTipButton)
        NSLayoutConstraint.activate([
            socialTipButton.heightAnchor.constraint(equalToConstant: 48),
            socialTipButton.widthAnchor.constraint(equalToConstant: 136),
        ])
        followStackView.addArrangedSubview(followButton)
        NSLayoutConstraint.activate([
            followButton.heightAnchor.constraint(equalToConstant: 48),
            followButton.widthAnchor.constraint(equalToConstant: 120),
        ])
        followStackView.addArrangedSubview(UIView()) // Spacer

        scrollStackView.addArrangedSubview(followStackView)
        
        scrollStackView.addArrangedSubview(socialTipSectionHeader)
        NSLayoutConstraint.activate([
            socialTipSectionHeader.heightAnchor.constraint(equalToConstant: 52),
            socialTipSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        socialTipContentWrapper.isHidden = true
        scrollStackView.addArrangedSubview(socialTipContentWrapper)
        
        scrollStackView.addArrangedSubview(userTipSectionHeader)
        userTipSectionHeader.isHidden = true
        NSLayoutConstraint.activate([
            userTipSectionHeader.heightAnchor.constraint(equalToConstant: 52),
            userTipSectionHeader.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        userTipContentWrapper.isHidden = true
        scrollStackView.addArrangedSubview(userTipContentWrapper)
        
        let middleSpacer = UIView()
        middleSpacer.translatesAutoresizingMaskIntoConstraints = false
        scrollStackView.addArrangedSubview(middleSpacer) // Spacer
        NSLayoutConstraint.activate([
            middleSpacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        scrollStackView.addArrangedSubview(liveSectionHeader)
        NSLayoutConstraint.activate([
            liveSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        liveCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(liveCellWrapper)

        scrollStackView.addArrangedSubview(postSectionHeader)
        NSLayoutConstraint.activate([
            postSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        postCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(postCellWrapper)

        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
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

        followingViewModel.viewDidLoad()
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        
        headerView.update(input: (group: viewModel.state.group, groupItem: nil, imagePipeline: dependencyProvider.imagePipeline))
    }

    func bind() {
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
        
        followingViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateFollowing(let isFollowing):
                self.followButton.isSelected = isFollowing
            case .updateFollowersCount(let count):
                self.followersSummaryView.update(input: (title: "フォロワー", count: count))
            case .updateIsButtonEnabled(let isEnabled):
                self.followButton.isEnabled = isEnabled
            case .reportError(let error):
                print(error)
//                self.showAlert()
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
        
        socialTipButton.listen { [unowned self] in
            let vc = PaymentSocialTipViewController(dependencyProvider: dependencyProvider, input: .group(viewModel.state.group))
            navigationController?.pushViewController(vc, animated: true)
        }

        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didGetGroupDetail(let response, let displayType):
                self.title = response.group.name
                self.followingViewModel.didGetGroupDetail(
                    isFollowing: response.isFollowing,
                    followersCount: response.followersCount
                )
                socialTipButton.isHidden = false
                self.setupFloatingItems(displayType: displayType)
                refreshControl.endRefreshing()
            case .getGroupTip(let tip):
                let isHidden = tip == nil
                socialTipSectionHeader.isHidden = isHidden
                socialTipContentWrapper.isHidden = isHidden
                if let tip = tip {
                    socialTipContent.inject(input: (tip: tip, imagePipeline: dependencyProvider.imagePipeline))
                }
            case .didGetUserTip(let tips):
                let isHidden = tips.isEmpty
                userTipSectionHeader.isHidden = isHidden
                userTipContentWrapper.isHidden = isHidden
                userTipContent.inject(tip: tips)
            case let .didGetChart(group, item):
                headerView.update(input: (group: group, groupItem: item, imagePipeline: dependencyProvider.imagePipeline))
            case .updateLiveSummary(let liveFeed):
                let isHidden = liveFeed == nil
                self.liveSectionHeader.isHidden = isHidden
                self.liveCellWrapper.isHidden = isHidden
                if let liveFeed = liveFeed {
                    liveCellContent.inject(input: (live: liveFeed, imagePipeline: dependencyProvider.imagePipeline, type: .normal))
                }
            case .updatePostSummary(let post):
                let isHidden = post == nil
                self.postSectionHeader.isHidden = isHidden
                self.postCellWrapper.isHidden = isHidden
                if let post = post {
                    self.postCellContent.inject(input: (
                        post: post, user: dependencyProvider.user,  imagePipeline: dependencyProvider.imagePipeline
                    ))
                }
            case .pushToGroupDetail(let group):
                let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group)
                self.navigationController?.pushViewController(vc, animated: true)
            case .didCreatedInvitation(let invitation):
                self.showInviteCode(invitationCode: invitation.id)
            case .reportError(let error):
                print(error)
//                self.showAlert()
            case .pushToLiveDetail(let input):
                let vc = LiveDetailViewController(
                    dependencyProvider: self.dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
//            case .pushToChartList(let input):
//                let vc = ChartListViewController(
//                    dependencyProvider: self.dependencyProvider, input: input)
//                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToLiveList(let input):
                let vc = LiveListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPostList(let input):
                let vc = PostListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPlayTrack(let input):
                let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .openURLInBrowser(let url):
                let safari = SFSafariViewController(
                    url: url)
                safari.dismissButtonStyle = .close
                present(safari, animated: true, completion: nil)
            case .pushToUserList(let input):
                let vc = UserListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPost(let input):
                let vc = PostViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .didToggleLikeLive:
                viewModel.refresh()
            case .openImage(let content):
                let galleryController = GalleryViewController(startIndex: 0, itemsDataSource: content.self, configuration: [.deleteButtonMode(.none), .seeAllCloseButtonMode(.none), .thumbnailsButtonMode(.none)])
                self.present(galleryController, animated: true, completion: nil)
            }
        }
        .store(in: &cancellables)

        headerView.listen { [viewModel] output in
            viewModel.headerEvent(event: output)
        }
        refreshControl.controlEventPublisher(for: .valueChanged)
            .sink { [viewModel] _ in
                viewModel.refresh()
            }
            .store(in: &cancellables)
        
        socialTipSectionHeader.listen { [unowned self] in
            let vc = SocialTipListViewController(dependencyProvider: dependencyProvider, input: .groupTip(viewModel.state.group.id))
            navigationController?.pushViewController(vc, animated: true)
        }
        
        socialTipContent.listen { [unowned self] _ in
            guard let tip = viewModel.state.tip else { return }
            let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: tip.user)
            navigationController?.pushViewController(vc, animated: true)
        }

        postCellContent.listen { [unowned self] output in
            guard let post = viewModel.state.posts.first else { return }
            postActionViewModel.postCellEvent(post, event: output)
        }

        liveSectionHeader.listen { [unowned self] in
            self.viewModel.didTapSeeMore(at: .live)
        }
        liveCellContent.listen { [unowned self] output in
            viewModel.liveCellEvent(event: output)
        }
        
        postSectionHeader.listen { [unowned self] in
            self.viewModel.didTapSeeMore(at: .post)
        }
        postCellContent.addTarget(self, action: #selector(postCellTaped), for: .touchUpInside)

        followersSummaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(followerSummaryTapped))
        )
        
        userTipSectionHeader.listen { [unowned self] in
            let vc = UserRankingListViewController(dependencyProvider: dependencyProvider, input: .groupTip(viewModel.state.group.id))
            navigationController?.pushViewController(vc, animated: true)
        }
        
        userTipContent.listen { [unowned self] user in
            let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
            navigationController?.pushViewController(vc
                                                     , animated: true)
        }
    }

    func setupViews() {
        headerView.update(input: (group: viewModel.state.group, groupItem: nil, imagePipeline: dependencyProvider.imagePipeline))
    }

    private func setupFloatingItems(displayType: BandDetailViewModel.DisplayType) {
        let items: [FloatingButtonItem]
        switch displayType {
        case .member:
            let createEditView = FloatingButtonItem(icon: UIImage(named: "edit")!)
            createEditView.addTarget(self, action: #selector(editGroup), for: .touchUpInside)
            let inviteCodeView = FloatingButtonItem(icon: UIImage(named: "invitation")!)
            inviteCodeView.addTarget(self, action: #selector(inviteGroup), for: .touchUpInside)
            items = [createEditView, inviteCodeView]
        case .group:
            let createMessageView = FloatingButtonItem(icon: UIImage(named: "mail")!)
            createMessageView.addTarget(self, action: #selector(createMessage), for: .touchUpInside)
            items = [createMessageView]
        case .fan:
            items = []
        }
        let floatingController = dependencyProvider.viewHierarchy.floatingViewController
        floatingController.setFloatingButtonItems(items)
    }

    private func showInviteCode(invitationCode: String) {
        UIPasteboard.general.string = invitationCode
        let alertController = UIAlertController(
            title: "招待コード", message: "コピーしました", preferredStyle: UIAlertController.Style.alert)

        let cancelAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.cancel,
            handler: { action in })
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
        alertController.addTextField(configurationHandler: { (text: UITextField!) -> Void in
            text.delegate = self
            text.text = invitationCode
        })

        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func followButtonTapped() {
        guard let isFollowing = followingViewModel.state.isFollowing else { return }
         isFollowing
            ? pointViewModel.usePoint(point: 100)
            : pointViewModel.addPoint(point: 100)
        followingViewModel.didButtonTapped()
    }

    @objc func editGroup() {
        let vc = EditBandViewController(
            dependencyProvider: dependencyProvider, input: viewModel.state.group)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc func inviteGroup() {
        viewModel.inviteGroup(groupId: viewModel.state.group.id)
    }

    @objc func createMessage() {
        if let twitterId = viewModel.state.group.twitterId {
            let safari = SFSafariViewController(
                url: URL(string: "https://twitter.com/\(twitterId)")!)
            safari.dismissButtonStyle = .close
            present(safari, animated: true, completion: nil)
        } else {
            showAlert(title: "Not Found", message: "このバンドにはTwitterアカウントが登録されていないのでメッセージを送ることができません")
        }
    }

    @objc func createShare(_ sender: UIBarButtonItem) {
        shareWithTwitter(type: .group(viewModel.state.group)) { [unowned self] isOK in
            if isOK {
                pointViewModel.addPoint(point: 100)
            } else {
                showAlert(title: "シェアできません", message: "Twitterアプリをインストールするとシェアできるようになります！")
            }
        }
    }
    
    private func downloadButtonTapped(feed: UserFeedSummary) {
        if let thumbnail = feed.ogpUrl {
            let image = UIImage(url: thumbnail)
            downloadImage(image: image)
        }
    }

    @objc private func postCellTaped() { viewModel.didSelectRow(at: .post) }
    @objc private func liveCellTaped() { viewModel.didSelectRow(at: .live) }

    @objc private func followerSummaryTapped() {
        let vc = UserListViewController(
            dependencyProvider: dependencyProvider,
            input: .followers(viewModel.state.group.id)
        )
        vc.title = "フォロワー"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    deinit {
        print("BandDetailVC.deinit")
    }
}

extension BandDetailViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return false
    }
}

extension BandDetailViewController: CoachMarksControllerDelegate, CoachMarksControllerDataSource {
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
