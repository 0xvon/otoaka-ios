//
//  LiveDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/24.
//

import Endpoint
import UIKit

final class LiveDetailViewController: UIViewController, Instantiable {

    typealias Input = Live
    var dependencyProvider: LoggedInDependencyProvider!
    var input: Live!
    var isLiked: Bool!
    var hasTicket: Bool!
    enum UserType {
        case fan
        case group
        case performer
    }
    var userType: UserType!
    var performers: [Group] = []
    var feeds: [GroupFeed] = []
    
    @IBOutlet weak var liveDetailHeader: LiveDetailHeaderView!
    @IBOutlet weak var likeButtonView: ReactionButtonView!
    @IBOutlet weak var commentButtonView: ReactionButtonView!
    @IBOutlet weak var buyTicketButtonView: Button!
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var contentsTableView: UITableView!
    @IBOutlet weak var verticalScrollView: UIScrollView!

    private var isOpened: Bool = false
    private var creationView: UIView!
    private var creationViewHeightConstraint: NSLayoutConstraint!
    private var openButtonView: CreateButton!
    private var createMessageView: CreateButton!
    private var createMessageViewBottomConstraint: NSLayoutConstraint!
    private var createShareView: CreateButton!
    private var createShareViewBottomConstraint: NSLayoutConstraint!
    private var editLiveView: CreateButton!
    private var editLiveViewBottomConstraint: NSLayoutConstraint!
    private var creationButtonConstraintItems: [NSLayoutConstraint] = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input
        self.isLiked = false
        self.hasTicket = false
        switch dependencyProvider.user.role {
        case .artist(_):
            self.userType = .group
        case .fan(_):
            self.userType = .fan
        }

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupCreation()
    }

    lazy var viewModel = LiveDetailViewModel(
        apiClient: dependencyProvider.apiClient,
        auth: dependencyProvider.auth,
        live: input,
        outputHander: { output in
            switch output {
            case .getLive(let liveDetail):
                DispatchQueue.main.async {
                    self.input = liveDetail.live
                    self.isLiked = liveDetail.isLiked
                    self.hasTicket = liveDetail.hasTicket
                    self.inject()
                }
            case .getGroupFeeds(let feeds):
                DispatchQueue.main.async {
                    self.feeds = feeds
                    self.contentsTableView.reloadData()
                }
            case .getHostGroup(let hostGroup):
                DispatchQueue.main.async {
                    self.userType = hostGroup.isMember ? .performer : self.userType
                    self.inject()
                }
            case .reserveTicket(let ticket):
                DispatchQueue.main.async {
                    self.hasTicket = true
                    self.inject()
                }
            case .likeLive:
                DispatchQueue.main.async {
                    self.isLiked = true
                    self.inject()
                }
            case .toggleFollow(let index):
                DispatchQueue.main.async {
                    print(index)
                }
            case .error(let error):
                print(error)
            }
        }
    )

    func setup() {
        view.backgroundColor = style.color.background.get()
        scrollableView.backgroundColor = style.color.background.get()
        
        verticalScrollView.refreshControl = UIRefreshControl()
        verticalScrollView.refreshControl?.addTarget(
            self, action: #selector(refreshLive(sender:)), for: .valueChanged)

        likeButtonView.inject(input: (text: "10000", image: UIImage(named: "heart")))
        likeButtonView.listen {
            self.likeButtonTapped()
        }

        commentButtonView.inject(input: (text: "500", image: UIImage(named: "comment")))
        commentButtonView.listen {
            self.commentButtonTapped()
        }

        buyTicketButtonView.inject(input: (text: "￥1,500", image: UIImage(named: "ticket")))
        buyTicketButtonView.listen {
            self.buyTicketButtonTapped()
        }
        
        viewModel.getLive()
        viewModel.getGroupFeed(groupId: input.hostGroup.id)
        if self.userType != .fan {
            viewModel.getHostGroup()
        }
        
        switch input.style {
        case .oneman(let performer):
            self.performers = [performer]
        case .battle(let performers):
            self.performers = performers
        case .festival(let performers):
            self.performers = performers
        }
        liveDetailHeader.inject(
            input: (dependencyProvider: self.dependencyProvider, live: self.input, groups: self.performers))
        liveDetailHeader.pushToBandViewController = { [weak self] vc in
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        liveDetailHeader.listen = { [weak self] cellIndex in
            print("listen \(cellIndex) band")
        }
        liveDetailHeader.like = { [weak self] cellIndex in
            self?.likeBand(cellIndex: cellIndex)
        }

        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        contentsTableView.register(
            UINib(nibName: "BandContentsCell", bundle: nil),
            forCellReuseIdentifier: "BandContentsCell")
        contentsTableView.backgroundColor = style.color.background.get()

    }

    func inject() {
        liveDetailHeader.update(
            input: (dependencyProvider: self.dependencyProvider, live: self.input, groups: []))
        self.ticketButtonStyle()
        self.likeButtonViewStyle()
        self.setupCreation()
    }

    private func setupCreation() {
        if let creationView = creationView {
            creationView.removeFromSuperview()
        }
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
        
        switch self.userType {
        case .performer:
            editLiveView = CreateButton(input: UIImage(named: "edit")!)
            editLiveView.layer.cornerRadius = 30
            editLiveView.translatesAutoresizingMaskIntoConstraints = false
            editLiveView.listen {
                self.editLive()
            }
            creationView.addSubview(editLiveView)

            editLiveViewBottomConstraint = NSLayoutConstraint(
                item: editLiveView!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: creationView,
                attribute: .bottom,
                multiplier: 1,
                constant: 0
            )
            
            createShareView = CreateButton(input: UIImage(named: "share")!)
            createShareView.layer.cornerRadius = 30
            createShareView.translatesAutoresizingMaskIntoConstraints = false
            createShareView.listen {
                self.createShare()
            }
            creationView.addSubview(createShareView)

            createShareViewBottomConstraint = NSLayoutConstraint(
                item: createShareView!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: creationView,
                attribute: .bottom,
                multiplier: 1,
                constant: 0
            )

//            createMessageView = CreateButton(input: UIImage(named: "mail")!)
//            createMessageView.layer.cornerRadius = 30
//            createMessageView.translatesAutoresizingMaskIntoConstraints = false
//            createMessageView.listen {
//                self.createMessage()
//            }
//            creationView.addSubview(createMessageView)

//            createMessageViewBottomConstraint = NSLayoutConstraint(
//                item: createMessageView!,
//                attribute: .bottom,
//                relatedBy: .equal,
//                toItem: creationView,
//                attribute: .bottom,
//                multiplier: 1,
//                constant: 0
//            )

            openButtonView = CreateButton(input: UIImage(named: "plus")!)
            openButtonView.layer.cornerRadius = 30
            openButtonView.translatesAutoresizingMaskIntoConstraints = false
            openButtonView.listen {
                self.isOpened.toggle()
                self.open(isOpened: self.isOpened)
            }
            creationView.addSubview(openButtonView)

            creationButtonConstraintItems = [
//                createMessageViewBottomConstraint,
                createShareViewBottomConstraint,
                editLiveViewBottomConstraint,
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

//                createMessageView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
//                createMessageView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
//                createMessageView.heightAnchor.constraint(equalTo: creationView.widthAnchor),

                createShareView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
                createShareView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
                createShareView.heightAnchor.constraint(equalTo: creationView.widthAnchor),
                
                editLiveView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
                editLiveView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
                editLiveView.heightAnchor.constraint(equalTo: creationView.widthAnchor),
            ]

            NSLayoutConstraint.activate(constraints)
        case .group:
            createShareView = CreateButton(input: UIImage(named: "share")!)
            createShareView.layer.cornerRadius = 30
            createShareView.translatesAutoresizingMaskIntoConstraints = false
            createShareView.listen {
                self.createShare()
            }
            creationView.addSubview(createShareView)

            createShareViewBottomConstraint = NSLayoutConstraint(
                item: createShareView!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: creationView,
                attribute: .bottom,
                multiplier: 1,
                constant: 0
            )

//            createMessageView = CreateButton(input: UIImage(named: "mail")!)
//            createMessageView.layer.cornerRadius = 30
//            createMessageView.translatesAutoresizingMaskIntoConstraints = false
//            createMessageView.listen {
//                self.createMessage()
//            }
//            creationView.addSubview(createMessageView)
//
//            createMessageViewBottomConstraint = NSLayoutConstraint(
//                item: createMessageView!,
//                attribute: .bottom,
//                relatedBy: .equal,
//                toItem: creationView,
//                attribute: .bottom,
//                multiplier: 1,
//                constant: 0
//            )

            openButtonView = CreateButton(input: UIImage(named: "plus")!)
            openButtonView.layer.cornerRadius = 30
            openButtonView.translatesAutoresizingMaskIntoConstraints = false
            openButtonView.listen {
                self.isOpened.toggle()
                self.open(isOpened: self.isOpened)
            }
            creationView.addSubview(openButtonView)

            creationButtonConstraintItems = [
//                createMessageViewBottomConstraint,
                createShareViewBottomConstraint,
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

//                createMessageView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
//                createMessageView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
//                createMessageView.heightAnchor.constraint(equalTo: creationView.widthAnchor),

                createShareView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
                createShareView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
                createShareView.heightAnchor.constraint(equalTo: creationView.widthAnchor),
            ]

            NSLayoutConstraint.activate(constraints)
        case .fan:
            createShareView = CreateButton(input: UIImage(named: "share")!)
            createShareView.layer.cornerRadius = 30
            createShareView.translatesAutoresizingMaskIntoConstraints = false
            createShareView.listen {
                self.createShare()
            }
            creationView.addSubview(createShareView)

            createShareViewBottomConstraint = NSLayoutConstraint(
                item: createShareView!,
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
                createShareViewBottomConstraint,
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

                createShareView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
                createShareView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
                createShareView.heightAnchor.constraint(equalTo: creationView.widthAnchor),
            ]

            NSLayoutConstraint.activate(constraints)
        case .none:
            break
        }
    }

    private func ticketButtonStyle() {
        if self.hasTicket {
            self.buyTicketButtonView.setText(text: "予約済")
        } else {
            self.buyTicketButtonView.setText(text: "￥1,500")
        }
    }
    
    private func likeButtonViewStyle() {
        if self.isLiked {
            self.likeButtonView.updateImage(image: UIImage(named: "heart_fill"))
        } else {
            self.likeButtonView.updateImage(image: UIImage(named: "heart"))
        }
    }

    @objc private func refreshLive(sender: UIRefreshControl) {
        viewModel.getLive()
        viewModel.getHostGroup()
        viewModel.getGroupFeed(groupId: input.hostGroup.id)
        sender.endRefreshing()
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

    func createMessage() {
        print("create message")
    }

    func createShare() {
        let shareLiveText: String = "\(input.hostGroup.name)主催の\(input.title)に集まれ！！\n\n via @rocketforband "
        let shareUrl: NSURL = NSURL(string: "https://apps.apple.com/jp/app/id1500148347")!
        let shareImage: UIImage = UIImage(url: input.artworkURL!.absoluteString)
        
        let activityItems: [Any] = [shareLiveText, shareUrl, shareImage]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: [])
        
        self.present(activityViewController, animated: true, completion: nil)
    }

    func editLive() {
        let vc = EditLiveViewController(dependencyProvider: dependencyProvider, input: input)
        self.navigationController?.pushViewController(vc, animated: true)
        self.isOpened.toggle()
        self.open(isOpened: self.isOpened)
    }
    
    private func likeBand(cellIndex: Int) {
        viewModel.followGroup(groupId: self.performers[cellIndex].id, cellIndex: cellIndex)
    }

    private func likeButtonTapped() {
        if isLiked {
            print("you already liked")
        } else {
            self.viewModel.likeLive()
        }
    }

    private func commentButtonTapped() {
        print("comment")
    }

    private func buyTicketButtonTapped() {
        if self.hasTicket {
            print("you already reserved ticket")
        } else {
            viewModel.reserveTicket()
        }
    }
}

extension LiveDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return min(1, self.feeds.count)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let view = UIView()
            let titleBaseView = UIView(frame: CGRect(x: 16, y: 16, width: 150, height: 40))
            let titleView = TitleLabelView(
                input: (
                    title: "CONTENTS", font: style.font.xlarge.get(), color: style.color.main.get()
                ))
            titleBaseView.addSubview(titleView)
            view.addSubview(titleBaseView)

            let seeMoreButton = UIButton(
                frame: CGRect(x: UIScreen.main.bounds.width - 132, y: 16, width: 100, height: 40))
            seeMoreButton.setTitle("もっと見る", for: .normal)
            seeMoreButton.setTitleColor(style.color.main.get(), for: .normal)
            seeMoreButton.titleLabel?.font = style.font.small.get()
            seeMoreButton.addTarget(
                self, action: #selector(seeMoreContents(_:)), for: .touchUpInside)
            view.addSubview(seeMoreButton)

            return view
        default:
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 60 : 16
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let feed = self.feeds[indexPath.section]
        return tableView.reuse(BandContentsCell.self, input: feed, for: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc private func seeMoreContents(_ sender: UIButton) {
        let vc = BandContentsListViewController(dependencyProvider: dependencyProvider, input: input.hostGroup)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
