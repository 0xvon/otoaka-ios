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
    
    private lazy var verticalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.refreshControl = self.refreshControl
        return scrollView
    }()
    private lazy var scrollStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    private lazy var postCellWrapper: UIView = Self.addPadding(to: self.postCellContent)
    private lazy var postCellContent: PostCellContent = {
        let content = UINib(nibName: "PostCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! PostCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()
    private let liveSectionHeader = SummarySectionHeader(title: "このレポートのライブ")
    private lazy var liveCellWrapper: UIView = Self.addPadding(to: self.liveCellContent)
    private lazy var liveCellContent: LiveCellContent = {
        let content = UINib(nibName: "LiveCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! LiveCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 350),
        ])
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
    
    private let refreshControl = BrandRefreshControl()

    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: PostDetailViewModel
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = PostDetailViewModel(dependencyProvider: dependencyProvider, input: input)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        viewModel.refresh()
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
        
        let topSpacer = UIView()
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        scrollStackView.addArrangedSubview(topSpacer)
        NSLayoutConstraint.activate([
            topSpacer.widthAnchor.constraint(equalTo: view.widthAnchor),
            topSpacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        scrollStackView.addArrangedSubview(postCellWrapper)
        scrollStackView.addArrangedSubview(liveSectionHeader)
        scrollStackView.addArrangedSubview(liveCellWrapper)
        liveSectionHeader.isHidden = true
        liveCellWrapper.isHidden = true
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        scrollStackView.addArrangedSubview(bottomSpacer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        bind()
    }
    
    private func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didRefreshPost(let post):
                postCellContent.inject(input: (
                    post: post,
                    user: dependencyProvider.user,
                    imagePipeline: dependencyProvider.imagePipeline
                ))
                refreshControl.endRefreshing()
            case .didDeletePost:
                navigationController?.popViewController(animated: true)
            case .didToggleLikePost:
                viewModel.refresh()
            case .error(let err):
                refreshControl.endRefreshing()
                print(err)
                showAlert()
            }
        }
        .store(in: &cancellables)
        
        postCellContent.listen { [unowned self] output in
            switch output {
            case .commentTapped:
                guard let post = viewModel.state.post else { return }
                self.commentButtonTapped(post: post)
            case .deleteTapped:
                guard let post = viewModel.state.post else { return }
                self.deleteButtonTapped(post: post)
            case .likeTapped:
                guard let post = viewModel.state.post else { return }
                self.likeButtonTapped(post: post)
            case .instagramTapped:
                guard let post = viewModel.state.post else { return }
                sharePostWithInstagram(post: post.post)
            case .twitterTapped:
                guard let post = viewModel.state.post else { return }
                self.twitterButtonTapped(post: post)
            case .userTapped:
                guard let post = viewModel.state.post else { return }
                self.userTapped(post: post)
            case .postListTapped:
                guard let post = viewModel.state.post else { return }
                self.livePostListButtonTapped(post: post)
            case .postTapped:
                guard let post = viewModel.state.post else { return }
                self.postTapped(post: post)
            case .playTapped(let track):
                self.playTapped(track: track)
            case .trackTapped(_): break
            case .imageTapped(let content):
                self.uploadImageTapped(content: content)
            case .groupTapped:
                guard let group = viewModel.state.post?.groups.first else { return }
                self.groupTapped(group: group)
            case .seePlaylistTapped:
                guard let post = viewModel.state.post else { return }
                let vc = TrackListViewController(dependencyProvider: dependencyProvider, input: .playlist(post.post))
                navigationController?.pushViewController(vc, animated: true)
            case .cellTapped:
                break
            }
        }
        
        refreshControl.controlEventPublisher(for: .valueChanged)
            .sink { [viewModel] _ in
                viewModel.refresh()
            }
            .store(in: &cancellables)
    }
        
    private func setupViews() {
//        postCellContent.inject(input: (
//            post: viewModel.state.post,
//            user: dependencyProvider.user,
//            imagePipeline: dependencyProvider.imagePipeline
//        ))
    }
    
    private func commentButtonTapped(post: PostSummary) {
        let vc = CommentListViewController(dependencyProvider: dependencyProvider, input: .postComment(post))
        let nav = BrandNavigationController(rootViewController: vc)
        self.present(nav, animated: true, completion: nil)
    }
    
    private func likeButtonTapped(post: PostSummary) {
        post.isLiked ? viewModel.unlikePost(post: post) : viewModel.likePost(post: post)
    }
    
    private func twitterButtonTapped(post: PostSummary) {
        shareWithTwitter(type: .post(post.post))
    }
    
    private func livePostListButtonTapped(post: PostSummary) {
        guard let live = post.post.live else { return }
        let vc = PostListViewController(dependencyProvider: dependencyProvider, input: .livePost(live))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func postTapped(post: PostSummary) {
        guard let live = post.post.live else { return }
        if post.post.author.id == dependencyProvider.user.id {
            let vc = PostViewController(dependencyProvider: dependencyProvider, input: (live: live, post: post.post))
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = PostViewController(dependencyProvider: dependencyProvider, input: (live: live, post: nil))
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    private func userTapped(post: PostSummary) {
        let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: post.author)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func deleteButtonTapped(post: PostSummary) {
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
    }
    
    private func uploadImageTapped(content: GalleryItemsDataSource) {
        let galleryController = GalleryViewController(startIndex: 0, itemsDataSource: content.self, configuration: [.deleteButtonMode(.none), .seeAllCloseButtonMode(.none), .thumbnailsButtonMode(.none)])
        self.present(galleryController, animated: true, completion: nil)
    }
    
    private func trackTapped(track: Track) {
        print("todo")
    }
    
    private func playTapped(track: Track) {
        let vc = PlayTrackViewController(dependencyProvider: dependencyProvider, input: .track(track))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func groupTapped(group: Group) {
        let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: group)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
