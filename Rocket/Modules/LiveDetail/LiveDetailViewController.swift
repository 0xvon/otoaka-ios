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
    @IBOutlet weak var liveDetailHeader: UIView!
    @IBOutlet weak var likeButtonView: ReactionButtonView!
    @IBOutlet weak var commentButtonView: ReactionButtonView!
    @IBOutlet weak var buyTicketButtonView: Button!
    @IBOutlet weak var scrollableView: UIView!
    
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

