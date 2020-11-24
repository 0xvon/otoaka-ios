//
//  BandDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import UIKit
import Endpoint

final class BandDetailViewController: UIViewController, Instantiable {
    typealias Input = Group
    
    var dependencyProvider: DependencyProvider!
    var input: Input
    var lives: [Live] = []
    var isLiked: Bool = false
    
    @IBOutlet weak var headerView: BandDetailHeaderView!
    @IBOutlet weak var likeButtonView: ReactionButtonView!
    @IBOutlet weak var commentButtonView: ReactionButtonView!
    @IBOutlet weak var liveTableView: UITableView!
    @IBOutlet weak var contentsTableView: UITableView!
    
    private var isOpened: Bool = false
    private var creationView: UIView!
    private var creationViewHeightConstraint: NSLayoutConstraint!
    private var openButtonView: CreateButton!
    private var createMessageView: CreateButton!
    private var createMessageViewBottomConstraint: NSLayoutConstraint!
    private var createShareView: CreateButton!
    private var createShareViewBottomConstraint: NSLayoutConstraint!
    private var creationButtonConstraintItems: [NSLayoutConstraint] = []
    
    lazy var viewModel = BandDetailViewModel(
        apiClient: dependencyProvider.apiClient,
        auth: dependencyProvider.auth,
        group: self.input,
        outputHander: { output in
            switch output {
            case .follow:
                DispatchQueue.main.async {
                    self.isLiked.toggle()
                    self.likeButtonColor()
                }
            case .unfollow:
                DispatchQueue.main.async {
                    self.isLiked.toggle()
                    self.likeButtonColor()
                }
            case .error(let error):
                print(error)
            }
        }
    )
    
    init(dependencyProvider: DependencyProvider, input: Input) {
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
        setupCreation()
    }
    
    func setup() {
        view.backgroundColor = style.color.background.get()
        headerView.inject(input: self.dependencyProvider)
        
        likeButtonView.inject(input: (text: "10,000", image: UIImage(named: "heart")))
        likeButtonView.listen {
            self.likeButtonTapped()
        }
        
        commentButtonView.inject(input: (text: "500", image: UIImage(named: "comment")))
        commentButtonView.listen {
            self.commentButtonTapped()
        }
        
        liveTableView.delegate = self
        liveTableView.dataSource = self
        liveTableView.backgroundColor = style.color.background.get()
        liveTableView.register(UINib(nibName: "LiveCell", bundle: nil), forCellReuseIdentifier: "LiveCell")
        
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        contentsTableView.backgroundColor = style.color.background.get()
        contentsTableView.register(UINib(nibName: "BandContentsCell", bundle: nil), forCellReuseIdentifier: "BandContentsCell")
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
            
            creationViewHeightConstraint.constant = CGFloat(60 + 76 * creationButtonConstraintItems.count)
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
        print("create share")
    }
    
    func likeButtonColor() {
        
    }
    
    private func likeButtonTapped() {
        if self.isLiked {
            viewModel.unfollowGroup()
        } else {
            viewModel.followGroup()
        }
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
        return min(1, self.lives.count)
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
            let titleView = TitleLabelView(input: (title: "LIVE", font: style.font.xlarge.get(), color: style.color.main.get()))
            titleBaseView.addSubview(titleView)
            view.addSubview(titleBaseView)
            
            let seeMoreButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 132, y: 16, width: 100, height: 40))
            seeMoreButton.setTitle("もっと見る", for: .normal)
            seeMoreButton.setTitleColor(style.color.main.get(), for: .normal)
            seeMoreButton.titleLabel?.font = style.font.small.get()
            seeMoreButton.addTarget(self, action: #selector(seeMoreLive(_:)), for: .touchUpInside)
            view.addSubview(seeMoreButton)
            
            return view
        case self.contentsTableView:
            let view = UIView()
            let titleBaseView = UIView(frame: CGRect(x: 16, y: 16, width: 150, height: 40))
            let titleView = TitleLabelView(input: (title: "CONTENTS", font: style.font.xlarge.get(), color: style.color.main.get()))
            titleBaseView.addSubview(titleView)
            view.addSubview(titleBaseView)
            
            let seeMoreButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 132, y: 16, width: 100, height: 40))
            seeMoreButton.setTitle("もっと見る", for: .normal)
            seeMoreButton.setTitleColor(style.color.main.get(), for: .normal)
            seeMoreButton.titleLabel?.font = style.font.small.get()
            seeMoreButton.addTarget(self, action: #selector(seeMoreContents(_:)), for: .touchUpInside)
            view.addSubview(seeMoreButton)
            
            return view
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case self.liveTableView:
            let live = self.lives[indexPath.section]
            let cell = tableView.reuse(LiveCell.self, input: live, for: indexPath)
            return cell
        case self.contentsTableView:
            let cell = tableView.reuse(BandContentsCell.self, input: (), for: indexPath)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case self.liveTableView:
            let live = self.lives[indexPath.section]
            let vc = LiveDetailViewController(dependencyProvider: self.dependencyProvider, input: live)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            print("hello")
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc private func seeMoreLive(_ sender: UIButton) {
        print("see more live")
    }
    
    @objc private func seeMoreContents(_ sender: UIButton) {
        print("see more contents")
    }
    
}
