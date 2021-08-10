//
//  PostListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/24.
//

import UIKit
import Endpoint
import Combine
import ImageViewer

final class PostListViewController: UIViewController, Instantiable {
    typealias Input = PostListViewModel.Input
    
    var dependencyProvider: LoggedInDependencyProvider
    private var postTableView: UITableView!
    let viewModel: PostListViewModel
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = PostListViewModel(dependencyProvider: dependencyProvider, input: input)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadData:
                postTableView.reloadData()
                setTableViewBackgroundView(isDisplay: viewModel.state.posts.isEmpty)
            case .didDeletePost:
                viewModel.refresh()
            case .didToggleLikePost:
                viewModel.refresh()
            case .error(let err):
                print(err)
                showAlert()
            }
        }
        .store(in: &cancellables)
    }
    
    func inject(_ input: Input) {
        viewModel.inject(input)
    }
    
    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        postTableView = UITableView()
        postTableView.translatesAutoresizingMaskIntoConstraints = false
        postTableView.showsVerticalScrollIndicator = false
        postTableView.tableFooterView = UIView(frame: .zero)
        postTableView.separatorStyle = .singleLine
        postTableView.separatorColor = Brand.color(for: .background(.secondary))
        postTableView.separatorInset = .zero
        postTableView.backgroundColor = Brand.color(for: .background(.primary))
        postTableView.delegate = self
        postTableView.dataSource = self
        postTableView.registerCellClass(PostCell.self)
        self.view.addSubview(postTableView)
        
        postTableView.refreshControl = BrandRefreshControl()
        postTableView.refreshControl?.addTarget(
            self, action: #selector(refresh(sender:)), for: .valueChanged)
        
        let constraints: [NSLayoutConstraint] = [
            postTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            postTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            postTableView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            postTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        viewModel.refresh()
        sender.endRefreshing()
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
        
    }
    
    private func instagramButtonTapped(post: PostSummary) {
        
    }
    
    private func livePostListButtonTapped(post: PostSummary) {
        guard let live = post.post.live else { return }
        let vc = PostListViewController(dependencyProvider: dependencyProvider, input: .livePost(live))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func userTapped(post: PostSummary) {
        let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: post.author)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func deleteButtonTapped(post: PostSummary) {
        let alertController = UIAlertController(
            title: "フィードを削除しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

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

extension PostListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.posts.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = viewModel.state.posts[indexPath.row]
        let cell = tableView.dequeueReusableCell(PostCell.self, input: (post: post, user: dependencyProvider.user, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .commentTapped:
                self.commentButtonTapped(post: post)
            case .deleteTapped:
                self.deleteButtonTapped(post: post)
            case .likeTapped:
                self.likeButtonTapped(post: post)
            case .instagramTapped:
                self.instagramButtonTapped(post: post)
            case .twitterTapped:
                self.twitterButtonTapped(post: post)
            case .userTapped:
                self.userTapped(post: post)
            case .postListTapped:
                self.livePostListButtonTapped(post: post)
            case .playTapped(let track):
                self.playTapped(track: track)
            case .trackTapped(_): break
            case .imageTapped(let content):
                self.uploadImageTapped(content: content)
            case .groupTapped:
                guard let group = post.groups.first else { return }
                self.groupTapped(group: group)
            case .cellTapped:
                break
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .postList, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
            
        }()
        postTableView.backgroundView = isDisplay ? emptyCollectionView : nil
        if let backgroundView = postTableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: postTableView.topAnchor, constant: 32),
                backgroundView.widthAnchor.constraint(equalTo: postTableView.widthAnchor, constant: -32),
                backgroundView.centerXAnchor.constraint(equalTo: postTableView.centerXAnchor),
            ])
        }
    }
}
