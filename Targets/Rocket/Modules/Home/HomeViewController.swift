//
//  HomeViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/23.
//

import UIKit
import Combine
import Endpoint
import ImageViewer

final class HomeViewController: UITableViewController {
    let dependencyProvider: LoggedInDependencyProvider
    
    let viewModel: HomeViewModel
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = HomeViewModel(dependencyProvider: dependencyProvider)
        
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "レポート"
        view.backgroundColor = Brand.color(for: .background(.primary))
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = Brand.color(for: .background(.primary))
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Brand.color(for: .background(.secondary))
        tableView.separatorInset = .zero
        tableView.registerCellClass(PostCell.self)
        refreshControl = BrandRefreshControl()
        
        bind()
        requestNotification()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: true)
        setupFloatingItems(userRole: dependencyProvider.user.role)
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadData:
                self.tableView.reloadData()
                self.setTableViewBackgroundView(isDisplay: viewModel.state.posts.isEmpty)
            case .didDeletePost:
                viewModel.refresh()
            case .didToggleLikePost:
                viewModel.refresh()
            case .reportError(let err):
                print(err)
                showAlert()
            case .isRefreshing(let isRefreshing):
                isRefreshing
                    ? refreshControl?.beginRefreshing()
                    : refreshControl?.endRefreshing()
            }
        }.store(in: &cancellables)
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @objc private func refresh() {
        viewModel.refresh()
    }
    
    private func requestNotification() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [
            .alert, .sound, .badge,
        ]) {
            granted, error in
            if let error = error {
                DispatchQueue.main.async {
                    print(error)
                    self.showAlert()
                }
                return
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func setupFloatingItems(userRole: RoleProperties) {
        let items: [FloatingButtonItem]
        let createFeedView = FloatingButtonItem(icon: UIImage(named: "post")!)
        createFeedView.addTarget(self, action: #selector(createPostButtonTapped), for: .touchUpInside)
        items = [createFeedView]
        let floatingController = dependencyProvider.viewHierarchy.floatingViewController
        floatingController.setFloatingButtonItems(items)
    }
    
    @objc private func createPostButtonTapped() {
        let vc = SelectLiveViewController(dependencyProvider: dependencyProvider)
        navigationController?.pushViewController(vc, animated: true)
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
    
    private func postTapped(post: PostSummary) {
        guard let live = post.post.live else { return }
        let vc = PostViewController(dependencyProvider: dependencyProvider, input: live)
        self.navigationController?.pushViewController(vc, animated: true)
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

extension HomeViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            case .postListTapped:
                self.livePostListButtonTapped(post: post)
            case .postTapped:
                self.postTapped(post: post)
            case .twitterTapped:
                self.twitterButtonTapped(post: post)
            case .userTapped:
                self.userTapped(post: post)
            case .playTapped(let track):
                self.playTapped(track: track)
            case .trackTapped(_): break
            case .imageTapped(let content):
                self.uploadImageTapped(content: content)
            case .groupTapped:
                guard let group = post.groups.first else { return }
                self.groupTapped(group: group)
            case .seePlaylistTapped:
                let vc = TrackListViewController(dependencyProvider: dependencyProvider, input: .playlist(post.post))
                navigationController?.pushViewController(vc, animated: true)
            case .cellTapped:
                break
            }
            
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 572
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("yo")
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .post, actionButtonTitle: "投稿してみる")
            emptyCollectionView.listen { [unowned self] in
                let vc = SelectLiveViewController(dependencyProvider: dependencyProvider)
                navigationController?.pushViewController(vc, animated: true)
            }
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
            
        }()
        tableView.backgroundView = isDisplay ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 32),
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor, constant: -32),
                backgroundView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            ])
        }
    }
}

extension HomeViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}


