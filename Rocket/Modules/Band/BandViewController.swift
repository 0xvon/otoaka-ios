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

final class BandViewController: UIViewController, Instantiable {

    typealias Input = Void
    var input: Input!
    var dependencyProvider: LoggedInDependencyProvider!

    @IBOutlet weak var horizontalScrollView: UIScrollView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var pageStackView: UIStackView!
    private var pageTitleStackViewLeadingConstraint: NSLayoutConstraint!
    private var contentsView: UIView!
    private var contentsTableView: UITableView!
    private var contentsPageTitleView: TitleLabelView!
    private var contentsPageButton: UIButton!
    private var liveView: UIView!
    private var liveTableView: UITableView!
    private var livePageTitleView: TitleLabelView!
    private var livePageButton: UIButton!
    private var chartsView: UIView!
    private var chartsTableView: UITableView!
    private var chartsPageTitleView: TitleLabelView!
    private var chartsPageButton: UIButton!
    private var bandsView: UIView!
    private var bandsTableView: UITableView!
    private var bandsPageTitleView: TitleLabelView!
    private var bandsPageButton: UIButton!
    private var iconMenu: UIBarButtonItem!

    var lives: [LiveFeed] = []
    //    var contents = []
    var bands: [Group] = []
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
    private var createContentsView: CreateButton!
    private var createContentsViewBottomConstraint: NSLayoutConstraint!
    private var createLiveView: CreateButton!
    private var createLiveViewBottomConstraint: NSLayoutConstraint!
    private var creationButtonConstraintItems: [NSLayoutConstraint] = []

