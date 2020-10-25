//
//  LiveDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/24.
//

import UIKit

final class LiveDetailViewController: UIViewController, Instantiable {
    
    typealias Input = Live
    
    var dependencyProvider: DependencyProvider!
    var input: Input
    @IBOutlet weak var liveDetailHeader: LiveDetailHeaderView!
    @IBOutlet weak var likeButtonView: ReactionButtonView!
    @IBOutlet weak var commentButtonView: ReactionButtonView!
    @IBOutlet weak var buyTicketButtonView: Button!
    @IBOutlet weak var scrollableView: UIView!
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
            let titleView = TitleLabelView(input: "CONTENTS")
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 60 : 16
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.reuse(BandContentsCell.self, input: (), for: indexPath)
    }
    
    @objc private func seeMoreContents(_ sender: UIButton) {
        print("see more")
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct LiveDetailViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerWrapper<LiveDetailViewController>(
            dependencyProvider: .make(),
            input: Live(id: "123", title: "BANGOHAN TOUR 2020", type: .battles, host_id: "12345", open_at: "明日", start_at: "12時", end_at: "14時")
        )
    }
}

#endif

