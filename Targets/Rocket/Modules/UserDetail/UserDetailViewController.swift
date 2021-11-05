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
import SCLAlertView

final class UserDetailViewController: UIViewController, Instantiable {
    typealias Input = User
    private let refreshControl = BrandRefreshControl()
    
    var dependencyProvider: LoggedInDependencyProvider
    let viewModel: UserDetailViewModel
    let userFollowingViewModel: UserFollowingViewModel
    let openMessageRoomViewModel: OpenMessageRoomViewModel
    var cancellables: Set<AnyCancellable> = []
    
    let vc1: UserProfileViewController
    let vc2: UserStatsViewController
    let vc3: CollectionListViewController
    
    private lazy var headerView: UserDetailHeaderView = {
        let headerView = UserDetailHeaderView()
        return headerView
    }()
    private lazy var tab: UserDetailTabView = {
        let tab = UserDetailTabView()
        return tab
    }()
    
    let pageViewController: PageViewController
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = UserDetailViewModel(dependencyProvider: dependencyProvider, user: input)
        self.userFollowingViewModel = UserFollowingViewModel(dependencyProvider: dependencyProvider, user: input)
        self.openMessageRoomViewModel = OpenMessageRoomViewModel(dependencyProvider: dependencyProvider)
        self.pageViewController = PageViewController()
        
