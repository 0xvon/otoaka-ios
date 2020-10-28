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
    }
    
    private func likeButtonTapped() {
        print("like")
    }
    
    private func commentButtonTapped() {
        print("comment")
    }
}
