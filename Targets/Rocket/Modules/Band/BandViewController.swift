//
//  BandViewController.swift
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

final class BandViewController: UIViewController, Instantiable {

    typealias Input = Void
    var input: Input!
    var dependencyProvider: LoggedInDependencyProvider!

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
    private var iconMenu: UIBarButtonItem!

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

    private var isOpened: Bool = false
    private var creationView: UIView!
    private var creationViewHeightConstraint: NSLayoutConstraint!
    private var openButtonView: CreateButton!
    private var createGroupFeedView: CreateButton!
    private var createGroupFeedViewBottomConstraint: NSLayoutConstraint!
    private var createLiveView: CreateButton!
    private var createLiveViewBottomConstraint: NSLayoutConstraint!
    private var creationButtonConstraintItems: [NSLayoutConstraint] = []

    lazy var viewModel = BandViewModel(
        apiClient: dependencyProvider.apiClient,
        youTubeDataApiClient: dependencyProvider.youTubeDataApiClient,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getGroupFeeds(let feeds):
                DispatchQueue.main.async {
                    self.feeds += feeds
                    self.groupFeedTableView.reloadData()
                }
            case .refreshGroupFeeds(let feeds):
                DispatchQueue.main.async {
                    self.feeds = feeds
                    self.groupFeedTableView.reloadData()
                }
            case .getLives(let lives):
                DispatchQueue.main.async {
                    self.lives += lives
                    self.liveTableView.reloadData()
                }
            case .refreshLives(let lives):
                DispatchQueue.main.async {
                    self.lives = lives
                    self.liveTableView.reloadData()
                }
            case .getGroups(let groups):
                DispatchQueue.main.async {
                    self.groups += groups
                    self.groupTableView.reloadData()
                }
            case .refreshGroups(let groups):
                DispatchQueue.main.async {
                    self.groups = groups
                    self.groupTableView.reloadData()
                }
            case .getCharts(let charts):
                DispatchQueue.main.async {
                    self.charts = charts
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
        switch dependencyProvider.user.role {
        case .artist(_):
            setupCreation()
        case .fan(_):
            print()
        }
        requestNotification()
    }

    override func viewDidLayoutSubviews() {
        horizontalScrollView.contentSize.width = UIScreen.main.bounds.width * CGFloat(pageItems.count)
    }

    func setup() {
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
        groupFeedTableView.register(
            UINib(nibName: "BandContentsCell", bundle: nil),
            forCellReuseIdentifier: "BandContentsCell")

        groupFeedTableView.refreshControl = UIRefreshControl()
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
        liveTableView.register(
            UINib(nibName: "LiveCell", bundle: nil), forCellReuseIdentifier: "LiveCell")

        liveTableView.refreshControl = UIRefreshControl()
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
        chartsTableView.register(
            UINib(nibName: "TrackCell", bundle: nil), forCellReuseIdentifier: "TrackCell")

        chartsTableView.refreshControl = UIRefreshControl()
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
        groupTableView.register(
            UINib(nibName: "BandCell", bundle: nil), forCellReuseIdentifier: "BandCell")

        groupTableView.refreshControl = UIRefreshControl()
        groupTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroup(sender:)), for: .valueChanged)
        
        groupPageTitleView = TitleLabelView(input: (title: "BANDS", font: Brand.font(for: .medium), color: Brand.color(for: .text(.primary))))
        groupPageTitleView.translatesAutoresizingMaskIntoConstraints = false
        groupPageButton = UIButton()
        groupPageButton.translatesAutoresizingMaskIntoConstraints = false
        
        setupPages()