    lazy var viewModel = BandViewModel(
        apiClient: dependencyProvider.apiClient,
        youTubeDataApiClient: dependencyProvider.youTubeDataApiClient,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getLives(let lives):
                DispatchQueue.main.async {
                    self.lives = lives
                    print(lives.count)
                    self.liveTableView.reloadData()
                }
            case .getBands(let groups):
                DispatchQueue.main.async {
                    self.bands = groups
                    self.bandsTableView.reloadData()
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
                print(error)
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
        horizontalScrollView.contentSize.width = UIScreen.main.bounds.width * 4
    }

    func setup() {
        horizontalScrollView.delegate = self
        horizontalScrollView.backgroundColor = style.color.background.get()

        searchBar.barTintColor = style.color.background.get()
        searchBar.searchTextField.placeholder = "バンド・ライブを探す"
        searchBar.searchTextField.textColor = style.color.main.get()
        searchBar.delegate = self
        
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

        contentsView = UIView()
        contentsView.translatesAutoresizingMaskIntoConstraints = false
        contentsView.backgroundColor = style.color.background.get()

        contentsTableView = UITableView()
        contentsTableView.translatesAutoresizingMaskIntoConstraints = false
        contentsTableView.showsVerticalScrollIndicator = false
        contentsTableView.tableFooterView = UIView(frame: .zero)
        contentsTableView.separatorStyle = .none
        contentsTableView.backgroundColor = style.color.background.get()
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        contentsTableView.register(
            UINib(nibName: "BandContentsCell", bundle: nil),
            forCellReuseIdentifier: "BandContentsCell")

        contentsTableView.refreshControl = UIRefreshControl()
        contentsTableView.refreshControl?.addTarget(
            self, action: #selector(refreshContents(sender:)), for: .valueChanged)
        
        contentsPageTitleView = TitleLabelView(input: (title: "CONTENTS", font: style.font.xlarge.get(), color: style.color.main.get()))
        contentsPageTitleView.translatesAutoresizingMaskIntoConstraints = false
        contentsPageButton = UIButton()
        contentsPageButton.translatesAutoresizingMaskIntoConstraints = false

        liveView = UIView()
        liveView.translatesAutoresizingMaskIntoConstraints = false
        liveView.backgroundColor = style.color.background.get()

        liveTableView = UITableView()
        liveTableView.translatesAutoresizingMaskIntoConstraints = false
        liveTableView.showsVerticalScrollIndicator = false
        liveTableView.tableFooterView = UIView(frame: .zero)
        liveTableView.separatorStyle = .none
        liveTableView.backgroundColor = style.color.background.get()
        liveTableView.delegate = self
        liveTableView.dataSource = self
        liveTableView.register(
            UINib(nibName: "LiveCell", bundle: nil), forCellReuseIdentifier: "LiveCell")

        liveTableView.refreshControl = UIRefreshControl()
        liveTableView.refreshControl?.addTarget(
            self, action: #selector(refreshLive(sender:)), for: .valueChanged)
        
        livePageTitleView = TitleLabelView(input: (title: "LIVE", font: style.font.regular.get(), color: style.color.main.get()))
        livePageTitleView.translatesAutoresizingMaskIntoConstraints = false
        livePageButton = UIButton()
        livePageButton.translatesAutoresizingMaskIntoConstraints = false

        chartsView = UIView()
        chartsView.translatesAutoresizingMaskIntoConstraints = false
        chartsView.backgroundColor = style.color.background.get()

        chartsTableView = UITableView()
        chartsTableView.translatesAutoresizingMaskIntoConstraints = false
        chartsTableView.showsVerticalScrollIndicator = false
        chartsTableView.backgroundColor = style.color.background.get()
        chartsTableView.tableFooterView = UIView(frame: .zero)
        chartsTableView.separatorStyle = .none
        chartsTableView.delegate = self
        chartsTableView.dataSource = self
        chartsTableView.register(
            UINib(nibName: "TrackCell", bundle: nil), forCellReuseIdentifier: "TrackCell")

        chartsTableView.refreshControl = UIRefreshControl()
        chartsTableView.refreshControl?.addTarget(
            self, action: #selector(refreshChart(sender:)), for: .valueChanged)

        bandsView = UIView()
        bandsView.translatesAutoresizingMaskIntoConstraints = false
        bandsView.backgroundColor = style.color.background.get()
        
        chartsPageTitleView = TitleLabelView(input: (title: "CHARTS", font: style.font.regular.get(), color: style.color.main.get()))
        chartsPageTitleView.translatesAutoresizingMaskIntoConstraints = false
        chartsPageButton = UIButton()
        chartsPageButton.translatesAutoresizingMaskIntoConstraints = false

        bandsTableView = UITableView()
        bandsTableView.translatesAutoresizingMaskIntoConstraints = false
        bandsTableView.showsVerticalScrollIndicator = false
        bandsTableView.tableFooterView = UIView(frame: .zero)
        bandsTableView.separatorStyle = .none
        bandsTableView.backgroundColor = style.color.background.get()
        bandsTableView.delegate = self
        bandsTableView.dataSource = self
        bandsTableView.register(
            UINib(nibName: "BandCell", bundle: nil), forCellReuseIdentifier: "BandCell")

        bandsTableView.refreshControl = UIRefreshControl()
        bandsTableView.refreshControl?.addTarget(
            self, action: #selector(refreshBand(sender:)), for: .valueChanged)
        
        bandsPageTitleView = TitleLabelView(input: (title: "BANDS", font: style.font.regular.get(), color: style.color.main.get()))
        bandsPageTitleView.translatesAutoresizingMaskIntoConstraints = false
        bandsPageButton = UIButton()
        bandsPageButton.translatesAutoresizingMaskIntoConstraints = false
        
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
            pageStackView.topAnchor.constraint(equalTo: self.searchBar.bottomAnchor, constant: 16),
            pageStackView.heightAnchor.constraint(equalToConstant: 40),

            iconMenu.customView!.widthAnchor.constraint(equalToConstant: 40),
            iconMenu.customView!.heightAnchor.constraint(equalToConstant: 40),
        ]
        NSLayoutConstraint.activate(constraints)
        initializeItems()
    }
    
    private func setupPages() {
        pageItems = [
            PageItem(page: contentsView, pageButton: contentsPageButton, tebleView: contentsTableView, pageTitle: contentsPageTitleView),
            PageItem(page: liveView, pageButton: livePageButton, tebleView: liveTableView, pageTitle: livePageTitleView),
            PageItem(page: chartsView, pageButton: chartsPageButton, tebleView: chartsTableView, pageTitle: chartsPageTitleView),
            PageItem(page: bandsView, pageButton: bandsPageButton, tebleView: bandsTableView, pageTitle: bandsPageTitleView),
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

        createContentsView = CreateButton(input: UIImage(named: "music")!)
        createContentsView.layer.cornerRadius = 30
        createContentsView.translatesAutoresizingMaskIntoConstraints = false
        createContentsView.listen {
            self.createContents()
        }
        creationView.addSubview(createContentsView)

        createContentsViewBottomConstraint = NSLayoutConstraint(
            item: createContentsView!,
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
            createContentsViewBottomConstraint,
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

            createContentsView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
            createContentsView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
            createContentsView.heightAnchor.constraint(equalTo: creationView.widthAnchor),

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
        viewModel.getLives()
        viewModel.getGroups()
        viewModel.getCharts()
    }

    @objc private func refreshContents(sender: UIRefreshControl) {
        sender.endRefreshing()
    }

    @objc private func refreshLive(sender: UIRefreshControl) {
        viewModel.getLives()
        sender.endRefreshing()
    }

    @objc private func refreshChart(sender: UIRefreshControl) {
        viewModel.getCharts()
        sender.endRefreshing()
    }

    @objc private func refreshBand(sender: UIRefreshControl) {
        viewModel.getGroups()
        sender.endRefreshing()
    }

    func requestNotification() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [
                    .alert, .sound, .badge,
                ]) {
                    granted, error in
                    if let error = error {
                        print(error)
                        return
                    }
                    guard granted else { return }

                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
    }

    func createContents() {
        let vc = PostViewController(dependencyProvider: self.dependencyProvider, input: ())
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func createLive() {
        let vc = CreateLiveViewController(dependencyProvider: self.dependencyProvider, input: ())
        self.navigationController?.pushViewController(vc, animated: true)
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
        case self.contentsTableView:
            return 10
        case self.liveTableView:
            return self.lives.count
        case self.chartsTableView:
            return self.charts.count
        case self.bandsTableView:
            return self.bands.count
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
        case self.contentsTableView:
            return 200
        case self.liveTableView:
            return 300
        case self.chartsTableView:
            return 400
        case self.bandsTableView:
            return 250
        default:
            return 100
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case self.contentsTableView:
            let cell = tableView.reuse(BandContentsCell.self, input: (), for: indexPath)
            return cell
        case self.liveTableView:
            let live = self.lives[indexPath.section].live
            let cell = tableView.reuse(LiveCell.self, input: live, for: indexPath)
            cell.listen { [weak self] in
                self?.listenButtonTapped(cellIndex: indexPath.section)
            }
            cell.buyTicket { [weak self] in
                self?.buyTicketButtonTapped(cellIndex: indexPath.section)
            }
            return cell
        case self.chartsTableView:
            let chart = self.charts[indexPath.section]
            let cell = tableView.reuse(TrackCell.self, input: chart, for: indexPath)
            return cell
        case self.bandsTableView:
            let band = self.bands[indexPath.section]
            let cell = tableView.reuse(BandCell.self, input: band, for: indexPath)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case self.bandsTableView:
            let band = self.bands[indexPath.section]
            let vc = BandDetailViewController(
                dependencyProvider: self.dependencyProvider, input: band)
            self.navigationController?.pushViewController(vc, animated: true)
        case self.liveTableView:
            let live = self.lives[indexPath.section].live
            let vc = LiveDetailViewController(
                dependencyProvider: self.dependencyProvider, input: live)
            self.navigationController?.pushViewController(vc, animated: true)
        case self.contentsTableView:
            let url = URL(string: "https://youtu.be/T_27VmK1vmc")
            if let url = url {
                let safari = SFSafariViewController(url: url)
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
                font: style.font.xlarge.get(), color: style.color.main.get())
            titleViews.remove(at: pageIndex)
            titleViews.forEach {
                $0.changeStyle(font: style.font.regular.get(), color: style.color.main.get())
            }
            pageTitleStackViewLeadingConstraint.constant = CGFloat(
                16 - (scrollView.contentOffset.x / UIScreen.main.bounds.width * 60))
        }
    }
}

extension BandViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

        let vc = SearchViewController(
            dependencyProvider: self.dependencyProvider.provider, input: ())
        self.navigationController?.pushViewController(vc, animated: true)
        searchBar.endEditing(true)
    }
}

extension BandViewController: UNUserNotificationCenterDelegate {

}
