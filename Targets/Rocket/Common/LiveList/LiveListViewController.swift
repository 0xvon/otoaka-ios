//
//  LiveListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import Endpoint
import Combine
import SafariServices
import UIComponent
import Instructions

final class LiveListViewController: UIViewController, Instantiable {
    typealias Input = LiveListViewModel.Input

    let dependencyProvider: LoggedInDependencyProvider
    private var liveTableView: UITableView!

    let viewModel: LiveListViewModel
    let pointViewModel: PointViewModel
    private var cancellables: [AnyCancellable] = []
    
    private lazy var header: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
        ])
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .largeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        label.text = "開催中のsnack event"
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
        ])
        
        view.addSubview(eventContent)
        NSLayoutConstraint.activate([
            eventContent.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            eventContent.leftAnchor.constraint(equalTo: view.leftAnchor),
            eventContent.rightAnchor.constraint(equalTo: view.rightAnchor),
            eventContent.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            eventContent.heightAnchor.constraint(equalToConstant: 192),
        ])
        return view
    }()
    private lazy var eventContent: SocialTipEventCardCollectionView = {
        let view = SocialTipEventCardCollectionView(socialTipEvents: [], imagePipeline: dependencyProvider.imagePipeline)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let coachMarksController = CoachMarksController()
    private lazy var coachSteps: [CoachStep] = [
//        CoachStep(view: header, hint: "ここにはsnackがライブ体験に変わるイベントが表示されます！試しにどんなイベントがあるか見てみよう！", next: "ok"),
    ]

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = LiveListViewModel(
            dependencyProvider: dependencyProvider,
            input: input
        )
        self.pointViewModel = PointViewModel(dependencyProvider: dependencyProvider)

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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        #if PRODUCTION
//        let userDefaults = UserDefaults.standard
//        let key = "LiveVCPresented_v3.2.0.r"
//        if !userDefaults.bool(forKey: key) {
//            coachMarksController.start(in: .currentWindow(of: self))
//            userDefaults.setValue(true, forKey: key)
//            userDefaults.synchronize()
//        }
//        #else
//        coachMarksController.start(in: .currentWindow(of: self))
//        #endif
    }

    private func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadTableView:
                self.setTableViewBackgroundView(tableView: liveTableView)
                self.liveTableView.reloadData()
            case .getEvents(let events):
                eventContent.inject(socialTipEvents: events)
            case .didToggleLikeLive: break
            case .error(let error):
                print(String(describing: error))
//                self.showAlert()
            }
        }
        .store(in: &cancellables)
        
        pointViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .addPoint(_):
                self.showSuccessToGetPoint(100)
            default: break
            }
        }
        .store(in: &cancellables)
        
        eventContent.listen { [unowned self] socialTipEvent in
            let vc = SocialTipEventDetailViewController(dependencyProvider: dependencyProvider, input: socialTipEvent)
            let nav = self.navigationController ?? presentingViewController?.navigationController
            nav?.pushViewController(vc, animated: true)
        }
    }

    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        navigationItem.largeTitleDisplayMode = .never
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        
        liveTableView = UITableView(frame: .zero, style: .grouped)
        liveTableView.translatesAutoresizingMaskIntoConstraints = false
        liveTableView.showsVerticalScrollIndicator = false
        liveTableView.tableFooterView = UIView(frame: .zero)
        liveTableView.separatorStyle = .none
        liveTableView.backgroundColor = .clear
        liveTableView.delegate = self
        liveTableView.dataSource = self
        liveTableView.registerCellClass(LiveCell.self)
        self.view.addSubview(liveTableView)
        
        liveTableView.refreshControl = BrandRefreshControl()
        liveTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)
        
        let constraints: [NSLayoutConstraint] = [
            liveTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            liveTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            liveTableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            liveTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    func inject(_ input: Input) {
        viewModel.inject(input)
    }
    
    @objc private func refreshGroups(sender: UIRefreshControl) {
        self.viewModel.refresh()
        sender.endRefreshing()
    }
    
    private var listener: (LiveFeed) -> Void = { _ in }
    func listen(_ listener: @escaping (LiveFeed) -> Void) {
        self.listener = listener
    }
}

extension LiveListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.lives.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 332
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch viewModel.dataSource {
        case .followingGroupsLives: return 210
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch viewModel.dataSource {
        case .followingGroupsLives:
            return header
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var live = self.viewModel.state.lives[indexPath.row]
        var cellType: LiveCellContent.LiveCellContentType
        switch viewModel.dataSource {
        case .searchResultToSelect(_):
            cellType = .review
        default:
            cellType = .normal
        }
        
        let cell = tableView.dequeueReusableCell(LiveCell.self, input: (live: live, imagePipeline: dependencyProvider.imagePipeline, type: cellType), for: indexPath)
        cell.listen { [unowned self] output in
            switch output {
            case .buyTicketButtonTapped:
                guard let url = live.live.piaEventUrl else { return }
                let safari = SFSafariViewController(
                    url: url)
                safari.dismissButtonStyle = .close
                present(safari, animated: true, completion: nil)
            case .likeButtonTapped:
                live.isLiked
                   ? pointViewModel.usePoint(point: 100)
                   : pointViewModel.addPoint(point: 100)
                viewModel.likeLiveButtonTapped(liveFeed: live)
                live.isLiked.toggle()
                viewModel.updateLive(live: live)
            case .numOfLikeTapped:
                let vc = UserListViewController(dependencyProvider: dependencyProvider, input: .liveLikedUsers(live.live.id))
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .reportButtonTapped:
                let vc = PostViewController(dependencyProvider: dependencyProvider, input: (live: live.live, post: nil))
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .numOfReportTapped:
                let vc = PostListViewController(dependencyProvider: dependencyProvider, input: .livePost(live.live))
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            case .selfTapped:
                let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: live.live)
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let live = self.viewModel.state.lives[indexPath.row]
        self.listener(live)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.willDisplay(rowAt: indexPath)
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            switch viewModel.dataSource {
            case .likedLive(_), .likedFutureLive(_):
                let emptyCollectionView = EmptyCollectionView(emptyType: .likedLiveList, actionButtonTitle: "ライブ追加する")
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                return emptyCollectionView
            case .groupLive(_):
                let emptyCollectionView = EmptyCollectionView(emptyType: .groupLiveList, actionButtonTitle: "ライブ追加する")
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                return emptyCollectionView
            case .followingGroupsLives:
                let emptyCollectionView = EmptyCollectionView(emptyType: .followingGroupsLives, actionButtonTitle: "アーティストを探す")
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                return emptyCollectionView
            default:
                let emptyCollectionView = EmptyCollectionView(emptyType: .liveList, actionButtonTitle: "ライブ追加する")
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                return emptyCollectionView
            }
            
        }()
        emptyCollectionView.listen { [unowned self] in
            switch viewModel.dataSource {
            case .followingGroupsLives:
                let vc = SearchGroupViewController(dependencyProvider: dependencyProvider)
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            default:
                let vc = CreateLiveViewController(dependencyProvider: dependencyProvider, input: ())
                let nav = self.navigationController ?? presentingViewController?.navigationController
                nav?.pushViewController(vc, animated: true)
            }
        }
        tableView.backgroundView = self.viewModel.state.lives.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 232),
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor, constant: -32),
                backgroundView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            ])
        }
    }
}

extension LiveListViewController: PageContent {
    var scrollView: UIScrollView {
        _ = view
        return self.liveTableView
    }
}

extension LiveListViewController: CoachMarksControllerDelegate, CoachMarksControllerDataSource {
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