        let icon: UIButton = UIButton(type: .custom)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let image = UIImage(url: dependencyProvider.user.thumbnailURL!)
        icon.setImage(image, for: .normal)
        icon.addTarget(self, action: #selector(iconTapped(_:)), for: .touchUpInside)
        icon.imageView?.layer.cornerRadius = 20

        iconMenu = UIBarButtonItem(customView: icon)
        self.navigationItem.leftBarButtonItem = iconMenu

        let constraints = [
            pageStackView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor, constant: 16),
            pageStackView.heightAnchor.constraint(equalToConstant: 40),

            iconMenu.customView!.widthAnchor.constraint(equalToConstant: 40),
            iconMenu.customView!.heightAnchor.constraint(equalToConstant: 40),
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

    private func setupCreation() {
        creationView = UIView()
        creationView.backgroundColor = .clear
        creationView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(creationView)

        creationViewHeightConstraint = NSLayoutConstraint(
            item: creationView!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1,
            constant: 60
        )
        creationView.addConstraint(creationViewHeightConstraint)

        createLiveView = CreateButton(input: UIImage(named: "ticket")!)
        createLiveView.layer.cornerRadius = 30
        createLiveView.translatesAutoresizingMaskIntoConstraints = false
        createLiveView.listen {
            self.createLive()
        }
        creationView.addSubview(createLiveView)

        createLiveViewBottomConstraint = NSLayoutConstraint(
            item: createLiveView!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: creationView,
            attribute: .bottom,
            multiplier: 1,
            constant: 0
        )

        createGroupFeedView = CreateButton(input: UIImage(named: "music")!)
        createGroupFeedView.layer.cornerRadius = 30
        createGroupFeedView.translatesAutoresizingMaskIntoConstraints = false
        createGroupFeedView.listen {
            self.createContents()
        }
        creationView.addSubview(createGroupFeedView)

        createGroupFeedViewBottomConstraint = NSLayoutConstraint(
            item: createGroupFeedView!,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: creationView,
            attribute: .bottom,
            multiplier: 1,
            constant: 0
        )

        openButtonView = CreateButton(input: UIImage(named: "plus")!)
        openButtonView.layer.cornerRadius = 30
        openButtonView.translatesAutoresizingMaskIntoConstraints = false
        openButtonView.listen {
            self.isOpened.toggle()
            self.open(isOpened: self.isOpened)
        }
        creationView.addSubview(openButtonView)

        creationButtonConstraintItems = [
            createGroupFeedViewBottomConstraint,
            createLiveViewBottomConstraint,
        ]

        creationView.addConstraints(creationButtonConstraintItems)

        let constraints = [
            creationView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            creationView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -100),
            creationView.widthAnchor.constraint(equalToConstant: 60),

            openButtonView.bottomAnchor.constraint(equalTo: creationView.bottomAnchor),
            openButtonView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
            openButtonView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
            openButtonView.heightAnchor.constraint(equalTo: creationView.widthAnchor),

            createGroupFeedView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
            createGroupFeedView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
            createGroupFeedView.heightAnchor.constraint(equalTo: creationView.widthAnchor),

            createLiveView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
            createLiveView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
            createLiveView.heightAnchor.constraint(equalTo: creationView.widthAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func open(isOpened: Bool) {
        if isOpened {
            UIView.animate(withDuration: 0.2) {
                self.openButtonView.transform = CGAffineTransform(rotationAngle: .pi * 3 / 4)
            }

            self.creationButtonConstraintItems.enumerated().forEach { (index, item) in
                creationView.removeConstraint(item)
                item.constant = CGFloat((index + 1) * -76)
                creationView.addConstraint(item)
                UIView.animate(withDuration: 0.2) {
                    self.creationView.layoutIfNeeded()
                }
            }

            creationViewHeightConstraint.constant = CGFloat(
                60 + 76 * creationButtonConstraintItems.count)
        } else {
            UIView.animate(withDuration: 0.2) {
                self.openButtonView.transform = .identity
            }

            self.creationButtonConstraintItems.enumerated().forEach { (index, item) in
                creationView.removeConstraint(item)
                item.constant = 0
                creationView.addConstraint(item)
                UIView.animate(withDuration: 0.2) {
                    self.creationView.layoutIfNeeded()
                }
            }

            creationViewHeightConstraint.constant = 60
        }
    }

    func initializeItems() {
        viewModel.getGroupFeeds()
        viewModel.getLives()
        viewModel.getGroups()
        viewModel.getCharts()
    }

    @objc private func refreshGroupFeeds(sender: UIRefreshControl) {
        viewModel.refreshGroupFeeds()
        sender.endRefreshing()
    }

    @objc private func refreshLive(sender: UIRefreshControl) {
        viewModel.refreshLives()
        sender.endRefreshing()
    }

    @objc private func refreshChart(sender: UIRefreshControl) {
        viewModel.getCharts()
        sender.endRefreshing()
    }

    @objc private func refreshGroup(sender: UIRefreshControl) {
        viewModel.refreshGroups()
        sender.endRefreshing()
    }

    func requestNotification() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            UNUserNotificationCenter.current().requestAuthorization(options: [
                .alert, .sound, .badge,
            ]) {
                granted, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.showAlert(title: "エラー", message: error.localizedDescription)
                    }
                    return
                }
                guard granted else { return }

                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func createContents() {
        let vc = PostViewController(dependencyProvider: self.dependencyProvider, input: ())
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.tintColor = Brand.color(for: .text(.primary))
        nav.navigationBar.barTintColor = .clear
        present(nav, animated: true, completion: nil)
    }

    func createLive() {
        let vc = CreateLiveViewController(dependencyProvider: self.dependencyProvider, input: ())
        present(vc, animated: true, completion: nil)
    }
    
    @objc func pageButtonTapped(_ sender: UIButton) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = UIScreen.main.bounds.width * CGFloat(sender.tag)
        }
    }

    @objc private func iconTapped(_ sender: Any) {
        let vc = AccountViewController(dependencyProvider: self.dependencyProvider, input: ())
        vc.signout {
            print("signout")
            self.listener()
        }
        present(vc, animated: true, completion: nil)
    }
    
    private var listener: () -> Void = {}
    func signout(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
    
}

extension BandViewController: UITableViewDelegate, UITableViewDataSource {
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
            let cell = tableView.dequeueReusableCell(ArtistFeedCell.self, input: feed, for: indexPath)
            cell.listen { [weak self] _ in
                self?.feedCommentButtonTapped(cellIndex: indexPath.section)
            }
            return cell
        case self.liveTableView:
            let live = self.lives[indexPath.section].live
            let cell = tableView.dequeueReusableCell(LiveCell.self, input: live, for: indexPath)
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
            let band = self.groups[indexPath.section]
            let cell = tableView.dequeueReusableCell(BandCell.self, input: band, for: indexPath)
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
                dependencyProvider: self.dependencyProvider, input: (live: live, ticket: nil))
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
}

extension BandViewController: UIScrollViewDelegate {
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

extension BandViewController: UNUserNotificationCenterDelegate {

}
