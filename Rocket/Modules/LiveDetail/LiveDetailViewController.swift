//
//  LiveDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/24.
//

import Endpoint
import UIKit
import SafariServices

final class LiveDetailViewController: UIViewController, Instantiable {

    typealias Input = (
        live: Live,
        ticket: Ticket?
    )
    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input!
    var isLiked: Bool!
    var participants: Int = 0
    enum UserType {
        case fan
        case group
        case performer
    }
    var userType: UserType!
    var performers: [Group] = []
    var feeds: [ArtistFeedSummary] = []
    
    @IBOutlet weak var liveDetailHeader: LiveDetailHeaderView!
    
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var verticalScrollView: UIScrollView!

    private var isOpened: Bool = false
    private var reactionStackView: UIStackView!
    private var likeButtonView: ReactionButtonView!
    private var commentButtonView: ReactionButtonView!
    private var buyTicketButtonView: PrimaryButton!
    private var numOfParticipantView: ReactionButtonView!
    private var contentsTableView: UITableView!
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
        live: input.live,
        outputHander: { output in
            switch output {
            case .getLive(let liveDetail):
                DispatchQueue.main.async {
                    self.input.live = liveDetail.live
                    self.input.ticket = liveDetail.ticket
                    self.isLiked = liveDetail.isLiked
                    self.participants = liveDetail.participants
                    self.input.ticket = liveDetail.ticket
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
                    self.input.ticket = ticket
                    self.participants += 1
                    self.inject()
                }
            case .refundTicket(let ticket):
                DispatchQueue.main.async {
                    self.input.ticket = ticket
                    self.participants -= 1
                    self.inject()
                }
            case .likeLive:
                DispatchQueue.main.async {
                    self.isLiked = true
                    self.inject()
                }
            case .unlikeLive:
                DispatchQueue.main.async {
                    self.isLiked = false
                    self.inject()
                }
            case .toggleFollow(let index):
                DispatchQueue.main.async {
                    print(index)
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )

    func setup() {
        view.backgroundColor = style.color.background.get()
        scrollableView.backgroundColor = style.color.background.get()
        
        verticalScrollView.refreshControl = UIRefreshControl()
        verticalScrollView.refreshControl?.addTarget(
            self, action: #selector(refreshLive(sender:)), for: .valueChanged)
        
        reactionStackView = UIStackView()
        reactionStackView.translatesAutoresizingMaskIntoConstraints = false
        reactionStackView.axis = .horizontal
        reactionStackView.distribution = .fill
        scrollableView.addSubview(reactionStackView)

        likeButtonView = ReactionButtonView(input: (text: "", image: nil))
        likeButtonView.translatesAutoresizingMaskIntoConstraints = false
//        likeButtonView.listen { type in
//            switch type {
//            case .reaction:
//                self.likeButtonTapped()
//            case .num:
//                self.numOfLikeButtonTapped()
//            }
//        }
        reactionStackView.addArrangedSubview(likeButtonView)
        
        commentButtonView = ReactionButtonView(input: (text: "", image: nil))
        commentButtonView.translatesAutoresizingMaskIntoConstraints = false
        reactionStackView.addArrangedSubview(commentButtonView)
//        commentButtonView.listen {
//            self.commentButtonTapped()
//        }

        buyTicketButtonView = PrimaryButton(text: "￥\(input.live.price)")
        buyTicketButtonView.setImage(UIImage(named: "ticket"), for: .normal)
        buyTicketButtonView.translatesAutoresizingMaskIntoConstraints = false
        buyTicketButtonView.layer.cornerRadius = 24
        buyTicketButtonView.listen {
            self.buyTicketButtonTapped()
        }
        reactionStackView.addArrangedSubview(buyTicketButtonView)
        
        numOfParticipantView = ReactionButtonView(input: (text: "", image: nil))
        numOfParticipantView.translatesAutoresizingMaskIntoConstraints = false
        numOfParticipantView.listen { _ in

            self.numOfParticipantsButtonTapped()
        }
        scrollableView.addSubview(numOfParticipantView)
        
        viewModel.getLive()
        viewModel.getGroupFeed(groupId: input.live.hostGroup.id)
        if self.userType != .fan {
            viewModel.getHostGroup()
        }
        
        injectPerformers()
        liveDetailHeader.inject(
            input: (dependencyProvider: self.dependencyProvider, live: self.input.live, groups: self.performers))
        liveDetailHeader.pushToBandViewController = { [weak self] vc in
            self?.navigationController?.pushViewController(vc, animated: true)
        }
//        liveDetailHeader.listen = { [weak self] cellIndex in
//            print("listen \(cellIndex) band")
//        }
        liveDetailHeader.like = { [weak self] cellIndex in
            self?.likeBand(cellIndex: cellIndex)
        }

        contentsTableView = UITableView(frame: .zero, style: .grouped)
        contentsTableView.translatesAutoresizingMaskIntoConstraints = false
        contentsTableView.delegate = self
        contentsTableView.separatorStyle = .none
        contentsTableView.isScrollEnabled = false
        contentsTableView.dataSource = self
        contentsTableView.register(
            UINib(nibName: "BandContentsCell", bundle: nil),
            forCellReuseIdentifier: "BandContentsCell")
        contentsTableView.backgroundColor = style.color.background.get()
        scrollableView.addSubview(contentsTableView)
                
        let constraints = [
            reactionStackView.topAnchor.constraint(equalTo: liveDetailHeader.bottomAnchor, constant: 12),
            reactionStackView.rightAnchor.constraint(equalTo: scrollableView.rightAnchor, constant: -16),
            reactionStackView.leftAnchor.constraint(equalTo: scrollableView.leftAnchor, constant: 16),
            
            likeButtonView.widthAnchor.constraint(equalToConstant: 80),
            
            commentButtonView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            buyTicketButtonView.widthAnchor.constraint(equalToConstant: 150),
            buyTicketButtonView.heightAnchor.constraint(equalToConstant: 48),
            
            numOfParticipantView.topAnchor.constraint(equalTo: reactionStackView.bottomAnchor, constant: 4),
            numOfParticipantView.widthAnchor.constraint(equalToConstant: 80),
            numOfParticipantView.heightAnchor.constraint(equalToConstant: 24),
            numOfParticipantView.centerXAnchor.constraint(equalTo: buyTicketButtonView.centerXAnchor),
            
            contentsTableView.leftAnchor.constraint(equalTo: scrollableView.leftAnchor, constant: 16),
            contentsTableView.rightAnchor.constraint(equalTo: scrollableView.rightAnchor, constant: -16),
            contentsTableView.topAnchor.constraint(equalTo: reactionStackView.bottomAnchor, constant: 48),
            contentsTableView.heightAnchor.constraint(equalToConstant: 360),
        ]
        NSLayoutConstraint.activate(constraints)

    }

    func inject() {
        self.ticketButtonStyle()
        self.injectPerformers()
        self.likeButtonViewStyle()
        self.setupCreation()
        liveDetailHeader.update(
            input: (dependencyProvider: self.dependencyProvider, live: self.input.live, groups: self.performers))
        numOfParticipantView.updateText(text: "\(self.participants)人予約済み")
    }
    
    func injectPerformers() {
        switch input.live.style {
        case .oneman(let performer):
            self.performers = [performer]
        case .battle(let performers):
            self.performers = performers
        case .festival(let performers):
            self.performers = performers
        }
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
        if let ticket = self.input.ticket {
            switch ticket.status {
            case .reserved:
                self.buyTicketButtonView.setTitle("予約済", for: .normal)
            case .refunded:
                self.buyTicketButtonView.setTitle("￥\(input.live.price)", for: .normal)
            }
        } else {
            self.buyTicketButtonView.setTitle("￥\(input.live.price)", for: .normal)
        }
    }
    
    private func numOfParticipantsButtonTapped() {
        let vc = UserListViewController(dependencyProvider: dependencyProvider, input: .tickets(input.live.id))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func likeButtonViewStyle() {
//        if self.isLiked {
//            self.likeButtonView.updateImage(image: UIImage(named: "heart_fill"))
//        } else {
//            self.likeButtonView.updateImage(image: UIImage(named: "heart"))
//        }
    }

    @objc private func refreshLive(sender: UIRefreshControl) {
        viewModel.getLive()
        viewModel.getHostGroup()
        viewModel.getGroupFeed(groupId: input.live.hostGroup.id)
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
        let shareLiveText: String = "\(input.live.hostGroup.name)主催の\(input.live.title)に集まれ！！\n\n via @rocketforband "
        let shareUrl: NSURL = NSURL(string: "https://apps.apple.com/jp/app/id1500148347")!
        let shareImage: UIImage = UIImage(url: input.live.artworkURL!.absoluteString)
        
        let activityItems: [Any] = [shareLiveText, shareUrl, shareImage]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: [])
        
        self.present(activityViewController, animated: true, completion: nil)
    }

    func editLive() {
        let vc = EditLiveViewController(dependencyProvider: dependencyProvider, input: input.live)
        self.navigationController?.pushViewController(vc, animated: true)
        self.isOpened.toggle()
        self.open(isOpened: self.isOpened)
    }
    
    private func likeBand(cellIndex: Int) {
        viewModel.followGroup(groupId: self.performers[cellIndex].id, cellIndex: cellIndex)
    }
    
    private func numOfLikeButtonTapped() {
//        let vc = UserListViewController(dependencyProvider: dependencyProvider, input: )
    }

    private func likeButtonTapped() {
        if isLiked {
            self.viewModel.unlikeLive()
        } else {
            self.viewModel.likeLive()
        }
    }

    private func commentButtonTapped() {
        print("comment")
    }

    private func buyTicketButtonTapped() {
        if let ticket = self.input.ticket, ticket.status == .reserved {
            viewModel.refundTicket(ticketId: ticket.id)
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
        return 1
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
        return 300
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 60 : 16
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.feeds.isEmpty {
            let view = UITableViewCell()
            view.backgroundColor = .clear
            return view
        }
        let feed = self.feeds[indexPath.section]
        let cell = tableView.reuse(BandContentsCell.self, input: feed, for: indexPath)
        cell.comment { [weak self] _ in
            self?.seeCommentButtonTapped()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !feeds.isEmpty {
            let content = self.feeds[indexPath.section]
            switch content.feedType {
            case .youtube(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
                present(safari, animated: true, completion: nil)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func seeCommentButtonTapped() {
        let feed = self.feeds[0]
        let vc = CommentListViewController(dependencyProvider: dependencyProvider, input: .feedComment(feed))
        present(vc, animated: true, completion: nil)
    }

    @objc private func seeMoreContents(_ sender: UIButton) {
        let vc = GroupFeedListViewController(dependencyProvider: dependencyProvider, input: input.live.hostGroup)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
