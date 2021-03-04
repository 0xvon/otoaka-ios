//
//  UserDetailViewController.swift
//  ImagePipeline
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import Foundation

final class UserDetailViewController: UIViewController, Instantiable {
    typealias Input = User
    private let refreshControl = BrandRefreshControl()
    
    var dependencyProvider: LoggedInDependencyProvider
    let viewModel: UserDetailViewModel
    let userFollowingViewModel: UserFollowingViewModel
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var headerView: UserDetailHeaderView = {
        let headerView = UserDetailHeaderView()
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
    
    private let followButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("フォロー", selected: false)
        button.setTitle("フォロー中", selected: true)
        button.layer.cornerRadius = 24
        return button
    }()
    
    private let editProfileButton: PrimaryButton = {
        let button = PrimaryButton(text: "プロフィール編集")
        button.setImage(UIImage(named: "edit"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 24
        return button
    }()
    
    private lazy var userActionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 16.0
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private lazy var biographyTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = false
        textView.isEditable = false
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        textView.font = Brand.font(for: .mediumStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.backgroundColor = .clear
        return textView
    }()
    
    private let feedSectionHeader = SummarySectionHeader(title: "FEED")
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
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = UserDetailViewModel(dependencyProvider: dependencyProvider, user: input)
        self.userFollowingViewModel = UserFollowingViewModel(dependencyProvider: dependencyProvider, user: input)
        
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
            headerView.heightAnchor.constraint(equalToConstant: 120),
            headerView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        scrollStackView.addArrangedSubview(biographyTextView)
        NSLayoutConstraint.activate([
            biographyTextView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        let mediumSpacer = UIView()
        scrollStackView.addArrangedSubview(mediumSpacer)
        NSLayoutConstraint.activate([
            mediumSpacer.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        userActionStackView.addArrangedSubview(editProfileButton)
        userActionStackView.addArrangedSubview(followButton)
        NSLayoutConstraint.activate([
            editProfileButton.heightAnchor.constraint(equalToConstant: 48),
            followButton.heightAnchor.constraint(equalToConstant: 48),
        ])
        
        scrollStackView.addArrangedSubview(userActionStackView)
        
        let headerSpacer = UIView()
        scrollStackView.addArrangedSubview(headerSpacer) // Spacer
        NSLayoutConstraint.activate([
            headerSpacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
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
        
        setupViews()
        bind()
        
        userFollowingViewModel.viewDidLoad()
    }
    
    func bind() {
        userFollowingViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateFollowersCount(let count):
                guard let userDetail = viewModel.state.userDetail else { return }
                headerView.update(input: (user: viewModel.state.user, followersCount: count, followingUsersCount: userDetail.followingUsersCount,  imagePipeline: dependencyProvider.imagePipeline))
            case .updateIsButtonEnabled(let enabled):
                followButton.isEnabled = enabled
            case .updateFollowing(let isFollowing):
                followButton.isSelected = isFollowing
            case .reportError(let error):
                self.showAlert(title: "エラー", message: error.localizedDescription)
            }
        }
        .store(in: &cancellables)
        
        followButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: userFollowingViewModel.didButtonTapped)
            .store(in: &cancellables)
        
        editProfileButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: didEditProfileButtonTapped)
            .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didRefreshUserDetail(let userDetail):
                switch viewModel.state.displayType {
                case .account:
                    dependencyProvider.user = userDetail.user
                    self.title = "マイページ"
                    biographyTextView.text = userDetail.biography
                    editProfileButton.isHidden = false
                    followButton.isHidden = true
                case .user:
                    self.title = userDetail.name
                    editProfileButton.isHidden = true
                    followButton.isHidden = false
                }
                userFollowingViewModel.didGetUserDetail(isFollowing: userDetail.isFollowing, followersCount: userDetail.followersCount)
                headerView.update(input: (user: viewModel.state.user, followersCount: userDetail.followersCount, followingUsersCount: userDetail.followingUsersCount,  imagePipeline: dependencyProvider.imagePipeline))
                refreshControl.endRefreshing()
            case .didRefreshFeedSummary(let feed):
                let isHidden = feed == nil
                self.feedSectionHeader.isHidden = isHidden
                self.feedCellWrapper.isHidden = isHidden
                if let feed = feed {
                    self.feedCellContent.inject(input: (
                        user: dependencyProvider.user, feed: feed, imagePipeline: dependencyProvider.imagePipeline
                    ))
                }
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
            case .didToggleLikeFeed:
                viewModel.refresh()
            case .didRefreshFollowingGroupSummary:
                break // TODO
            case .pushToFeedList(_):
                break
            case .pushToUserList(let input):
                let vc = UserListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToGroupList(_):
                break
            case .pushToCommentList(let feed):
                let vc = CommentListViewController(
                    dependencyProvider: dependencyProvider, input: feed)
                let nav = BrandNavigationController(rootViewController: vc)
                self.present(nav, animated: true, completion: nil)
            case .openURLInBrowser(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
            case .didShareFeedButtonTapped(let feed):
                switch feed.feedType {
                case .youtube(let url):
                    let shareLiveText: String = "\(feed.text.prefix(20))\n\n by \(feed.author.name)\n\n\(url.absoluteString) via @wooruobudesu #ロック好きならロケバン #ロケバンで好きな曲をシェアしよう"
                    let shareUrl = URL(string: "https://apps.apple.com/jp/app/rocket-for-bands-ii/id1550896325")!

                    let activityItems: [Any] = [shareLiveText, shareUrl]
                    let activityViewController = UIActivityViewController(
                        activityItems: activityItems, applicationActivities: [])

                    activityViewController.completionWithItemsHandler = { [dependencyProvider] _, _, _, _ in
                        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: true)
                    }
                    activityViewController.popoverPresentationController?.permittedArrowDirections = .up
                    dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
                    self.present(activityViewController, animated: true, completion: nil)
                }
            case .reportError(let error):
                self.showAlert(title: "エラー", message: String(describing: error))
            }
        }
        .store(in: &cancellables)
        
        headerView.listen { [viewModel] output in
            viewModel.headerEvent(output: output)
        }
        
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
        
    }
    
    func setupViews() {
        headerView.update(input: (user: viewModel.state.user, followersCount: 0, followingUsersCount: 0, imagePipeline: dependencyProvider.imagePipeline))
    }
    
    func didEditProfileButtonTapped() {
        let vc = EditUserViewController(dependencyProvider: dependencyProvider, input: ())
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func feedCellTaped() { viewModel.didSelectRow(at: .feed) }
}
