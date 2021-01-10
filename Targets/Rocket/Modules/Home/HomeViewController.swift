//
//  HomeViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import Endpoint
import Foundation
import UIKit
import UserNotifications
import SafariServices
import InternalDomain

final class HomeViewController: UIViewController, Instantiable {

    typealias Input = Void
    var input: Input!
    let dependencyProvider: LoggedInDependencyProvider

    @IBOutlet weak var horizontalScrollView: UIScrollView!
    
    private var pageStackView: UIStackView!
    private var pageTitleStackViewLeadingConstraint: NSLayoutConstraint!
    private var groupFeedsView: UIView!
    private var groupFeedTableView: UITableView!
    private var groupFeedPageTitleView: TitleLabelView!
    private var groupFeedPageButton: UIButton!
    private var liveView: UIView!
    private var liveTableView: UITableView!
    private var livePageTitleView: TitleLabelView!
    private var livePageButton: UIButton!
    private var chartsView: UIView!
    private var chartsTableView: UITableView!
    private var chartsPageTitleView: TitleLabelView!
    private var chartsPageButton: UIButton!
    private var groupsView: UIView!
    private var groupTableView: UITableView!
    private var groupPageTitleView: TitleLabelView!
    private var groupPageButton: UIButton!

    var lives: [LiveFeed] = []
    var feeds: [ArtistFeedSummary] = []
    var groups: [Group] = []
    var charts: [ChannelDetail.ChannelItem] = []
    var pageItems: [PageItem] = []
    
    struct PageItem {
        let page: UIView
        let pageButton: UIButton
        let tebleView: UITableView
        let pageTitle: TitleLabelView
    }

    lazy var viewModel = HomeViewModel(
        apiClient: dependencyProvider.apiClient,
        youTubeDataApiClient: dependencyProvider.youTubeDataApiClient,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getGroupFeeds(let feeds):
                DispatchQueue.main.async {
                    self.feeds += feeds
                    self.setTableViewBackgroundView(tableView: self.groupFeedTableView)
                    self.groupFeedTableView.reloadData()
                }
            case .getUserInfo(let user):
                DispatchQueue.main.async {
                }
            case .refreshGroupFeeds(let feeds):
                DispatchQueue.main.async {
                    self.feeds = feeds
                    self.setTableViewBackgroundView(tableView: self.groupFeedTableView)
                    self.groupFeedTableView.reloadData()
                }
            case .getLives(let lives):
                DispatchQueue.main.async {
                    self.lives += lives
                    self.setTableViewBackgroundView(tableView: self.liveTableView)
                    self.liveTableView.reloadData()
                }
            case .refreshLives(let lives):
                DispatchQueue.main.async {
                    self.lives = lives
                    self.setTableViewBackgroundView(tableView: self.liveTableView)
                    self.liveTableView.reloadData()
                }
            case .getGroups(let groups):
                DispatchQueue.main.async {
                    self.groups += groups
                    self.setTableViewBackgroundView(tableView: self.groupTableView)
                    self.groupTableView.reloadData()
                }
            case .refreshGroups(let groups):
                DispatchQueue.main.async {
                    self.groups = groups
                    self.setTableViewBackgroundView(tableView: self.groupTableView)
                    self.groupTableView.reloadData()
                }
            case .getCharts(let charts):
                DispatchQueue.main.async {
                    self.charts = charts
                    self.setTableViewBackgroundView(tableView: self.chartsTableView)
                    self.chartsTableView.reloadData()
                }
            case .reserveTicket(let ticket):
                DispatchQueue.main.async {
                    if let index = self.lives.firstIndex(where: { $0.live.id == ticket.live.id }) {
                        self.lives.remove(at: index)
                    }
                    self.liveTableView.reloadData()
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        requestNotification()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: true)
        setupFloatingItems(role: dependencyProvider.user.role)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }

    override func viewDidLayoutSubviews() {
        horizontalScrollView.contentSize.width = UIScreen.main.bounds.width * CGFloat(pageItems.count)
    }

