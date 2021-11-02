//
//  PostDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/22.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import InternalDomain
import ImageViewer

final class PostDetailViewController: UIViewController, Instantiable {
    typealias Input = Post
    
    let postDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private lazy var liveView: LiveBannerCellContent = {
        let content = LiveBannerCellContent()
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    private lazy var scrollStackView: UIStackView = {
        let postView = UIStackView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        postView.backgroundColor = Brand.color(for: .background(.primary))
        postView.axis = .vertical
        postView.spacing = 16
        
        postView.addArrangedSubview(liveView)
        NSLayoutConstraint.activate([
            liveView.widthAnchor.constraint(equalTo: postView.widthAnchor),
            liveView.heightAnchor.constraint(equalToConstant: 100),
        ])
        
        postView.addArrangedSubview(textContainerView)
        NSLayoutConstraint.activate([
            textContainerView.widthAnchor.constraint(equalTo: postView.widthAnchor)
        ])
        
        postView.addArrangedSubview(imageGalleryView)
        NSLayoutConstraint.activate([
            imageGalleryView.widthAnchor.constraint(equalTo: postView.widthAnchor),
            imageGalleryView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
        ])
        
        postView.addArrangedSubview(sectionView)
        NSLayoutConstraint.activate([
            sectionView.widthAnchor.constraint(equalTo: postView.widthAnchor),
            sectionView.heightAnchor.constraint(equalToConstant: 32),
        ])
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        postView.addArrangedSubview(bottomSpacer)
        NSLayoutConstraint.activate([
            bottomSpacer.widthAnchor.constraint(equalTo: postView.widthAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        return postView
    }()
    private lazy var textContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.topAnchor),
            avatarImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
        ])
        
        view.addSubview(usernameLabel)
        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            usernameLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 4),
        ])
        
        view.addSubview(settingButton)
        NSLayoutConstraint.activate([
            settingButton.widthAnchor.constraint(equalToConstant: 24),
            settingButton.heightAnchor.constraint(equalTo: settingButton.widthAnchor),
            settingButton.topAnchor.constraint(equalTo: usernameLabel.topAnchor),
            settingButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            settingButton.leftAnchor.constraint(equalTo: usernameLabel.rightAnchor, constant: 4),
        ])
        
        view.addSubview(trackNameLabel)
        NSLayoutConstraint.activate([
            trackNameLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor),
            trackNameLabel.leftAnchor.constraint(equalTo: usernameLabel.leftAnchor),
            trackNameLabel.rightAnchor.constraint(equalTo: usernameLabel.rightAnchor),
        ])
        
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            textView.rightAnchor.constraint(equalTo: settingButton.rightAnchor),
            textView.leftAnchor.constraint(equalTo: avatarImageView.leftAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualTo: avatarImageView.heightAnchor, multiplier: 1.6),
        ])
        
        return view
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = ""
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.font = Brand.font(for: .mediumStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .left
        
        textView.returnKeyType = .done
        return textView
    }()
    private lazy var imageGalleryView: ImageGalleryCollectionView = {
        let view = ImageGalleryCollectionView(images: .none, imagePipeline: dependencyProvider.imagePipeline)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var avatarImageView: UIImageView = {
        let avatarImageView = UIImageView()
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        return avatarImageView
    }()
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var settingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(
            UIImage(systemName: "ellipsis")!
                .withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal),
            for: .normal
        )
        button.addTarget(self, action: #selector(settingTapped), for: .touchUpInside)
        return button
    }()
    private lazy var trackNameLabel: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = Brand.font(for: .xsmall)
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(trackTapped), for: .touchUpInside)
        return button
    }()
    private lazy var sectionView: UIStackView = {
        let sectionView = UIStackView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.distribution = .fill
        sectionView.axis = .horizontal
        
        sectionView.addArrangedSubview(commentButtonView)
        NSLayoutConstraint.activate([
            commentButtonView.widthAnchor.constraint(equalToConstant: 60),
        ])
        
        sectionView.addArrangedSubview(likeButtonView)
        NSLayoutConstraint.activate([
            likeButtonView.widthAnchor.constraint(equalToConstant: 60),
        ])
        
        sectionView.addArrangedSubview(dateLabel)
        
        let rightSpacer = UIView()
        rightSpacer.translatesAutoresizingMaskIntoConstraints = false
        sectionView.addArrangedSubview(rightSpacer)
        NSLayoutConstraint.activate([
            rightSpacer.widthAnchor.constraint(equalToConstant: 16),
        ])
        
        return sectionView
    }()
    private lazy var commentButtonView: ReactionIndicatorButton = {
        let commentButton = ReactionIndicatorButton()
        commentButton.translatesAutoresizingMaskIntoConstraints = false
        commentButton.setImage(
            UIImage(systemName: "message")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        commentButton.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        return commentButton
    }()
    private lazy var likeButtonView: ReactionIndicatorButton = {
        let likeButton = ReactionIndicatorButton()
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.setImage(
            UIImage(systemName: "heart")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal)
        likeButton.setImage(
            UIImage(systemName: "heart.fill")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .selected)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return likeButton
    }()
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .xsmall)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    
    private let refreshControl = BrandRefreshControl()

    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: PostDetailViewModel
    let postActionViewModel: PostActionViewModel
    let openMessageViewModel: OpenMessageRoomViewModel
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = PostDetailViewModel(dependencyProvider: dependencyProvider, input: input)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        
        viewModel.refresh()
    }
    
    private func bind() {
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
                showAlert()
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
                showAlert()
            }
        }
        .store(in: &cancellables)
        
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didRefreshPost(let post):
                refreshControl.endRefreshing()
                textView.text = post.text
                trackNameLabel.setTitle(post.tracks.first?.trackName, for: .normal)
                usernameLabel.text = post.author.name
                if let thumbnail = post.author.thumbnailURL, let url = URL(string: thumbnail) {
                    dependencyProvider.imagePipeline.loadImage(url, into: avatarImageView)
                }
                liveView.inject(input: (live: post.live!, imagePipeline: dependencyProvider.imagePipeline))
                imageGalleryView.inject(images: .url(post.imageUrls.compactMap { URL(string: $0) }))
                imageGalleryView.isHidden = post.imageUrls.isEmpty
                
                commentButtonView.setTitle("DM", for: .normal)
                commentButtonView.isEnabled = true
                likeButtonView.setTitle("\(post.likeCount)", for: .normal)
                likeButtonView.isSelected = post.isLiked
                likeButtonView.isEnabled = true
                dateLabel.text = postDateFormatter.string(from: post.createdAt)
            case .error(let err):
                refreshControl.endRefreshing()
                print(String(describing: err))
                showAlert()
            }
        }
        .store(in: &cancellables)
        
        refreshControl.controlEventPublisher(for: .valueChanged)
            .sink { [viewModel] _ in
                viewModel.refresh()
            }
            .store(in: &cancellables)
        
        liveView.addTarget(self, action: #selector(liveTapped), for: .touchUpInside)
    }
    
    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
        ])
        
        scrollView.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            scrollStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            scrollStackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            scrollStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])
    }
        
    @objc private func trackTapped() {
        guard let post = viewModel.state.post else { return }
        postActionViewModel.postCellEvent(post, event: .trackTapped)
    }
    
    @objc private func settingTapped() {
        guard let post = viewModel.state.post else { return }
        postActionViewModel.postCellEvent(post, event: .settingTapped)
    }
    
    @objc private func likeButtonTapped() {
        likeButtonView.isEnabled = false
        guard let post = viewModel.state.post else { return }
        postActionViewModel.postCellEvent(post, event: .likeTapped)
    }
    
    @objc private func commentButtonTapped() {
        guard let post = viewModel.state.post else { return }
        postActionViewModel.postCellEvent(post, event: .commentTapped)
    }
    
    @objc private func liveTapped() {
        guard let post = viewModel.state.post else { return }
        postActionViewModel.postCellEvent(post, event: .liveTapped)
    }
    
    @objc private func userTapped() {
        guard let post = viewModel.state.post else { return }
        postActionViewModel.postCellEvent(post, event: .userTapped)
    }
}
