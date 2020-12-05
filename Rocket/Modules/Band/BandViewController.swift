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

    @IBOutlet weak var pageTitleStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentsPageTitleView: TitleLabelView!
    @IBOutlet weak var livePageTitleView: TitleLabelView!
    @IBOutlet weak var chartsPageTitleView: TitleLabelView!
    @IBOutlet weak var bandsPageTitleView: TitleLabelView!
    @IBOutlet weak var horizontalScrollView: UIScrollView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var contentsPageButton: UIButton!
    @IBOutlet weak var livePageButton: UIButton!
    @IBOutlet weak var chartsPageButton: UIButton!
    @IBOutlet weak var bandsPageButton: UIButton!

    private var contentsTableView: UITableView!
    private var liveTableView: UITableView!
    private var chartsTableView: UITableView!
    private var bandsTableView: UITableView!
    private var iconMenu: UIBarButtonItem!

    var lives: [Live] = []
    //    var contents = []
    var bands: [Group] = []

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
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getLives(let lives):
                DispatchQueue.main.async {
                    self.lives = lives
                    self.liveTableView.reloadData()
                }
            case .getBands(let groups):
                DispatchQueue.main.async {
                    self.bands = groups
                    self.bandsTableView.reloadData()
                }
            case .reserveTicket(let ticket):
                DispatchQueue.main.async {
                    if let index = self.lives.firstIndex(where: { $0.id == ticket.live.id }) {
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

        let contentsView = UIView()
        contentsView.translatesAutoresizingMaskIntoConstraints = false
        contentsView.backgroundColor = style.color.background.get()
        horizontalScrollView.addSubview(contentsView)

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
        contentsView.addSubview(contentsTableView)

        contentsTableView.refreshControl = UIRefreshControl()
        contentsTableView.refreshControl?.addTarget(
            self, action: #selector(refreshContents(sender:)), for: .valueChanged)

        let liveView = UIView()
        liveView.translatesAutoresizingMaskIntoConstraints = false
        liveView.backgroundColor = style.color.background.get()
        horizontalScrollView.addSubview(liveView)

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
        liveView.addSubview(liveTableView)

        liveTableView.refreshControl = UIRefreshControl()
        liveTableView.refreshControl?.addTarget(
            self, action: #selector(refreshLive(sender:)), for: .valueChanged)

        let chartsView = UIView()
        chartsView.translatesAutoresizingMaskIntoConstraints = false
        chartsView.backgroundColor = style.color.background.get()
        horizontalScrollView.addSubview(chartsView)

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
        chartsView.addSubview(chartsTableView)

        chartsTableView.refreshControl = UIRefreshControl()
        chartsTableView.refreshControl?.addTarget(
            self, action: #selector(refreshChart(sender:)), for: .valueChanged)

        let bandsView = UIView()
        bandsView.translatesAutoresizingMaskIntoConstraints = false
        bandsView.backgroundColor = style.color.background.get()
        horizontalScrollView.addSubview(bandsView)

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
        bandsView.addSubview(bandsTableView)

        bandsTableView.refreshControl = UIRefreshControl()
        bandsTableView.refreshControl?.addTarget(
            self, action: #selector(refreshBand(sender:)), for: .valueChanged)

        contentsPageTitleView.inject(
            input: (title: "CONTENTS", font: style.font.xlarge.get(), color: style.color.main.get())
        )
        contentsPageTitleView.bringSubviewToFront(contentsPageButton)
        livePageTitleView.inject(
            input: (title: "LIVE", font: style.font.regular.get(), color: style.color.main.get()))
        livePageTitleView.bringSubviewToFront(livePageButton)
        chartsPageTitleView.inject(
            input: (title: "CHARTS", font: style.font.regular.get(), color: style.color.main.get()))
        chartsPageTitleView.bringSubviewToFront(chartsPageButton)
        bandsPageTitleView.inject(
            input: (title: "BANDS", font: style.font.regular.get(), color: style.color.main.get()))
        bandsPageTitleView.bringSubviewToFront(bandsPageButton)

        let icon: UIButton = UIButton(type: .custom)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let image = UIImage(url: dependencyProvider.user.thumbnailURL!)
        icon.setImage(image, for: .normal)
        icon.addTarget(self, action: #selector(iconTapped(_:)), for: .touchUpInside)
        icon.imageView?.layer.cornerRadius = 20

        iconMenu = UIBarButtonItem(customView: icon)
        self.navigationItem.leftBarButtonItem = iconMenu

        let constraint = [
            contentsView.leftAnchor.constraint(equalTo: horizontalScrollView.leftAnchor),
            contentsView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
            contentsView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            contentsView.centerYAnchor.constraint(equalTo: horizontalScrollView.centerYAnchor),
            contentsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),

            liveView.leftAnchor.constraint(equalTo: contentsView.rightAnchor),
            liveView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
            liveView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            liveView.centerYAnchor.constraint(equalTo: horizontalScrollView.centerYAnchor),
            liveView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),

            chartsView.leftAnchor.constraint(equalTo: liveView.rightAnchor),
            chartsView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
            chartsView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            chartsView.centerYAnchor.constraint(equalTo: horizontalScrollView.centerYAnchor),
            chartsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),

            bandsView.leftAnchor.constraint(equalTo: chartsView.rightAnchor),
            bandsView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
            bandsView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
            bandsView.centerYAnchor.constraint(equalTo: horizontalScrollView.centerYAnchor),
            bandsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),

            contentsTableView.leftAnchor.constraint(equalTo: contentsView.leftAnchor, constant: 16),
            contentsTableView.rightAnchor.constraint(
                equalTo: contentsView.rightAnchor, constant: -16),
            contentsTableView.topAnchor.constraint(equalTo: contentsView.topAnchor, constant: 56),
            contentsTableView.bottomAnchor.constraint(
                equalTo: contentsView.bottomAnchor, constant: -16),

            liveTableView.leftAnchor.constraint(equalTo: liveView.leftAnchor, constant: 16),
            liveTableView.rightAnchor.constraint(equalTo: liveView.rightAnchor, constant: -16),
            liveTableView.topAnchor.constraint(equalTo: liveView.topAnchor, constant: 56),
            liveTableView.bottomAnchor.constraint(equalTo: liveView.bottomAnchor, constant: -16),

            chartsTableView.leftAnchor.constraint(equalTo: chartsView.leftAnchor, constant: 16),
            chartsTableView.rightAnchor.constraint(equalTo: chartsView.rightAnchor, constant: -16),
            chartsTableView.topAnchor.constraint(equalTo: chartsView.topAnchor, constant: 56),
            chartsTableView.bottomAnchor.constraint(
                equalTo: chartsView.bottomAnchor, constant: -16),

            bandsTableView.leftAnchor.constraint(equalTo: bandsView.leftAnchor, constant: 16),
            bandsTableView.rightAnchor.constraint(equalTo: bandsView.rightAnchor, constant: -16),
            bandsTableView.topAnchor.constraint(equalTo: bandsView.topAnchor, constant: 56),
            bandsTableView.bottomAnchor.constraint(equalTo: bandsView.bottomAnchor, constant: -16),

            iconMenu.customView!.widthAnchor.constraint(equalToConstant: 40),
            iconMenu.customView!.heightAnchor.constraint(equalToConstant: 40),
        ]
        NSLayoutConstraint.activate(constraint)
        initializeItems()
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
    }

    @objc private func refreshContents(sender: UIRefreshControl) {
        sender.endRefreshing()
    }

    @objc private func refreshLive(sender: UIRefreshControl) {
        viewModel.getLives()
        sender.endRefreshing()
    }

    @objc private func refreshChart(sender: UIRefreshControl) {
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

    @IBAction func contentsPageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = 0
        }
    }

    @IBAction func livePageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = UIScreen.main.bounds.width
        }
    }

    @IBAction func chartsPageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = UIScreen.main.bounds.width * 2
        }

    }

    @IBAction func bandsPageButtonTapped(_ sender: Any) {
        UIScrollView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x = UIScreen.main.bounds.width * 3
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
            return 10
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
            let live = self.lives[indexPath.section]
            let cell = tableView.reuse(LiveCell.self, input: live, for: indexPath)
            cell.listen { [weak self] in
                self?.listenButtonTapped(cellIndex: indexPath.section)
            }
            cell.buyTicket { [weak self] in
                self?.buyTicketButtonTapped(cellIndex: indexPath.section)
            }
            return cell
        case self.chartsTableView:
            let cell = tableView.reuse(TrackCell.self, input: (), for: indexPath)
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
            let live = self.lives[indexPath.section]
            let vc = LiveDetailViewController(
                dependencyProvider: self.dependencyProvider, input: live)
            self.navigationController?.pushViewController(vc, animated: true)
        case self.contentsTableView:
            let url = URL(string: "https://youtu.be/T_27VmK1vmc")
            if let url = url {
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
        let live = self.lives[cellIndex]
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
                ), 3)
            var titleViews: [TitleLabelView] = [
                contentsPageTitleView, livePageTitleView, chartsPageTitleView, bandsPageTitleView,
            ]
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