    func setup() {
        title = "Home"
        horizontalScrollView.delegate = self
        horizontalScrollView.backgroundColor = Brand.color(for: .background(.primary))
        
        pageStackView = UIStackView()
        pageStackView.translatesAutoresizingMaskIntoConstraints = false
        pageStackView.axis = .horizontal
        pageStackView.spacing = 8
        pageStackView.distribution = .equalSpacing
        self.view.addSubview(pageStackView)
        
        pageTitleStackViewLeadingConstraint = NSLayoutConstraint(
            item: pageStackView!,
            attribute: .left,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .left,
            multiplier: 1,
            constant: 16
        )
        self.view.addConstraint(pageTitleStackViewLeadingConstraint)

        groupFeedsView = UIView()
        groupFeedsView.translatesAutoresizingMaskIntoConstraints = false
        groupFeedsView.backgroundColor = Brand.color(for: .background(.primary))

        groupFeedTableView = UITableView()
        groupFeedTableView.translatesAutoresizingMaskIntoConstraints = false
        groupFeedTableView.showsVerticalScrollIndicator = false
        groupFeedTableView.tableFooterView = UIView(frame: .zero)
        groupFeedTableView.separatorStyle = .none
        groupFeedTableView.backgroundColor = Brand.color(for: .background(.primary))
        groupFeedTableView.delegate = self
        groupFeedTableView.dataSource = self
        groupFeedTableView.registerCellClass(ArtistFeedCell.self)

        groupFeedTableView.refreshControl = BrandRefreshControl()
        groupFeedTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroupFeeds(sender:)), for: .valueChanged)
        
        groupFeedPageTitleView = TitleLabelView(input: (title: "FEEDS", font: Brand.font(for: .xlargeStrong), color: Brand.color(for: .text(.primary))))
        groupFeedPageTitleView.translatesAutoresizingMaskIntoConstraints = false
        groupFeedPageButton = UIButton()
        groupFeedPageButton.translatesAutoresizingMaskIntoConstraints = false

        liveView = UIView()
        liveView.translatesAutoresizingMaskIntoConstraints = false
        liveView.backgroundColor = Brand.color(for: .background(.primary))

        liveTableView = UITableView()
        liveTableView.translatesAutoresizingMaskIntoConstraints = false
        liveTableView.showsVerticalScrollIndicator = false
        liveTableView.tableFooterView = UIView(frame: .zero)
        liveTableView.separatorStyle = .none
        liveTableView.backgroundColor = Brand.color(for: .background(.primary))
        liveTableView.delegate = self
        liveTableView.dataSource = self
        liveTableView.registerCellClass(LiveCell.self)

        liveTableView.refreshControl = BrandRefreshControl()
        liveTableView.refreshControl?.addTarget(
            self, action: #selector(refreshLive(sender:)), for: .valueChanged)
        
        livePageTitleView = TitleLabelView(input: (title: "LIVE", font: Brand.font(for: .medium), color: Brand.color(for: .text(.primary))))
        livePageTitleView.translatesAutoresizingMaskIntoConstraints = false
        livePageButton = UIButton()
        livePageButton.translatesAutoresizingMaskIntoConstraints = false
        
        chartsView = UIView()
        chartsView.translatesAutoresizingMaskIntoConstraints = false
        chartsView.backgroundColor = Brand.color(for: .background(.primary))

        chartsTableView = UITableView()
        chartsTableView.translatesAutoresizingMaskIntoConstraints = false
        chartsTableView.showsVerticalScrollIndicator = false
        chartsTableView.backgroundColor = Brand.color(for: .background(.primary))
        chartsTableView.tableFooterView = UIView(frame: .zero)
        chartsTableView.separatorStyle = .none
        chartsTableView.delegate = self
        chartsTableView.dataSource = self
        chartsTableView.registerCellClass(TrackCell.self)

        chartsTableView.refreshControl = BrandRefreshControl()
        chartsTableView.refreshControl?.addTarget(
            self, action: #selector(refreshChart(sender:)), for: .valueChanged)

        groupsView = UIView()
        groupsView.translatesAutoresizingMaskIntoConstraints = false
        groupsView.backgroundColor = Brand.color(for: .background(.primary))
        
        chartsPageTitleView = TitleLabelView(input: (title: "CHARTS", font: Brand.font(for: .medium), color: Brand.color(for: .text(.primary))))
        chartsPageTitleView.translatesAutoresizingMaskIntoConstraints = false
        chartsPageButton = UIButton()
        chartsPageButton.translatesAutoresizingMaskIntoConstraints = false

        groupTableView = UITableView()
        groupTableView.translatesAutoresizingMaskIntoConstraints = false
        groupTableView.showsVerticalScrollIndicator = false
        groupTableView.tableFooterView = UIView(frame: .zero)
        groupTableView.separatorStyle = .none
        groupTableView.backgroundColor = Brand.color(for: .background(.primary))
        groupTableView.delegate = self
        groupTableView.dataSource = self
        groupTableView.register(UINib(nibName: "BandCell", bundle: nil), forCellReuseIdentifier: "BandCell")

        groupTableView.refreshControl = BrandRefreshControl()
        groupTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroup(sender:)), for: .valueChanged)
        
        groupPageTitleView = TitleLabelView(input: (title: "BANDS", font: Brand.font(for: .medium), color: Brand.color(for: .text(.primary))))
        groupPageTitleView.translatesAutoresizingMaskIntoConstraints = false
        groupPageButton = UIButton()
        groupPageButton.translatesAutoresizingMaskIntoConstraints = false
        
        setupPages()

        let constraints = [
            pageStackView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor, constant: 16),
            pageStackView.heightAnchor.constraint(equalToConstant: 40),
        ]
        NSLayoutConstraint.activate(constraints)
        initializeItems()
    }
    
    private func setupPages() {
        pageItems = [
            PageItem(page: groupFeedsView, pageButton: groupFeedPageButton, tebleView: groupFeedTableView, pageTitle: groupFeedPageTitleView),
            PageItem(page: groupsView, pageButton: groupPageButton, tebleView: groupTableView, pageTitle: groupPageTitleView),
            PageItem(page: liveView, pageButton: livePageButton, tebleView: liveTableView, pageTitle: livePageTitleView),
//            PageItem(page: chartsView, pageButton: chartsPageButton, tebleView: chartsTableView, pageTitle: chartsPageTitleView),
        ]
        
        for (index, item) in pageItems.enumerated() {
            self.horizontalScrollView.addSubview(item.page)
            item.page.addSubview(item.tebleView)
            
            pageStackView.addArrangedSubview(item.pageTitle)
            item.pageTitle.addSubview(item.pageButton)
            item.pageButton.addTarget(self, action: #selector(pageButtonTapped(_:)), for: .touchUpInside)
            item.pageButton.tag = index
            
            let constraints = [
                item.page.leftAnchor.constraint(equalTo: (index == 0) ? horizontalScrollView.leftAnchor : pageItems[index - 1].page.rightAnchor),
                item.page.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
                item.page.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
                item.page.centerYAnchor.constraint(equalTo: horizontalScrollView.centerYAnchor),
                item.page.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
                
                item.tebleView.leftAnchor.constraint(equalTo: item.page.leftAnchor, constant: 16),
                item.tebleView.rightAnchor.constraint(
                    equalTo: item.page.rightAnchor, constant: -16),
                item.tebleView.topAnchor.constraint(equalTo: item.page.topAnchor, constant: 56),
                item.tebleView.bottomAnchor.constraint(
                    equalTo: item.page.bottomAnchor, constant: -16),
                
                item.pageButton.topAnchor.constraint(equalTo: item.pageTitle.topAnchor),
                item.pageButton.bottomAnchor.constraint(equalTo: item.pageTitle.bottomAnchor),
                item.pageButton.rightAnchor.constraint(equalTo: item.pageTitle.rightAnchor),
                item.pageButton.leftAnchor.constraint(equalTo: item.pageTitle.leftAnchor),
            ]
            NSLayoutConstraint.activate(constraints)
        }
    }

    private func setupFloatingItems(role: RoleProperties) {
        let items: [FloatingButtonItem]
        switch role {
        case .artist:
            let createLiveView = FloatingButtonItem(icon: UIImage(named: "ticket")!)
            createLiveView.addTarget(self, action: #selector(createLive), for: .touchUpInside)
            let createFeedView = FloatingButtonItem(icon: UIImage(named: "music")!)
            createFeedView.addTarget(self, action: #selector(createFeed), for: .touchUpInside)
            items = [createLiveView, createFeedView]
        case .fan:
            items = []
        }
        let floatingController = dependencyProvider.viewHierarchy.floatingViewController
        floatingController.setFloatingButtonItems(items)
    }

    func initializeItems() {
        viewModel.getUserInfo()
        viewModel.getGroupFeeds()
        viewModel.getLives()
        viewModel.getGroups()
        viewModel.getCharts()
    }

    @objc private func refreshGroupFeeds(sender: UIRefreshControl) {
        viewModel.getUserInfo()
        viewModel.refreshGroupFeeds()
        sender.endRefreshing()
    }

    @objc private func refreshLive(sender: UIRefreshControl) {
        viewModel.getUserInfo()
        viewModel.refreshLives()
        sender.endRefreshing()
    }

    @objc private func refreshChart(sender: UIRefreshControl) {
        viewModel.getUserInfo()
        viewModel.getCharts()
        sender.endRefreshing()
    }

    @objc private func refreshGroup(sender: UIRefreshControl) {
        viewModel.getUserInfo()
        viewModel.refreshGroups()
        sender.endRefreshing()
    }

    func requestNotification() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [
            .alert, .sound, .badge,
        ]) {
            granted, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
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

    @objc func createFeed() {
        let vc = PostViewController(dependencyProvider: self.dependencyProvider, input: ())
        let nav = BrandNavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }

    @objc func createLive() {
        let vc = CreateLiveViewController(dependencyProvider: self.dependencyProvider, input: ())
        let nav = BrandNavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
    
    @objc func pageButtonTapped(_ sender: UIButton) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = UIScreen.main.bounds.width * CGFloat(sender.tag)
        }
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        switch tableView {
        case self.groupFeedTableView:
            return self.feeds.count
        case self.liveTableView:
            return self.lives.count
        case self.chartsTableView:
            return self.charts.count
        case self.groupTableView:
            return self.groups.count
        default:
            return 10
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case self.groupFeedTableView:
            return 300
        case self.liveTableView:
            return 300
        case self.chartsTableView:
            return 400
        case self.groupTableView:
            return 250
        default:
            return 100
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case self.groupFeedTableView:
            let feed = self.feeds[indexPath.section]
            let cell = tableView.dequeueReusableCell(
                ArtistFeedCell.self,
                input: (feed: feed, imagePipeline: dependencyProvider.imagePipeline),
                for: indexPath
            )
            cell.listen { [weak self] _ in
                self?.feedCommentButtonTapped(cellIndex: indexPath.section)
            }
            return cell
        case self.liveTableView:
            let live = self.lives[indexPath.section].live
            let cell = tableView.dequeueReusableCell(LiveCell.self, input: (live: live, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
            cell.listen { [weak self] output in
                switch output {
                case .listenButtonTapped: self?.listenButtonTapped(cellIndex: indexPath.section)
                case .buyTicketButtonTapped: self?.buyTicketButtonTapped(cellIndex: indexPath.section)
                }
            }
            return cell
        case self.chartsTableView:
            let chart = self.charts[indexPath.section]
            let cell = tableView.dequeueReusableCell(TrackCell.self, input: chart, for: indexPath)
            return cell
        case self.groupTableView:
            let group = self.groups[indexPath.section]
            let cell = tableView.dequeueReusableCell(GroupCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case self.groupTableView:
            let band = self.groups[indexPath.section]
            let vc = BandDetailViewController(
                dependencyProvider: self.dependencyProvider, input: band)
            self.navigationController?.pushViewController(vc, animated: true)
        case self.liveTableView:
            let live = self.lives[indexPath.section].live
            let vc = LiveDetailViewController(
                dependencyProvider: self.dependencyProvider, input: live)
            self.navigationController?.pushViewController(vc, animated: true)
        case self.groupFeedTableView:
            let feed = self.feeds[indexPath.section]
            switch feed.feedType {
            case .youtube(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
                present(safari, animated: true, completion: nil)
            }
        case self.chartsTableView:
            let videoId = self.charts[indexPath.section].id.videoId
            if let url = URL(string: "https://youtu.be/\(videoId)") {
                let safari = SFSafariViewController(url: url)
                present(safari, animated: true, completion: nil)
            }
        default:
            print("hello")
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func setTableViewBackgroundView(tableView: UITableView) {
        switch tableView {
        case self.groupFeedTableView:
            let emptyCollectionView: EmptyCollectionView = {
                let emptyCollectionView = EmptyCollectionView(emptyType: .feed, actionButtonTitle: "バンドを探す")
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                emptyCollectionView.listen {
                    self.didSearchButtonTapped()
                }
                return emptyCollectionView
            }()
            tableView.backgroundView = feeds.isEmpty ? emptyCollectionView : nil
        case self.liveTableView:
            let emptyCollectionView: EmptyCollectionView = {
                let emptyCollectionView = EmptyCollectionView(emptyType: .live, actionButtonTitle: "バンドを探す")
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                emptyCollectionView.listen {
                    self.didSearchButtonTapped()
                }
                return emptyCollectionView
            }()
            tableView.backgroundView = self.lives.isEmpty ? emptyCollectionView : nil
        case self.chartsTableView:
            let emptyCollectionView: EmptyCollectionView = {
                let emptyCollectionView = EmptyCollectionView(emptyType: .chart, actionButtonTitle: "バンドを探す")
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                emptyCollectionView.listen {
                    self.didSearchButtonTapped()
                }
                return emptyCollectionView
            }()
            tableView.backgroundView = charts.isEmpty ? emptyCollectionView : nil
        case self.groupTableView:
            let emptyCollectionView: EmptyCollectionView = {
                let emptyCollectionView = EmptyCollectionView(emptyType: .group, actionButtonTitle: nil)
                emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
                return emptyCollectionView
            }()
            tableView.backgroundView = groups.isEmpty ? emptyCollectionView : nil
        default:
            break
        }
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
    
    private func didSearchButtonTapped() {
        self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers![2]
    }

    private func listenButtonTapped(cellIndex: Int) {
        print("listen")
    }

    private func buyTicketButtonTapped(cellIndex: Int) {
        let live = self.lives[cellIndex].live
        viewModel.reserveTicket(liveId: live.id)
    }
    
    private func feedCommentButtonTapped(cellIndex: Int) {
        let feed = self.feeds[cellIndex]
        let vc = CommentListViewController(dependencyProvider: dependencyProvider, input: .feedComment(feed))
        present(vc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch tableView {
        case self.groupFeedTableView:
            if (self.feeds.count - indexPath.section) == 2 && self.feeds.count % per == 0 {
                self.viewModel.getGroupFeeds()
            }
        case self.liveTableView:
            if (self.lives.count - indexPath.section) == 2 && self.lives.count % per == 0 {
                self.viewModel.getLives()
            }
        case self.groupTableView:
            if (self.groups.count - indexPath.section) == 2 && self.groups.count % per == 0 {
                self.viewModel.getGroups()
            }
        default:
            break
        }
    }

    // fIXME: Don't override
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        viewControllerToPresent.presentationController?.delegate = self
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

extension HomeViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: true)
    }
}

extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == horizontalScrollView {
            let pageIndex: Int = min(
                Int(
                    (scrollView.contentOffset.x + UIScreen.main.bounds.width / 2)
                        / UIScreen.main.bounds.width
                ), self.pageItems.count - 1)
            var titleViews: [TitleLabelView] = pageItems.map { $0.pageTitle }
            titleViews[pageIndex].changeStyle(
                font: Brand.font(for: .xlargeStrong), color: Brand.color(for: .text(.primary)))
            titleViews.remove(at: pageIndex)
            titleViews.forEach {
                $0.changeStyle(font: Brand.font(for: .mediumStrong), color: Brand.color(for: .text(.primary)))
            }
            pageTitleStackViewLeadingConstraint.constant = CGFloat(
                16 - (scrollView.contentOffset.x / UIScreen.main.bounds.width * 50))
        }
    }
}

extension HomeViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
