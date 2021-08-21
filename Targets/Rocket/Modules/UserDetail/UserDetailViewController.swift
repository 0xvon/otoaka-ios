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
        self.pageViewController = PageViewController()
        
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
//                    let item = UIBarButtonItem(title: "ログアウト", style: .plain, target: self, action: #selector(logoutButtonTapped(_:)))
//                    navigationItem.setRightBarButton(
//                        item,
//                        animated: false
//                    )
                case .user:
                    self.title = userDetail.name
                }
                refreshControl.endRefreshing()
            case .pushToMessageRoom(let room):
                let vc = MessageRoomViewController(dependencyProvider: dependencyProvider, input: room)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToUserList(let input):
                let vc = UserListViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .openURLInBrowser(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
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

        let vc1 = CollectionListViewController(dependencyProvider: dependencyProvider, input: .userPost(viewModel.state.user))
        let vc2 = CollectionListViewController(dependencyProvider: dependencyProvider, input: .likedPost(viewModel.state.user))
        let vc3 = GroupListViewController(dependencyProvider: dependencyProvider, input: .followingGroups(viewModel.state.user.id))

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
