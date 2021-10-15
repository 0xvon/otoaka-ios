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
import UIComponent

final class PostListViewController: UIViewController, Instantiable {
    typealias Input = PostListViewModel.Input
    
    var dependencyProvider: LoggedInDependencyProvider
    private var postTableView: UITableView!
    let viewModel: PostListViewModel
    let postActionViewModel: PostActionViewModel
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = PostListViewModel(dependencyProvider: dependencyProvider, input: input)
        self.postActionViewModel = PostActionViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
        
        switch input {
        case .followingPost:
            self.title = "タイムライン"
        case .trendPost:
            self.title = "トレンド"
        case .groupPost(_):
            self.title = "このアーティストのレポート"
        case .likedPost(_):
            self.title = "いいねしたレポート"
        case .livePost(_):
            self.title = "このライブのレポート"
        case .userPost(_):
            self.title = "このユーザーのレポート"
        case .none: break
        }
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
                let cancelAction = UIAlertAction(
                    title: "キャンセル", style: UIAlertAction.Style.cancel,
                    handler: { action in })
                alertController.addAction(shareTwitterAction)
                alertController.addAction(shareInstagramAction)
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
        switch input {
        case .followingPost:
            self.title = "タイムライン"
        case .trendPost:
            self.title = "トレンド"
        case .groupPost(_):
            self.title = "このアーティストのレポート"
        case .likedPost(_):
            self.title = "いいねしたレポート"
        case .livePost(_):
            self.title = "このライブのレポート"
        case .userPost(_):
            self.title = "このユーザーのレポート"
        case .none: break
        }
    }
    
    func setup() {
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        postTableView = UITableView()
        postTableView.translatesAutoresizingMaskIntoConstraints = false
        postTableView.showsVerticalScrollIndicator = false
        postTableView.tableFooterView = UIView(frame: .zero)
        postTableView.separatorStyle = .singleLine
        postTableView.separatorColor = Brand.color(for: .background(.secondary))
        postTableView.separatorInset = .zero
        postTableView.backgroundColor = .clear
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
            postTableView.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    deinit {
        print("PostListVC.deinit")
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        viewModel.refresh()
        sender.endRefreshing()
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
            postActionViewModel.postCellEvent(post, event: output)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(isDisplay: Bool = true) {
        let emptyCollectionView: EmptyCollectionView = {
            switch viewModel.dataSource {
            case .followingPost:
                let emptyCollectionView = EmptyCollectionView(emptyType: .post, actionButtonTitle: "ライブを探してレポートを書く")
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                emptyCollectionView.listen { [unowned self] in
                    let vc = tabBarController?.viewControllers?[1]
                    tabBarController?.selectedViewController = vc
                }
                return emptyCollectionView
            case .livePost(let live):
                let emptyCollectionView = EmptyCollectionView(emptyType: .livePost, actionButtonTitle: "レポートを書く")
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                emptyCollectionView.listen { [unowned self] in
                    let vc = PostViewController(dependencyProvider: dependencyProvider, input: (live: live, post: nil))
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                return emptyCollectionView
            default:
                let emptyCollectionView = EmptyCollectionView(emptyType: .post, actionButtonTitle: nil)
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                return emptyCollectionView
            }
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

extension PostListViewController: PageContent {
    var scrollView: UIScrollView {
        _ = view
        return self.postTableView
    }
}
