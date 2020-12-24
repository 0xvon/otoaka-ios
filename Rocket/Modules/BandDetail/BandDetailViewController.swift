//
//  BandDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import Endpoint
import UIKit
import SafariServices

final class BandDetailViewController: UIViewController, Instantiable {
    typealias Input = Group
    
    enum UserType {
        case fan
        case group
        case member
    }

    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input!
    var lives: [Live] = []
    var feeds: [ArtistFeed] = []
    var groupItem: ChannelDetail.ChannelItem? = nil
    var isFollowing: Bool = false
    var followersCount: Int = 0
    var userType: UserType!

    @IBOutlet weak var headerView: BandDetailHeaderView!
    @IBOutlet weak var likeButtonView: ReactionButtonView!
    @IBOutlet weak var commentButtonView: ReactionButtonView!
    @IBOutlet weak var liveTableView: UITableView!
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
    private var createEditView: CreateButton!
    private var createEditViewBottomConstraint: NSLayoutConstraint!
    private var inviteCodeView: CreateButton!
    private var inviteCodeViewBottomConstraint: NSLayoutConstraint!
    private var creationButtonConstraintItems: [NSLayoutConstraint] = []

    lazy var viewModel = BandDetailViewModel(
        apiClient: dependencyProvider.apiClient,
        youTubeDataAPIClient: dependencyProvider.youTubeDataApiClient,
        auth: dependencyProvider.auth,
        group: self.input,
        outputHander: { output in
            switch output {
            case .getGroup(let response):
                DispatchQueue.main.async {
                    self.input = response.group
                    self.isFollowing = response.isFollowing
                    self.followersCount = response.followersCount
                    switch self.dependencyProvider.user.role {
                    case .fan(_):
                        self.userType = .fan
                    default:
                        self.userType = response.isMember ? .member : .group
                    }
                    self.setupLikeView()
                    self.setupCreation()
                    self.inject()
                }
            case .getChart(let items):
                DispatchQueue.main.async {
                    self.groupItem = items.first
                    self.inject()
                }
            case .getGroupLives(let lives):
                DispatchQueue.main.async {
                    self.lives = lives
                    self.liveTableView.reloadData()
                }
            case .getGroupFeeds(let feeds):
                DispatchQueue.main.async {
                    self.feeds = feeds
                    self.contentsTableView.reloadData()
                }
            case .follow:
                DispatchQueue.main.async {
                    self.isFollowing.toggle()
                    self.followersCount += 1
                    self.setupLikeView()
                    self.likeButtonColor()
                }
            case .unfollow:
                DispatchQueue.main.async {
                    self.isFollowing.toggle()
                    self.followersCount -= 1
                    self.setupLikeView()
                    self.likeButtonColor()
                }
            case .inviteGroup(let invitation):
                DispatchQueue.main.async {
                    self.showInviteCode(invitationCode: invitation.id)
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
        switch dependencyProvider.user.role {
        case .artist(_):
            self.userType = .member
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

    func setup() {
        view.backgroundColor = style.color.background.get()
        headerView.inject(input: (group: input, groupItem: self.groupItem))
        headerView.listen { listenType in
            switch listenType {
            case .play(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
                self.present(safari, animated: true, completion: nil)
            case .seeMoreCharts:
                let vc = ChartListViewController(dependencyProvider: self.dependencyProvider, input: self.input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .youtube(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
                self.present(safari, animated: true, completion: nil)
            case .twitter(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
                self.present(safari, animated: true, completion: nil)
            }
        }

        verticalScrollView.refreshControl = UIRefreshControl()
        verticalScrollView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)

        likeButtonView.inject(input: (text: "", image: UIImage(named: "heart")))
        likeButtonView.listen { type in
            switch type {
            case .reaction:
                self.likeButtonTapped()
            case .num:
                self.numOfLikeButtonTapped()
            }
            
        }

        commentButtonView.isHidden = true
        commentButtonView.inject(input: (text: "500", image: UIImage(named: "comment")))
        commentButtonView.listen { _ in
            self.commentButtonTapped()
        }

        liveTableView.delegate = self
        liveTableView.separatorStyle = .none
        liveTableView.dataSource = self
        liveTableView.backgroundColor = style.color.background.get()
        liveTableView.register(
            UINib(nibName: "LiveCell", bundle: nil), forCellReuseIdentifier: "LiveCell")
        liveTableView.tableFooterView = UIView(frame: .zero)
        viewModel.getGroup()
        viewModel.getGroupFeed()
        viewModel.getGroupLive()
        viewModel.getChart()

        contentsTableView.delegate = self
        contentsTableView.separatorStyle = .none
        contentsTableView.dataSource = self
        contentsTableView.backgroundColor = style.color.background.get()
        contentsTableView.tableFooterView = UIView(frame: .zero)
        contentsTableView.register(
            UINib(nibName: "BandContentsCell", bundle: nil),
            forCellReuseIdentifier: "BandContentsCell")
    }
    
    private func setupLikeView() {
        let image: UIImage = self.isFollowing ? UIImage(named: "heart_fill")! : UIImage(named: "heart")!
        self.likeButtonView.setItem(text: "\(self.followersCount)", image: image)
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
        case .member:
            createEditView = CreateButton(input: UIImage(named: "edit")!)
            createEditView.layer.cornerRadius = 30
            createEditView.translatesAutoresizingMaskIntoConstraints = false
            createEditView.listen {
                self.editGroup()
            }
            creationView.addSubview(createEditView)

            createEditViewBottomConstraint = NSLayoutConstraint(
                item: createEditView!,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: creationView,
                attribute: .bottom,
                multiplier: 1,
                constant: 0
            )
            
            inviteCodeView = CreateButton(input: UIImage(named: "invitation")!)
            inviteCodeView.layer.cornerRadius = 30
            inviteCodeView.translatesAutoresizingMaskIntoConstraints = false
            inviteCodeView.listen {
                self.inviteGroup()
            }
            creationView.addSubview(inviteCodeView)

            inviteCodeViewBottomConstraint = NSLayoutConstraint(
                item: inviteCodeView!,
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
                inviteCodeViewBottomConstraint,
                createEditViewBottomConstraint,
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
                
                createEditView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
                createEditView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
                createEditView.heightAnchor.constraint(equalTo: creationView.widthAnchor),
                
                inviteCodeView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
                inviteCodeView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
                inviteCodeView.heightAnchor.constraint(equalTo: creationView.widthAnchor),
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

            createMessageView = CreateButton(input: UIImage(named: "mail")!)
            createMessageView.layer.cornerRadius = 30
            createMessageView.translatesAutoresizingMaskIntoConstraints = false
            createMessageView.listen {
                self.createMessage()
            }
            creationView.addSubview(createMessageView)

            createMessageViewBottomConstraint = NSLayoutConstraint(
                item: createMessageView!,
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
                createMessageViewBottomConstraint,
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

                createMessageView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
                createMessageView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
                createMessageView.heightAnchor.constraint(equalTo: creationView.widthAnchor),

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

    func inject() {
        headerView.update(input: (group: input, groupItem: self.groupItem))
    }

    @objc private func refreshGroups(sender: UIRefreshControl) {
        viewModel.getGroup()
        viewModel.getGroupFeed()
        viewModel.getGroupLive()
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
    
    private func showInviteCode(invitationCode: String) {
        let alertController = UIAlertController(
            title: "招待コード", message: invitationCode, preferredStyle: UIAlertController.Style.alert)

        let cancelAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.cancel,
            handler: { action in
                print("close")
            })
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    func editGroup() {
        let vc = EditBandViewController(dependencyProvider: dependencyProvider, input: input)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func inviteGroup() {
        viewModel.inviteGroup(groupId: input.id)
    }

    func createMessage() {
        if let twitterId = input.twitterId {
            let safari = SFSafariViewController(url: URL(string: "https://twitter.com/\(twitterId)")!)
            safari.dismissButtonStyle = .close
            present(safari, animated: true, completion: nil)
        }
    }

    func createShare() {
        let shareLiveText: String = "\(input.name)がオススメだよ！！\n\n via @rocketforband "
        let shareUrl: NSURL = NSURL(string: "https://apps.apple.com/jp/app/id1500148347")!
        let shareImage: UIImage = UIImage(url: input.artworkURL!.absoluteString)
        
        let activityItems: [Any] = [shareLiveText, shareUrl, shareImage]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: [])
        
        self.present(activityViewController, animated: true, completion: nil)
    }

    func likeButtonColor() {

    }

    private func likeButtonTapped() {
        if self.isFollowing {
            viewModel.unfollowGroup()
        } else {
            viewModel.followGroup()
        }
    }
    
    private func numOfLikeButtonTapped() {
        let vc = UserListViewController(dependencyProvider: dependencyProvider, input: .followers(self.input.id))
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func commentButtonTapped() {
        print("comment")
    }
}

extension BandDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        switch tableView {
        case self.liveTableView:
            return 1
        case self.contentsTableView:
            return 1
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 60 : 16
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case self.liveTableView:
            return 300
        case self.contentsTableView:
            return 200
        default:
            return 100
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch tableView {
        case self.liveTableView:
            let view = UIView()
            let titleBaseView = UIView(frame: CGRect(x: 16, y: 16, width: 150, height: 40))
            let titleView = TitleLabelView(
                input: (title: "LIVE", font: style.font.xlarge.get(), color: style.color.main.get())
            )
            titleBaseView.addSubview(titleView)
            view.addSubview(titleBaseView)

            let seeMoreButton = UIButton(
                frame: CGRect(x: UIScreen.main.bounds.width - 132, y: 16, width: 100, height: 40))
            seeMoreButton.setTitle("もっと見る", for: .normal)
            seeMoreButton.setTitleColor(style.color.main.get(), for: .normal)
            seeMoreButton.titleLabel?.font = style.font.small.get()
            seeMoreButton.addTarget(self, action: #selector(seeMoreLive(_:)), for: .touchUpInside)
            view.addSubview(seeMoreButton)

            return view
        case self.contentsTableView:
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
            return UIView()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case self.liveTableView:
            if self.lives.isEmpty {
                let view = UITableViewCell()
                view.backgroundColor = .clear
                return view
            }
            let live = self.lives[indexPath.section]
            let cell = tableView.reuse(LiveCell.self, input: live, for: indexPath)
            return cell
        case self.contentsTableView:
            if self.feeds.isEmpty {
                let view = UITableViewCell()
                view.backgroundColor = .clear
                return view
            }
            let feed = self.feeds[indexPath.section]
            let cell = tableView.reuse(BandContentsCell.self, input: feed, for: indexPath)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case self.liveTableView:
            if self.lives.isEmpty { break }
            let live = self.lives[indexPath.section]
            let vc = LiveDetailViewController(
                dependencyProvider: self.dependencyProvider, input: live)
            self.navigationController?.pushViewController(vc, animated: true)
        case self.contentsTableView:
            if self.feeds.isEmpty { break }
            let feed = self.feeds[indexPath.section]
            switch feed.feedType {
            case .youtube(let url):
                let safari = SFSafariViewController(url: url)
                safari.dismissButtonStyle = .close
                present(safari, animated: true, completion: nil)
            }
        default:
            print("hello")
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc private func seeMoreLive(_ sender: UIButton) {
        let vc = LiveListViewController(dependencyProvider: self.dependencyProvider, input: .groupLive(self.input))
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func seeMoreContents(_ sender: UIButton) {
        let vc = GroupFeedListViewController(dependencyProvider: dependencyProvider, input: input)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

//extension BandDetailViewController: SFSafariViewControllerDelegate {
//    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
//        print("hello")
//    }
//}
