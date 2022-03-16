//
//  RootViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import Auth0
import Endpoint
import UIKit
import Combine
import SafariServices

final class RootViewController: UITabBarController, Instantiable {
    typealias Input = Void

    let dependencyProvider: DependencyProvider
    private var isFirstViewDidAppear = true
    private var cancellables: Set<AnyCancellable> = []
    let viewModel: RootViewModel

    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = RootViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.tabBar.tintColor = Brand.color(for: .text(.primary))
        self.tabBar.barTintColor = Brand.color(for: .background(.primary))
        self.tabBar.backgroundColor = Brand.color(for: .background(.primary))
        bind()
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didGetSignupStatus(let isSignedUp):
                isSignedUp ? makeViewFromUserInfo() : presentRegistrationScreen()
            case .didGetUserInfo(let user):
                setViewControllers(instantiateTabs(with: user), animated: true)
            case .reportError(let error):
                print(error)
                showAlert()
            }
        }.store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstViewDidAppear {
            isFirstViewDidAppear = false
            checkSignupStatus()
        }
        
        checkVersion()
    }
    
    func checkSignupStatus() {
        dependencyProvider.credentialsManager.hasValid()
            ? viewModel.getSignupStatus()
            : presentRegistrationScreen()
    }
    
    private func presentRegistrationScreen() {
        let vc = RegistrationViewController(dependencyProvider: dependencyProvider) { [unowned self] in
            self.makeViewFromUserInfo()
        }
        let nav = DismissionSubscribableNavigationController(rootViewController: vc)
        nav.subscribeDismission { [unowned self] in
            self.checkSignupStatus()
        }
        self.present(nav, animated: true)
    }
    
    func makeViewFromUserInfo() {
        viewModel.userInfo()
    }
    
    func checkVersion() {
        let versionData: RequiredVersion =  try! dependencyProvider.versioningService.blockingMasterData()
        guard let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return }
        let isRequiredUpdate: Bool = {
            guard let appVersion: Int = Int(appVersion.replacingOccurrences(of: ".", with: "")) else { return false }
            guard let requiredVersion: Int = Int(versionData.required_version.replacingOccurrences(of: ".", with: "")) else { return false }
            return appVersion < requiredVersion
        }()
        
        if isRequiredUpdate {
            promptVersioningViewController(versionData: versionData)
        }
    }
    
    func instantiateTabs(with user: User) -> [UIViewController] {
        let loggedInProvider = LoggedInDependencyProvider(provider: dependencyProvider, user: user)
        let homeVC = BrandNavigationController(rootViewController: HomeViewController(dependencyProvider: loggedInProvider))
        homeVC.tabBarItem = UITabBarItem(
            title: "ライブ",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        let timelineVC = BrandNavigationController(rootViewController: GroupCollectionListViewController(dependencyProvider: loggedInProvider, input: .all))
        timelineVC.tabBarItem = UITabBarItem(title: "snack", image: UIImage(systemName: "flame"), selectedImage: UIImage(systemName: "flame.fill"))
        let searchVC = BrandNavigationController(rootViewController: SearchViewController(dependencyProvider: loggedInProvider))
        searchVC.tabBarItem = UITabBarItem(title: "探す", image: UIImage(systemName: "magnifyingglass"), selectedImage: UIImage(systemName: "magnifyingglass"))
        let accountVC = UserDetailViewController(dependencyProvider: loggedInProvider, input: loggedInProvider.user)
        let accountNav = BrandNavigationController(
            rootViewController: accountVC
        )
        accountNav.tabBarItem = UITabBarItem(
            title: "マイページ",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
        accountVC.listen { [unowned self] in
            checkSignupStatus()
        }
        return [
            homeVC,
            timelineVC,
            searchVC,
            accountNav,
        ]
    }
    
    private func promptVersioningViewController(versionData: RequiredVersion) {
        let alertController = UIAlertController(
            title: "アップデートが必要です", message: "version \(versionData.required_version)が利用可能です。アップデートしてください。", preferredStyle: UIAlertController.Style.alert
        )
        let ok = UIAlertAction(title: "OK", style: .default, handler: { [unowned self] _ in
            let safari = SFSafariViewController(url: URL(string: versionData.update_url)!)
            safari.dismissButtonStyle = .close
            present(safari, animated: true, completion: nil)
        })
        alertController.addAction(ok)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
        self.present(alertController, animated: true)
    }
}
