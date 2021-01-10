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
import UIKit

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
        followButton.setTitle("フォロー", selected: false)
        followButton.setTitle("フォロー中", selected: true)
        return followButton
    }()
    private lazy var followStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 16.0
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private let liveSectionHeader = SummarySectionHeader(title: "LIVE")
    // FIXME: Use a safe way to instantiate views from xib
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

    private let feedSectionHeader = SummarySectionHeader(title: "FEED")
    private lazy var feedCellContent: ArtistFeedCellContent = {
        let content = UINib(nibName: "ArtistFeedCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! ArtistFeedCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 300),
        ])
        return content
    }()
    private lazy var feedCellWrapper: UIView = Self.addPadding(to: self.feedCellContent)


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
    let viewModel: BandDetailViewModel
    let followingViewModel: FollowingViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = BandDetailViewModel(
            dependencyProvider: dependencyProvider,
            group: input
        )
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
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: true)
        if let displayType = viewModel.state.displayType {
            setupFloatingItems(displayType: displayType)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
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
        followStackView.addArrangedSubview(followButton)
        NSLayoutConstraint.activate([
            followButton.heightAnchor.constraint(equalToConstant: 44),
            followButton.widthAnchor.constraint(equalToConstant: 100),
        ])
        followStackView.addArrangedSubview(UIView()) // Spacer

        scrollStackView.addArrangedSubview(followStackView)

        scrollStackView.addArrangedSubview(liveSectionHeader)
        NSLayoutConstraint.activate([
            liveSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        liveCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(liveCellWrapper)

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

        followingViewModel.viewDidLoad()
        viewModel.viewDidLoad()
    }

    func bind() {
        followingViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateFollowing(let isFollowing):
                self.followButton.isSelected = isFollowing
            case .updateIsButtonEnabled(let isEnabled):
                self.followButton.isEnabled = isEnabled
            case .updateFollowersCount(let count):
                self.followersSummaryView.update(input: (title: "フォロワー", count: count))
            case .reportError(let error):
                self.showAlert(title: "エラー", message: error.localizedDescription)
            }
        }
        .store(in: &cancellables)

        followButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: followingViewModel.didButtonTapped)
            .store(in: &cancellables)

        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didGetGroupDetail(let response, let displayType):
                self.title = response.group.name
                self.followingViewModel.didGetGroupDetail(
                    isFollowing: response.isFollowing,
                    followersCount: response.followersCount
                )
                self.setupFloatingItems(displayType: displayType)
            case let .didGetChart(group, item):
                headerView.update(input: (group: group, groupItem: item, imagePipeline: dependencyProvider.imagePipeline))
                refreshControl.endRefreshing()
            case .updateLiveSummary(.none):
                self.liveSectionHeader.isHidden = true
                self.liveCellWrapper.isHidden = true
            case .updateLiveSummary(.some(let live)):
                self.liveSectionHeader.isHidden = false
                self.liveCellWrapper.isHidden = false
                self.liveCellContent.inject(input: live)
            case .updateFeedSummary(.none):
                self.feedSectionHeader.isHidden = true
                self.feedCellWrapper.isHidden = true
            case .updateFeedSummary(.some(let feed)):
                self.feedSectionHeader.isHidden = false
                self.feedCellWrapper.isHidden = false
                self.feedCellContent.inject(
                    input: (feed: feed, imagePipeline: dependencyProvider.imagePipeline)
                )

            case .didCreatedInvitation(let invitation):
                self.showInviteCode(invitationCode: invitation.id)
            case .reportError(let error):
                self.showAlert(title: "エラー", message: String(describing: error))
            case .pushToLiveDetail(let input):
                let vc = LiveDetailViewController(
                    dependencyProvider: self.dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToChartList(let input):
                let vc = ChartListViewController(
                    dependencyProvider: self.dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToCommentList(let input):
                let vc = CommentListViewController(
                    dependencyProvider: dependencyProvider, input: input)
                let nav = BrandNavigationController(rootViewController: vc)
                self.present(nav, animated: true, completion: nil)
            case .pushToLiveList(let input):
                let vc = LiveListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToGroupFeedList(let input):
                let vc = GroupFeedListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .openURLInBrowser(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
                present(safari, animated: true, completion: nil)
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

        feedCellContent.listen { [unowned self] output in
            self.viewModel.feedCellEvent(event: output)
        }

        liveSectionHeader.listen { [unowned self] in
            self.viewModel.didTapSeeMore(at: .live)
        }
        feedSectionHeader.listen { [unowned self] in
            self.viewModel.didTapSeeMore(at: .feed)
        }
        liveCellContent.addTarget(self, action: #selector(liveCellTaped), for: .touchUpInside)
        feedCellContent.addTarget(self, action: #selector(feedCellTaped), for: .touchUpInside)

        followersSummaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(followerSummaryTapped))
        )
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
            handler: { action in
                print("close")
            })
        alertController.addAction(cancelAction)

        alertController.addTextField(configurationHandler: { (text: UITextField!) -> Void in
            text.delegate = self
            text.text = invitationCode
        })

        self.present(alertController, animated: true, completion: nil)
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
        let shareLiveText: String = "\(viewModel.state.group.name)がオススメだよ！！\n\n via @rocketforband "
        let shareUrl = URL(string: "https://apps.apple.com/jp/app/id1500148347")!
        let shareImage: UIImage = UIImage(url: viewModel.state.group.artworkURL!.absoluteString)

        let activityItems: [Any] = [shareLiveText, shareUrl, shareImage]
        let activityViewController = UIActivityViewController(
            activityItems: activityItems, applicationActivities: [])

        activityViewController.completionWithItemsHandler = { [dependencyProvider] _, _, _, _ in
            dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: true)
        }
        activityViewController.popoverPresentationController?.barButtonItem = sender
        activityViewController.popoverPresentationController?.permittedArrowDirections = .up
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        self.present(activityViewController, animated: true, completion: nil)
    }

    @objc private func feedCellTaped() { viewModel.didSelectRow(at: .feed) }
    @objc private func liveCellTaped() { viewModel.didSelectRow(at: .live) }

    @objc private func followerSummaryTapped() {
        let vc = UserListViewController(
            dependencyProvider: dependencyProvider,
            input: .followers(viewModel.state.group.id)
        )
        self.navigationController?.pushViewController(vc, animated: true)
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
