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
import TagListView
import ImageViewer

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
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private lazy var scrollStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()
    
    private let followButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("フォロー", selected: false)
        button.layer.cornerRadius = 24
        return button
    }()
    
    private let sendMessageButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("メッセージ", selected: false)
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
        stackView.distribution = .fillEqually
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
    private lazy var tagListView: TagListView = {
        let tagListView = TagListView()
        tagListView.translatesAutoresizingMaskIntoConstraints = false
        tagListView.textColor = Brand.color(for: .text(.primary))
        tagListView.textFont = Brand.font(for: .smallStrong)
        tagListView.tagBackgroundColor = Brand.color(for: .background(.link))
        tagListView.alignment = .leading
        tagListView.cornerRadius = 10
        tagListView.paddingY = 4
        tagListView.paddingX = 8
        tagListView.marginY = 8
        tagListView.marginX = 8
        return tagListView
    }()
    private lazy var snsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 12
        stackView.axis = .vertical
        stackView.distribution = .fill
        
        stackView.addArrangedSubview(twitterStackView)
        NSLayoutConstraint.activate([
            twitterStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            twitterStackView.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        stackView.addArrangedSubview(instagramStackView)
        NSLayoutConstraint.activate([
            instagramStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            instagramStackView.heightAnchor.constraint(equalToConstant: 20),
        ])
        return stackView
    }()
    
    private lazy var twitterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.isUserInteractionEnabled = true
        stackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(twitterIdTapped)))
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "twitter")
        
        let leftSpacer = UIView()
        leftSpacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(leftSpacer)
        NSLayoutConstraint.activate([
            leftSpacer.heightAnchor.constraint(equalToConstant: 20),
            leftSpacer.widthAnchor.constraint(equalToConstant: 16),
        ])
        
        stackView.addArrangedSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        stackView.addArrangedSubview(twitterIdLabel)
        NSLayoutConstraint.activate([
            twitterIdLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        return stackView
    }()
    private lazy var twitterIdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .left
        return label
    }()
    
    private lazy var instagramStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.isUserInteractionEnabled = true
        stackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(instagramIdTapped)))
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "insta")
        imageView.clipsToBounds = true
        
        let leftSpacer = UIView()
        leftSpacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(leftSpacer)
        NSLayoutConstraint.activate([
            leftSpacer.heightAnchor.constraint(equalToConstant: 20),
            leftSpacer.widthAnchor.constraint(equalToConstant: 16),
        ])
        
        stackView.addArrangedSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        stackView.addArrangedSubview(instagramIdLabel)
        NSLayoutConstraint.activate([
            instagramIdLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        return stackView
    }()
    private lazy var instagramIdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .left
        return label
    }()
    
    private let postSectionHeader = SummarySectionHeader(title: "ライブレポート")
    private lazy var postCellContent: PostCellContent = {
        let content = UINib(nibName: "PostCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! PostCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    private lazy var postCellWrapper: UIView = Self.addPadding(to: self.postCellContent)
    
    private let groupSectionHeader = SummarySectionHeader(title: "お気に入りアーティスト")
    private lazy var groupCellContent: GroupCellContent = {
        let content = UINib(nibName: "GroupCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! GroupCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 300),
        ])
        return content
    }()
    private lazy var groupCellWrapper: UIView = Self.addPadding(to: self.groupCellContent)
    
    private let liveSectionHeader = SummarySectionHeader(title: "行きたいライブ")
    private lazy var liveCellContent: LiveCellContent = {
        let content = UINib(nibName: "LiveCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! LiveCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 350),
        ])
        return content
    }()
    private lazy var liveCellWrapper: UIView = Self.addPadding(to: self.liveCellContent)
    
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
    
    deinit {
        print("UserDetailVC.deinit")
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
            headerView.heightAnchor.constraint(equalToConstant: 160),
            headerView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        scrollStackView.addArrangedSubview(biographyTextView)
        NSLayoutConstraint.activate([
            biographyTextView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        scrollStackView.addArrangedSubview(snsStackView)
        NSLayoutConstraint.activate([
            snsStackView.widthAnchor.constraint(equalTo: scrollStackView.widthAnchor),
        ])
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(tagListView)
        NSLayoutConstraint.activate([
            tagListView.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -16),
            tagListView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 16),
            tagListView.topAnchor.constraint(equalTo: containerView.topAnchor),
            tagListView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        scrollStackView.addArrangedSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        userActionStackView.addArrangedSubview(editProfileButton)
        userActionStackView.addArrangedSubview(followButton)
        userActionStackView.addArrangedSubview(sendMessageButton)
        NSLayoutConstraint.activate([
            editProfileButton.heightAnchor.constraint(equalToConstant: 48),
            followButton.heightAnchor.constraint(equalToConstant: 48),
            sendMessageButton.heightAnchor.constraint(equalToConstant: 48),
        ])
        
        scrollStackView.addArrangedSubview(userActionStackView)
        
        let headerSpacer = UIView()
        scrollStackView.addArrangedSubview(headerSpacer) // Spacer
        NSLayoutConstraint.activate([
            headerSpacer.heightAnchor.constraint(equalToConstant: 8),
        ])
        
        scrollStackView.addArrangedSubview(postSectionHeader)
        NSLayoutConstraint.activate([
            postSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        postCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(postCellWrapper)
        
        scrollStackView.addArrangedSubview(liveSectionHeader)
        NSLayoutConstraint.activate([
            liveSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        liveCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(liveCellWrapper)
        
        scrollStackView.addArrangedSubview(groupSectionHeader)
        NSLayoutConstraint.activate([
            groupSectionHeader.heightAnchor.constraint(equalToConstant: 64),
        ])
        groupCellWrapper.isHidden = true
        scrollStackView.addArrangedSubview(groupCellWrapper)
        
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
            case .updateIsButtonEnabled(let enabled):
                followButton.isEnabled = enabled
            case .updateFollowing:
                viewModel.refresh()
            case .reportError(let error):
                print(error)
                self.showAlert()
            }
        }
        .store(in: &cancellables)

        followButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: { [unowned self] in
                guard let isFollowing = viewModel.state.userDetail?.isFollowing else { return }
                userFollowingViewModel.didButtonTapped(isFollowing: isFollowing)
            })
            .store(in: &cancellables)

        sendMessageButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: { [unowned self] in
                self.didSendMessageButtonTapped()
            })
            .store(in: &cancellables)

        editProfileButton.controlEventPublisher(for: .touchUpInside)
            .sink(receiveValue: { [unowned self] in
                self.didEditProfileButtonTapped()
            })
            .store(in: &cancellables)

        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didRefreshUserDetail(let userDetail):
                switch viewModel.state.displayType {
                case .account:
                    dependencyProvider.user = userDetail.user
                    self.title = "マイページ"
                    editProfileButton.isHidden = false
                    followButton.isHidden = true
                    sendMessageButton.isHidden = true
                    let item = UIBarButtonItem(title: "ログアウト", style: .plain, target: self, action: #selector(logoutButtonTapped(_:)))
                    navigationItem.setRightBarButton(
                        item,
                        animated: false
                    )
                case .user:
                    self.title = userDetail.name
                    biographyTextView.text = userDetail.biography
                    editProfileButton.isHidden = true
                    followButton.isHidden = false
                    sendMessageButton.isHidden = true
                    headerView.update(input: (user: viewModel.state.user, followersCount: userDetail.followersCount, followingUsersCount: userDetail.followingUsersCount, likePostCount: userDetail.likePostCount, imagePipeline: dependencyProvider.imagePipeline))
                    if userDetail.isFollowing {
                        userDetail.isFollowed
                            ? followButton.setTitle("相互フォロー中", selected: true)
                            : followButton.setTitle("フォロー中", selected: true)
                    } else {
                        userDetail.isFollowed
                            ? followButton.setTitle("フォローバック", selected: false)
                            : followButton.setTitle("フォロー", selected: false)
                    }
                    followButton.isSelected = userDetail.isFollowing
                }
                userFollowingViewModel.didGetUserDetail()
                if let twitterUrl = userDetail.twitterUrl, let twitterId = twitterUrl.absoluteString.split(separator: "/").last {
                    twitterStackView.isHidden = false
                    twitterIdLabel.text = "@" + twitterId
                } else {
                    twitterStackView.isHidden = true
                }
                if let instagramUrl = userDetail.instagramUrl, let instagramId = instagramUrl.absoluteString.split(separator: "/").last {
                    instagramStackView.isHidden = false
                    instagramIdLabel.text = "@" + instagramId
                } else {
                    instagramStackView.isHidden = true
                }
                biographyTextView.text = userDetail.biography
                refreshControl.endRefreshing()
            case .pushToGroupDetail(let group):
                let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPlayTrack(let input):
                let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPostAuthor(let user):
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: user)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToMessageRoom(let room):
                let vc = MessageRoomViewController(dependencyProvider: dependencyProvider, input: room)
                self.navigationController?.pushViewController(vc, animated: true)
            case .didRefreshPostSummary(let post):
                let isHidden = post == nil
                self.postSectionHeader.isHidden = isHidden
                self.postCellWrapper.isHidden = isHidden
                if let post = post {
                    self.postCellContent.inject(input: (
                        post: post, user: dependencyProvider.user, imagePipeline: dependencyProvider.imagePipeline
                    ))
                }
            case .didRefreshFollowingGroup(let group, let groupNameSummary):
                let isHidden = group == nil
                self.groupSectionHeader.isHidden = isHidden
                self.groupCellWrapper.isHidden = isHidden
                if let group = group {
                    self.groupCellContent.inject(input: (
                        group: group,
                        imagePipeline: dependencyProvider.imagePipeline
                    ))
                }

                tagListView.removeAllTags()
                tagListView.addTags(groupNameSummary)
            case .didRefreshLikedLive(let liveFeed):
                let isHidden = liveFeed == nil
                self.liveSectionHeader.isHidden = isHidden
                self.liveCellWrapper.isHidden = isHidden
                if let liveFeed = liveFeed {
                    self.liveCellContent.inject(input: (
                        live: liveFeed,
                        imagePipeline: dependencyProvider.imagePipeline,
                        type: .normal
                    ))
                }
            case .didDeletePostButtonTapped(let post):
                let alertController = UIAlertController(
                    title: "投稿を削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

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
            case .didDeletePost:
                viewModel.refresh()
            case .didToggleLikePost:
                viewModel.refresh()
            case .pushToFeedList(let input):
                let vc = FeedListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPostList(let input):
                let vc = PostListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToUserList(let input):
                let vc = UserListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToGroupList(let input):
                let vc = GroupListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToLiveList(let input):
                let vc = LiveListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToCommentList(let input):
                let vc = CommentListViewController(
                    dependencyProvider: dependencyProvider, input: input)
                let nav = BrandNavigationController(rootViewController: vc)
                self.present(nav, animated: true, completion: nil)
            case .pushToPost(let input):
                let vc = PostViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .openURLInBrowser(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
            case .didTwitterButtonTapped(let post):
                shareWithTwitter(type: .post(post.post))
            case .didInstagramButtonTapped(let post):
                self.instagramButtonTapped(post: post.post)
            case .didToggleLikeLive:
                viewModel.refresh()
            case .reportError(let error):
                print(error)
                self.showAlert()
            case .openImage(let content):
                let galleryController = GalleryViewController(startIndex: 0, itemsDataSource: content.self, configuration: [.deleteButtonMode(.none), .seeAllCloseButtonMode(.none), .thumbnailsButtonMode(.none)])
                self.present(galleryController, animated: true, completion: nil)
            case .pushToTrackList(let input):
                let vc = TrackListViewController(dependencyProvider: dependencyProvider, input: input)
                navigationController?.pushViewController(vc, animated: true)
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

        postCellContent.listen { [viewModel] output in
            viewModel.postCellEvent(event: output)
        }

        groupSectionHeader.listen { [unowned self] in
            viewModel.didTapSeeMore(at: .group)
        }

        groupCellContent.listen { [unowned self] output in
            viewModel.groupCellEvent(event: output)
        }

        postSectionHeader.listen { [unowned self] in
            self.viewModel.didTapSeeMore(at: .post)
        }

        postCellContent.addTarget(self, action: #selector(postCellTaped), for: .touchUpInside)

        groupCellContent.addTarget(self, action: #selector(groupCellTaped), for: .touchUpInside)

        liveSectionHeader.listen { [unowned self] in
            viewModel.didTapSeeMore(at: .live)
        }

        liveCellContent.listen { [unowned self] output in
            viewModel.liveCellEvent(event: output)
        }

    }
    
    func setupViews() {
        headerView.update(input: (user: viewModel.state.user, followersCount: 0, followingUsersCount: 0, likePostCount: 0, imagePipeline: dependencyProvider.imagePipeline))
    }
    
    func didEditProfileButtonTapped() {
        let vc = EditUserViewController(dependencyProvider: dependencyProvider, input: ())
        vc.listen { [unowned self] in
            self.listener()
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func didSendMessageButtonTapped() {
        viewModel.createMessageRoom(partner: viewModel.state.user)
    }
    
    private func downloadButtonTapped(feed: UserFeedSummary) {
        if let thumbnail = feed.ogpUrl {
            let image = UIImage(url: thumbnail)
            downloadImage(image: image)
        }
    }
    
    private func instagramButtonTapped(post: Post) {
        sharePostWithInstagram(post: post)
    }
    
    @objc private func twitterIdTapped() {
        guard let url = viewModel.state.userDetail?.twitterUrl else { return }
        let safari = SFSafariViewController(
            url: url)
        safari.dismissButtonStyle = .close
        present(safari, animated: true, completion: nil)
    }
    
    @objc private func instagramIdTapped() {
        guard let url = viewModel.state.userDetail?.instagramUrl else { return }
        let safari = SFSafariViewController(
            url: url)
        safari.dismissButtonStyle = .close
        present(safari, animated: true, completion: nil)
    }
    
    @objc private func postCellTaped() { viewModel.didSelectRow(at: .post) }
    
    @objc private func groupCellTaped() { viewModel.didSelectRow(at: .group) }
    
    @objc private func logoutButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "ログアウトしますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let acceptAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.default,
            handler: { [unowned self] action in
                logout()
            })
        let cancelAction = UIAlertAction(
            title: "キャンセル", style: UIAlertAction.Style.cancel,
            handler: { action in })
        alertController.addAction(acceptAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.barButtonItem = sender
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func logout() {
        dependencyProvider.auth.signOut(self) { [unowned self] error in
            if let error = error {
                print(error)
                showAlert()
                return
            }
            self.listener()
        }
    }
    
    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}