        vc1 = UserProfileViewController(dependencyProvider: dependencyProvider, input: viewModel.state.user)
        vc2 = UserStatsViewController(dependencyProvider: dependencyProvider, input: viewModel.state.user)
        vc3 = CollectionListViewController(dependencyProvider: dependencyProvider, input: .userPost(viewModel.state.user))
                
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        bind()
    }
    
    func bind() {
        userFollowingViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateFollowing:
                viewModel.refresh()
            case .reportError(let error):
                print(error)
                self.showAlert()
            }
        }
        .store(in: &cancellables)

        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didRefreshUserDetail(let userDetail):
                headerView.update(input: (selfUser: dependencyProvider.user, userDetail: userDetail, imagePipeline: dependencyProvider.imagePipeline))
                tab.update(userDetail: userDetail)
                switch viewModel.state.displayType {
                case .account:
                    dependencyProvider.user = userDetail.user
                    self.title = "マイページ"
                    let settingItem = UIBarButtonItem(
                        image: UIImage(systemName: "ellipsis")!.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal),
                        style: .plain,
                        target: self,
                        action: #selector(settingButtonTapped(_:))
                    )
                    let linkItem = UIBarButtonItem(
                        image: UIImage(systemName: "link")!.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(linkButtonTapped(_:))
                    )
                    
                    navigationItem.setRightBarButtonItems(
                        [settingItem, linkItem],
                        animated: false
                    )
                case .user:
                    self.title = userDetail.name
                    navigationItem.setRightBarButton(nil, animated: true)
                }
                refreshControl.endRefreshing()
            case .sendMessageButonTapped:
                openMessageRoomViewModel.createMessageRoom(partner: viewModel.state.user)
            case .pushToMessageRoom(let room):
                let vc = MessageRoomViewController(dependencyProvider: dependencyProvider, input: room)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToUserList(let input):
                let vc = UserListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPostList(let input):
                let vc = PostListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .openURLInBrowser(let url):
                openUrlInBrowser(url: url)
            case .reportError(let error):
                print(error)
                self.showAlert()
            case .openImage(let content):
                let galleryController = GalleryViewController(startIndex: 0, itemsDataSource: content.self, configuration: [.deleteButtonMode(.none), .seeAllCloseButtonMode(.none), .thumbnailsButtonMode(.none)])
                self.present(galleryController, animated: true, completion: nil)
            case .followButtontapped:
                guard let userDetail = viewModel.state.userDetail else { return }
                userFollowingViewModel.didButtonTapped(isFollowing: userDetail.isFollowing)
            case .editProfileButtonTapped:
                let vc = EditUserViewController(dependencyProvider: dependencyProvider, input: ())
                vc.listen { [unowned self] in
                    self.listener()
                }
                self.navigationController?.pushViewController(vc, animated: true)
            case .didUsernameRegistered:
                showSuccess()
            case .usernameAlreadyExists(_):
                showUsernameAlert()
            }
        }
        .store(in: &cancellables)
        
        openMessageRoomViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
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

        headerView.listen { [viewModel] output in
            viewModel.headerEvent(output: output)
        }

        refreshControl.controlEventPublisher(for: .valueChanged)
            .sink { [viewModel] _ in
                viewModel.refresh()
            }
            .store(in: &cancellables)
    }
    
    func setupViews() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        navigationItem.largeTitleDisplayMode = .never
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.layoutMarginsGuide.topAnchor.constraint(equalTo:    pageViewController.view.topAnchor),
            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: pageViewController.view.bottomAnchor),
            view.leftAnchor.constraint(equalTo:   pageViewController.view.leftAnchor),
            view.rightAnchor.constraint(equalTo:  pageViewController.view.rightAnchor),
        ])
        pageViewController.didMove(toParent: self)
        
        pageViewController.embed((
            header: headerView,
            tab: tab,
            children: [vc1, vc2, vc3]
        ))
    }
    
    func didEditProfileButtonTapped() {
        let vc = EditUserViewController(dependencyProvider: dependencyProvider, input: ())
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func didSendMessageButtonTapped() {
        viewModel.createMessageRoom(partner: viewModel.state.user)
    }
    
    @objc private func linkButtonTapped(_ sender: UIBarButtonItem) {
        showUsernameAlert()
    }
    
    func showSuccess() {
        guard let username = viewModel.state.username else { return }
        let alertView = SCLAlertView()
        let link = "https://rocketfor.band/\(username)"
        alertView.addButton("リンクをコピー", action: {
            UIPasteboard.general.string = link
        })
        alertView.showSuccess("リンク生成完了", subTitle: "\(link)にアクセスするとweb上であなたのプロフィールを確認することができます！みんなに共有してみましょう！")
    }
    
    func showUsernameAlert() {
        let alertView = SCLAlertView()
        alertView.customSubview?.backgroundColor = .black
        let textField = alertView.addTextField()
        textField.backgroundColor = .white
        textField.textColor = .black
        
        alertView.addButton("OK", action: { [unowned self] in
            if let username = textField.text?.lowercased(), username.isValidUsername() {
                viewModel.registerUsername(username: username)
            } else {
                showUsernameAlert()
            }
        })
        
        alertView.showEdit(
            "ユーザーネーム設定",
            subTitle: "プロフィールリンクを共有するためにユーザーネームを12文字以内で設定してください。\n文字は半角英数字と._のみ使えます。入力ミスがあったりユーザーネームが既に使用されている場合もう一度やり直しになります。\n以前設定したユーザーネームは使えなくなります。",
            closeButtonTitle: "キャンセル",
            timeout: .none,
            colorStyle: 0xE4472A
        )
    }
    
    @objc private func settingButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "設定", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        var actions: [UIAlertAction] = []
        switch viewModel.state.displayType {
        case .account:
            let shareProfileAction = UIAlertAction(title: "ライブ参戦数をインスタでシェア", style: .default, handler: { [unowned self] _ in
                shareUserWithInstagram(user: viewModel.state.user, views: [vc2.scrollStackView])
            })
            let requestLiveAction = UIAlertAction(title: "ライブ掲載申請", style: .default, handler: { [unowned self] _ in
                if let url = URL(string: "https://forms.gle/epoBeqdaGeMUcv8o9") {
                    openUrlInBrowser(url: url)
                }
            })
            let logoutAction = UIAlertAction(title: "ログアウト", style: .default, handler: { [unowned self] _ in
                    logout()
            })
            let cancelAction = UIAlertAction(
                title: "キャンセル", style: UIAlertAction.Style.cancel,
                handler: { _ in })
            actions = [shareProfileAction, requestLiveAction, logoutAction, cancelAction]
        case .user:
            let blockAction = UIAlertAction(title: "ブロック", style: UIAlertAction.Style.default, handler: { [unowned self] _ in
                    block()
            })
            let cancelAction = UIAlertAction(
                title: "キャンセル", style: UIAlertAction.Style.cancel,
                handler: { _ in })
            actions = [blockAction, cancelAction]
        }
        actions.forEach { alertController.addAction($0) }
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.barButtonItem = sender
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func openUrlInBrowser(url: URL) {
        let safari = SFSafariViewController(url: url)
        safari.dismissButtonStyle = .close
        present(safari, animated: true, completion: nil)
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
    private func block() {
        
    }
    
    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}

extension String {
    func isValidUsername() -> Bool {
        let pattern = "^[a-zA-Z0-9_\\-.]{1,12}$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let checkingResults = regex.matches(in: self, range: NSRange(location: 0, length: self.count))
        return checkingResults.count > 0
    }
}
