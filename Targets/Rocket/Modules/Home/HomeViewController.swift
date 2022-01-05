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
//import Parchment
import AppTrackingTransparency
import SCLAlertView
import Instructions

final class HomeViewController: UIViewController {
    let dependencyProvider: LoggedInDependencyProvider
    private var cancellables: [AnyCancellable] = []
    private let urlSchemeActionViewModel: UrlSchemeActionViewModel
    private let pointViewModel: PointViewModel
    
    private lazy var notificationButton: UIBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "bell"),
        style: .plain,
        target: self,
        action: #selector(notificationButtonTapped)
    )
    private lazy var messageButton: UIBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "envelope"),
        style: .plain,
        target: self,
        action: #selector(messageButtonTapped)
    )
    
    private let coachMarksController = CoachMarksController()
    private lazy var coachSteps: [CoachStep] = [
//        CoachStep(view: searchButton.value(forKey: "view") as! UIView, hint: "このページにはみんなのsnack(差し入れ)が表示されるよ！\nsnackをすると自分のファン度が高まったりライブでかけがえのない体験に変わるよ！\n試しにアーティストを探してsnackしてみよう！", next: "ok"),
    ]
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.urlSchemeActionViewModel = UrlSchemeActionViewModel(dependencyProvider: dependencyProvider)
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        urlSchemeActionViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .pushToUserDetail(let input):
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToGroupDetail(let input):
                let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToLiveDetail(let input):
                let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPostDetail(let input):
                let vc = PostDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .reportError(let err):
                print(String(describing: err))
                showAlert(title: "見つかりませんでした", message: "URLが正しいかお確かめの上再度お試しください")
            }
        }
        .store(in: &cancellables)
        
        pointViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .addPoint(_):
                self.showSuccessToGetPoint(2000)
            default: break
            }
        }
        .store(in: &cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ホーム"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Brand.color(for: .background(.primary))
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        
        navigationItem.setRightBarButtonItems([
            messageButton,
            notificationButton,
        ], animated: false)
        
        setPagingViewController()
        requestNotification()
//        showWalkThrough()
        presentPoint()
        if #available(iOS 14, *) {
            checkTrackingAuthorizationStatus()
        }
        actForUrlScheme()
        
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if PRODUCTION
        let userDefaults = UserDefaults.standard
        let key = "HomeVCPresented_v3.2.0.r"
        if !userDefaults.bool(forKey: key) {
            coachMarksController.start(in: .currentWindow(of: self))
            userDefaults.setValue(true, forKey: key)
            userDefaults.synchronize()
        }
        #else
        coachMarksController.start(in: .currentWindow(of: self))
        #endif
    }
    
    private func setPagingViewController() {
        let vc = LiveListViewController(dependencyProvider: dependencyProvider, input: .followingGroupsLives)
        self.addChild(vc)
        self.view.addSubview(vc.view)
        vc.didMove(toParent: self)
        
//        let vc1 = PostListViewController(dependencyProvider: dependencyProvider, input: .followingPost)
//        let vc2 = PostListViewController(dependencyProvider: dependencyProvider, input: .trendPost)
//        let pagingViewController = PagingViewController(viewControllers: [
//            vc0,
//            vc1,
//            vc2,
//        ])
//        self.addChild(pagingViewController)
//        self.view.addSubview(pagingViewController.view)
//        pagingViewController.didMove(toParent: self)
//        pagingViewController.menuBackgroundColor = Brand.color(for: .background(.primary))
//        pagingViewController.borderColor = .clear
//        pagingViewController.selectedTextColor = Brand.color(for: .brand(.primary))
//        pagingViewController.indicatorColor = Brand.color(for: .brand(.primary))
//        pagingViewController.textColor = Brand.color(for: .text(.primary))
//        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            pagingViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
//            pagingViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
//            pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            pagingViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
//        ])
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
    
    @available(iOS 14, *)
    func checkTrackingAuthorizationStatus() {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .notDetermined:
            requestTrackingAuthorization()
        case .restricted:
            updateTrackingAuthorizationStatus(false)
        case .denied:
            updateTrackingAuthorizationStatus(false)
        case .authorized:
            updateTrackingAuthorizationStatus(true)
        @unknown default:
            fatalError()
        }
    }

    @available(iOS 14, *)
    func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .notDetermined: break
            case .restricted:
                self.updateTrackingAuthorizationStatus(false)
            case .denied:
                self.updateTrackingAuthorizationStatus(false)
            case .authorized:
                self.updateTrackingAuthorizationStatus(true)
            @unknown default:
                fatalError()
            }
        }
    }

    func updateTrackingAuthorizationStatus(_ b: Bool) {
    }
    
//    private func showWalkThrough() {
//        let userDefaults = UserDefaults.standard
//        let key = "walkThroughPresented_v3.2.0.r\(UUID.init().uuidString)"
//        if !userDefaults.bool(forKey: key) {
//            let vc = WalkThroughViewController(dependencyProvider: dependencyProvider)
//            let nav = DismissionSubscribableNavigationController(rootViewController: vc)
//            present(nav, animated: true, completion: nil)
//            userDefaults.setValue(true, forKey: key)
//            userDefaults.synchronize()
//            nav.subscribeDismission { [unowned self] in
//                presentPoint()
//            }
//        }
//    }
    
    private func presentPoint() {
        #if PRODUCTION
        let userDefaults = UserDefaults.standard
        let key = "pointPresented_v3.2.0.r"
        if !userDefaults.bool(forKey: key) {
            pointViewModel.addPoint(point: 2000)
            userDefaults.setValue(true, forKey: key)
            userDefaults.synchronize()
        }
        #else
        pointViewModel.addPoint(point: 2000)
        #endif
    }
    
    private func actForUrlScheme() {
        if let url = dependencyProvider.urlScheme {
            urlSchemeActionViewModel.action(url: url)
        }
    }
    
    @objc private func messageButtonTapped() {
        let vc = MessageListViewController(dependencyProvider: dependencyProvider, input: ())
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func notificationButtonTapped() {
        let vc = UserNotificationViewControlelr(dependencyProvider: dependencyProvider)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension HomeViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
}

extension HomeViewController: CoachMarksControllerDelegate, CoachMarksControllerDataSource {
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
