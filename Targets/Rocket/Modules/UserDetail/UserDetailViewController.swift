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
import Instructions

final class UserDetailViewController: UIViewController, Instantiable {
    typealias Input = User
    private let refreshControl = BrandRefreshControl()
    
    var dependencyProvider: LoggedInDependencyProvider
    let viewModel: UserDetailViewModel
    let userFollowingViewModel: UserFollowingViewModel
    let openMessageRoomViewModel: OpenMessageRoomViewModel
    let pointViewModel: PointViewModel
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
    private let coachMarksController = CoachMarksController()
    private lazy var coachSteps: [CoachStep] = [
        CoachStep(view: headerView, hint: "ここにユーザー情報が表示されます！試しにプロフィールを作成してみよう！", next: "ok"),
        CoachStep(view: tab, hint: "タブを切り替えると色んな記録を見ることができます", next: "ok"),
        CoachStep(view: vc1.followingSectionHeader, hint: "フォローしたアーティストやライブ参戦はここに記録されます", next: "ok"),
    ]
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = UserDetailViewModel(dependencyProvider: dependencyProvider, user: input)
        self.userFollowingViewModel = UserFollowingViewModel(dependencyProvider: dependencyProvider, user: input)
        self.openMessageRoomViewModel = OpenMessageRoomViewModel(dependencyProvider: dependencyProvider)
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if dependencyProvider.user.id == viewModel.state.user.id {
            #if PRODUCTION
            let userDefaults = UserDefaults.standard
            let key = "UserDetailVCPresented_v3.2.0.r"
            if !userDefaults.bool(forKey: key) {
                coachMarksController.start(in: .currentWindow(of: self))
                userDefaults.setValue(true, forKey: key)
                userDefaults.synchronize()
            }
            #else
            coachMarksController.start(in: .currentWindow(of: self))
            #endif
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        bind()
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        
        headerView.update(input: (selfUser: dependencyProvider.user, userDetail: UserDetail(user: viewModel.state.user, followersCount: 0, followingUsersCount: 0, postCount: 0, likePostCount: 0, likeFutureLiveCount: 0, likePastLiveCount: 0, followingGroupsCount: 0, isFollowed: false, isFollowing: false, isBlocked: false, isBlocking: false), imagePipeline: dependencyProvider.imagePipeline))
        
        var barButonItems: [UIBarButtonItem] = []
        let settingItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis")!.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(settingButtonTapped(_:))
        )
        barButonItems.append(settingItem)
        switch viewModel.state.displayType {
        case .account:
            self.title = "マイページ"
            let shareItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(didShareButtonTapped))
            barButonItems.append(shareItem)
        case .user:
            self.title = viewModel.state.user.name
            navigationItem.setRightBarButton(nil, animated: true)
        }
        navigationItem.setRightBarButtonItems(
            barButonItems,
            animated: false
        )
    }
    
    func bind() {
        userFollowingViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateFollowing:
                viewModel.refresh()
            case .updateBlocking:
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
//                self.showAlert()
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
        
//        pointViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
//            switch output {
//            case .addPoint(let point):
//                showAlert(title: "ポイント獲得！", message: "\(point.value)ポイント獲得しました！ポイントはアーティストの応援に使えるよ！")
//            case .usePoint(let point): break
//            case .reportError(let err):
//                print(String(describing: err))
//                showAlert()
//            }
//        }

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
        vc.listen { [unowned self] in
            self.listener()
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func didShareButtonTapped() {
        if viewModel.state.user.username != nil {
            shareWithTwitter(type: .user(viewModel.state.user)) { [unowned self] isOK in
                if isOK {
                    pointViewModel.addPoint(point: 100)
                } else {
                    showAlert(title: "シェアできません", message: "Twitterアプリをインストールするとシェアできるようになります！")
                }
            }
        } else {
            showAlert(title: "ユーザーネームを設定してください", message: "プロフィール設定よりユーザーネームを設定するとTwitterでシェアできるようになるよ！")
        }
        
    }
    
    func didSendMessageButtonTapped() {
        viewModel.createMessageRoom(partner: viewModel.state.user)
    }
    
    @objc private func settingButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "設定", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        var actions: [UIAlertAction] = []
        switch viewModel.state.displayType {
        case .account:
            let shareProfileAction = UIAlertAction(title: "ライブ参戦数をインスタでシェア", style: .default, handler: { [unowned self] _ in
                shareUserWithInstagram(user: viewModel.state.user, views: [vc2.scrollStackView])
                pointViewModel.addPoint(point: 100)
            })
            let editProfileAction = UIAlertAction(title: "プロフィール編集", style: .default, handler: { [unowned self] _ in
                let vc = EditUserViewController(dependencyProvider: dependencyProvider, input: ())
                navigationController?.pushViewController(vc, animated: true)
            })
            let requestLiveAction = UIAlertAction(title: "ライブ掲載申請", style: .default, handler: { [unowned self] _ in
                if let url = URL(string: "https://forms.gle/epoBeqdaGeMUcv8o9") {
                    openUrlInBrowser(url: url)
                }
            })
            let myTipAction = UIAlertAction(title: "snack履歴", style: .default, handler: { [unowned self] _ in
                let vc = SocialTipListViewController(dependencyProvider: dependencyProvider, input: .myTip(dependencyProvider.user.id))
                navigationController?.pushViewController(vc, animated: true)
            })
            let logoutAction = UIAlertAction(title: "ログアウト", style: .default, handler: { [unowned self] _ in
                    logout()
            })
            let cancelAction = UIAlertAction(
                title: "キャンセル", style: UIAlertAction.Style.cancel,
                handler: { _ in })
            actions = [
                shareProfileAction,
                editProfileAction,
                requestLiveAction,
                myTipAction,
                logoutAction,
                cancelAction,
            ]
        case .user:
            guard let userDetail = viewModel.state.userDetail else { return }
            let blockAction = UIAlertAction(title: userDetail.isBlocking ? "ブロック解除" : "ブロックする", style: UIAlertAction.Style.default, handler: { [unowned self] _ in
                userFollowingViewModel.didBlockButtonTapped(isBlocking: userDetail.isBlocking)
            })
            let reportAction = UIAlertAction(title: "報告する", style: .default, handler: { [unowned self] _ in
                if let url = URL(string: "https://forms.gle/kcoJZ5qSrBGSaamP6") {
                    openUrlInBrowser(url: url)
                }
            })
            let cancelAction = UIAlertAction(
                title: "キャンセル", style: UIAlertAction.Style.cancel,
                handler: { _ in })
            actions = [blockAction, reportAction, cancelAction]
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
        _ = dependencyProvider.credentialsManager.clear()
        self.listener()
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

extension UserDetailViewController: CoachMarksControllerDelegate, CoachMarksControllerDataSource {
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return coachSteps.count
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        return coachMarksController.helper.makeCoachMark(for: coachSteps[index].view)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: (UIView & CoachMarkBodyView), arrowView: (UIView & CoachMarkArrowView)?) {
        let coachStep = self.coachSteps[index]
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        coachViews.bodyView.hintLabel.text = coachStep.hint
        coachViews.bodyView.nextLabel.text = coachStep.next
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}
