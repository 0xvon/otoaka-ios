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

    var dependencyProvider: LoggedInDependencyProvider!

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

    private let followersSummaryView = FollowersSummaryView()
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
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    // FIXME: Use a safe way to instantiate views from xib
    private lazy var liveCellContent: LiveCellContent = {
        UINib(nibName: "LiveCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! LiveCellContent
    }()
    private lazy var feedCellContent: ArtistFeedCellContent = {
        UINib(nibName: "ArtistFeedCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! ArtistFeedCellContent
    }()

    let refreshControl = UIRefreshControl()

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

        scrollStackView.addArrangedSubview(SummarySectionHeader(title: "LIVE"))
        liveCellContent.isHidden = true
        scrollStackView.addArrangedSubview(liveCellContent)

        scrollStackView.addArrangedSubview(SummarySectionHeader(title: "FEED"))
        feedCellContent.isHidden = true
        scrollStackView.addArrangedSubview(feedCellContent)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
                self.followersSummaryView.updateNumber(count)
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
                self.followingViewModel.didGetGroupDetail(
                    isFollowing: response.isFollowing,
                    followersCount: response.followersCount
                )
                self.setupFloatingItems(displayType: displayType)
            case let .didGetChart(group, item):
                headerView.update(input: (group: group, groupItem: item))
            case .updateLiveSummary(.none):
                self.liveCellContent.isHidden = true
            case .updateLiveSummary(.some(let live)):
                self.liveCellContent.isHidden = false
                self.liveCellContent.inject(input: live)
            case .updateFeedSummary(.none):
                self.feedCellContent.isHidden = true
            case .updateFeedSummary(.some(let feed)):
                self.feedCellContent.isHidden = false
                self.feedCellContent.inject(input: feed)
            case .didCreatedInvitation(let invitation):
                self.showInviteCode(invitationCode: invitation.id)
            case .reportError(let error):
                self.showAlert(title: "エラー", message: error.localizedDescription)
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
                self.present(vc, animated: true, completion: nil)
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
            .sink { [refreshControl, viewModel] _ in
                viewModel.refresh()
                refreshControl.endRefreshing()
            }
            .store(in: &cancellables)

        feedCellContent.listen { [unowned self] output in
            self.viewModel.feedCellEvent(event: output)
        }

        liveCellContent.addTarget(self, action: #selector(liveCellTaped), for: .touchUpInside)
        feedCellContent.addTarget(self, action: #selector(feedCellTaped), for: .touchUpInside)
    }

    func setupViews() {
        headerView.update(input: (group: viewModel.state.group, groupItem: nil))
    }

    private func setupFloatingItems(displayType: BandDetailViewModel.DisplayType) {
        let items: [FloatingButtonItem]
        switch displayType {
        case .member:
            let createEditView = FloatingButtonItem(icon: UIImage(named: "edit")!)
            createEditView.addTarget(self, action: #selector(editGroup), for: .touchUpInside)
            let inviteCodeView = FloatingButtonItem(icon: UIImage(named: "invitation")!)
            inviteCodeView.addTarget(self, action: #selector(inviteGroup), for: .touchUpInside)
            let createShareView = FloatingButtonItem(icon: UIImage(named: "share")!)
            createShareView.addTarget(self, action: #selector(createShare), for: .touchUpInside)
            items = [createEditView, inviteCodeView, createShareView]
        case .group:
            let createShareView = FloatingButtonItem(icon: UIImage(named: "share")!)
            createShareView.addTarget(self, action: #selector(createShare), for: .touchUpInside)
            let createMessageView = FloatingButtonItem(icon: UIImage(named: "mail")!)
            createMessageView.addTarget(self, action: #selector(createMessage), for: .touchUpInside)
            items = [createShareView, createMessageView]
        case .fan:
            let createShareView = FloatingButtonItem(icon: UIImage(named: "share")!)
            createShareView.addTarget(self, action: #selector(createShare), for: .touchUpInside)
            items = [createShareView]
        }
        let floatingController = dependencyProvider.viewHierarchy.floatingViewController
        floatingController.setFloatingButtonItems(items)
    }

    private func showInviteCode(invitationCode: String) {
        let alertController = UIAlertController(
            title: "招待コード", message: nil, preferredStyle: UIAlertController.Style.alert)

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
        }
    }

    @objc func createShare() {
        let shareLiveText: String = "\(viewModel.state.group.name)がオススメだよ！！\n\n via @rocketforband "
        let shareUrl: NSURL = NSURL(string: "https://apps.apple.com/jp/app/id1500148347")!
        let shareImage: UIImage = UIImage(url: viewModel.state.group.artworkURL!.absoluteString)

        let activityItems: [Any] = [shareLiveText, shareUrl, shareImage]
        let activityViewController = UIActivityViewController(
            activityItems: activityItems, applicationActivities: [])

        self.present(activityViewController, animated: true, completion: nil)
    }

    @objc func feedCellTaped() { viewModel.didSelectRow(at: .feed) }
    @objc func liveCellTaped() { viewModel.didSelectRow(at: .live) }

    private func numOfLikeButtonTapped() {
        let vc = UserListViewController(
            dependencyProvider: dependencyProvider,
            input: .followers(viewModel.state.group.id)
        )
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func commentButtonTapped() {
        print("comment")
    }
}

extension BandDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        viewModel.didSelectRow(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc private func seeMoreLive(_ sender: UIButton) {
        let vc = LiveListViewController(
            dependencyProvider: self.dependencyProvider, input: .groupLive(viewModel.state.group))
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func seeMoreContents(_ sender: UIButton) {
        let vc = GroupFeedListViewController(
            dependencyProvider: dependencyProvider, input: viewModel.state.group)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func followersSummaryButtonTapped(_ sender: UIButton) {
        let vc = UserListViewController(
            dependencyProvider: dependencyProvider, input: .followers(self.viewModel.state.group.id)
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
