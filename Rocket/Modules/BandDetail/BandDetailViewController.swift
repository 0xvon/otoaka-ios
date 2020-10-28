//
//  BandDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import UIKit

final class BandDetailViewController: UIViewController, Instantiable {
    typealias Input = Void
    
    var dependencyProvider: DependencyProvider!
    var input: Input
    
    @IBOutlet weak var headerView: BandDetailHeaderView!
    @IBOutlet weak var likeButtonView: ReactionButtonView!
    @IBOutlet weak var commentButtonView: ReactionButtonView!
    @IBOutlet weak var liveTableView: UITableView!
    @IBOutlet weak var contentsTableView: UITableView!
    
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
    
    private func likeButtonTapped() {
        print("like")
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
        return 1
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
            let cell = tableView.reuse(LiveCell.self, input: Live(id: "xxx", title: "cxx", type: .battles, host_id: "xxx", open_at: "xx:xx", start_at: "xx:xx", end_at: "xx:xx"), for: indexPath)
            return cell
        case self.contentsTableView:
            let cell = tableView.reuse(BandContentsCell.self, input: (), for: indexPath)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    @objc private func seeMoreLive(_ sender: UIButton) {
        print("see more live")
    }
    
    @objc private func seeMoreContents(_ sender: UIButton) {
        print("see more contents")
    }
    
}
