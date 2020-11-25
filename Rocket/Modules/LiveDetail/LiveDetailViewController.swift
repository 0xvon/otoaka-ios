//
//  LiveDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/24.
//

import UIKit
import Endpoint

final class LiveDetailViewController: UIViewController, Instantiable {
    
    typealias Input = Live
    
    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input
    @IBOutlet weak var liveDetailHeader: LiveDetailHeaderView!
    @IBOutlet weak var likeButtonView: ReactionButtonView!
    @IBOutlet weak var commentButtonView: ReactionButtonView!
    @IBOutlet weak var buyTicketButtonView: Button!
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var contentsTableView: UITableView!
    
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
        scrollableView.backgroundColor = style.color.background.get()
        
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
        
        liveDetailHeader.inject(input: (dependencyProvider: self.dependencyProvider, live: self.input, groups: []))
        liveDetailHeader.pushToBandViewController = { [weak self] vc in
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        liveDetailHeader.listen = { [weak self] cellIndex in
            print("listen \(cellIndex) band")
        }
        liveDetailHeader.like = { [weak self] cellIndex in
            print("like \(cellIndex) band")
        }
        
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        contentsTableView.register(UINib(nibName: "BandContentsCell", bundle: nil), forCellReuseIdentifier: "BandContentsCell")
        contentsTableView.backgroundColor = style.color.background.get()
        
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
            
            createMessageView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
            createMessageView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
            createMessageView.heightAnchor.constraint(equalTo: creationView.widthAnchor),
            
            createShareView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
            createShareView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
            createShareView.heightAnchor.constraint(equalTo: creationView.widthAnchor),
            
            editLiveView.rightAnchor.constraint(equalTo: creationView.rightAnchor),
            editLiveView.widthAnchor.constraint(equalTo: creationView.widthAnchor),
            editLiveView.heightAnchor.constraint(equalTo: creationView.widthAnchor),
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
    
    func editLive() {
        let vc = EditLiveViewController(dependencyProvider: dependencyProvider, input: input)
        self.navigationController?.pushViewController(vc, animated: true)
        self.isOpened.toggle()
        self.open(isOpened: self.isOpened)
    }
    
    private func likeButtonTapped() {
        print("like")
    }
    
    private func commentButtonTapped() {
        print("comment")
    }
    
    private func buyTicketButtonTapped() {
        print("buy ticket")
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
        return tableView.reuse(BandContentsCell.self, input: (), for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc private func seeMoreContents(_ sender: UIButton) {
        print("see more")
    }
}
