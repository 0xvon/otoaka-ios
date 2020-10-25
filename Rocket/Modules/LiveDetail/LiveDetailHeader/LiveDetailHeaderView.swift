//
//  LiveDetailHeaderView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import UIKit

final class LiveDetailHeaderView: UIView {
    typealias Input = (
        text: String,
        image: UIImage?
    )
    
    var input: Input!
    
    private var horizontalScrollView: UIScrollView!
    private var liveInformationView: UIView!
    private var bandInformationView: UIView!
    private var liveTitleLabel: UILabel!
    private var bandNameLabel: UILabel!
    private var mapBadgeView: BadgeView!
    private var placeBadgeView: BadgeView!
    private var liveImageView: UIImageView!
    private var bandsTableView: UITableView!
    
    init(input: Input) {
        self.input = input
        super.init(frame: .zero)
        self.inject(input: input)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
        
    func inject(input: Input) {
        self.input = input
        self.setup()
    }
    
    func setup() {
        backgroundColor = .clear
        let contentView = UIView(frame: self.frame)
        addSubview(contentView)
        
        contentView.backgroundColor = .clear
        contentView.layer.opacity = 0.8
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        let constraints = [
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftAnchor.constraint(equalTo: contentView.leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),
            
            
            
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
