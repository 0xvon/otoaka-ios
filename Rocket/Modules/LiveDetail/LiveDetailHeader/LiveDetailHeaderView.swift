//
//  LiveDetailHeaderView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import UIKit

final class LiveDetailHeaderView: UIView {
    typealias Input = (
        live: Live,
        groups: [Group]
    )
    
    var input: Input!
    
    private var horizontalScrollView: UIScrollView!
    private var liveInformationView: UIView!
    private var bandInformationView: UIView!
    private var liveTitleLabel: UILabel!
    private var bandNameLabel: UILabel!
    private var mapBadgeView: BadgeView!
    private var dateBadgeView: BadgeView!
    private var liveImageView: UIImageView!
    private var arrowButton: UIButton!
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
        
        liveImageView = UIImageView()
        liveImageView.translatesAutoresizingMaskIntoConstraints = false
        liveImageView.image = UIImage(named: "live")
        liveImageView.contentMode = .scaleAspectFill
        liveImageView.layer.opacity = 0.6
        addSubview(liveImageView)
        
        horizontalScrollView = UIScrollView()
        horizontalScrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalScrollView)
        horizontalScrollView.isPagingEnabled = true
        horizontalScrollView.isScrollEnabled = true
        horizontalScrollView.showsHorizontalScrollIndicator = false
        horizontalScrollView.showsVerticalScrollIndicator = false
        horizontalScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width * 2, height: self.frame.height)
        horizontalScrollView.delegate = self
        
        liveInformationView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: self.frame.height))
        liveInformationView.backgroundColor = .clear
        horizontalScrollView.addSubview(liveInformationView)
        
        bandInformationView = UIView(frame: CGRect(x: UIScreen.main.bounds.width, y: 0, width: UIScreen.main.bounds.width, height: self.bounds.height))
        bandInformationView.backgroundColor = .clear
        horizontalScrollView.addSubview(bandInformationView)
        
        liveTitleLabel = UILabel()
        liveTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        liveTitleLabel.text = input.live.title
        liveTitleLabel.font = style.font.xlarge.get()
        liveTitleLabel.textColor = style.color.main.get()
        liveTitleLabel.lineBreakMode = .byWordWrapping
        liveTitleLabel.numberOfLines = 0
        liveTitleLabel.adjustsFontSizeToFitWidth = false
        liveTitleLabel.sizeToFit()
        liveInformationView.addSubview(liveTitleLabel)
        
        bandNameLabel = UILabel()
        bandNameLabel.translatesAutoresizingMaskIntoConstraints = false
        bandNameLabel.text = "masatojames, kateinoigakukun"
        bandNameLabel.font = style.font.regular.get()
        bandNameLabel.textColor = style.color.main.get()
        bandNameLabel.lineBreakMode = .byWordWrapping
        bandNameLabel.numberOfLines = 0
        bandNameLabel.adjustsFontSizeToFitWidth = false
        bandNameLabel.sizeToFit()
        liveInformationView.addSubview(bandNameLabel)
        
        dateBadgeView = BadgeView(input: (text: "明日18時", image: UIImage(named: "calendar")))
        liveInformationView.addSubview(dateBadgeView)
        
        mapBadgeView = BadgeView(input: (text: "代々木公演", image: UIImage(named: "map")))
        liveInformationView.addSubview(mapBadgeView)
        
        arrowButton = UIButton()
        arrowButton.translatesAutoresizingMaskIntoConstraints = false
        arrowButton.contentMode = .scaleAspectFit
        arrowButton.contentHorizontalAlignment = .fill
        arrowButton.contentVerticalAlignment = .fill
        arrowButton.setImage(UIImage(named: "arrow"), for: .normal)
        arrowButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)
        liveInformationView.addSubview(arrowButton)
        
        let constraints = [
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftAnchor.constraint(equalTo: contentView.leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),
            
            liveImageView.topAnchor.constraint(equalTo: topAnchor),
            liveImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            liveImageView.leftAnchor.constraint(equalTo: leftAnchor),
            liveImageView.rightAnchor.constraint(equalTo: rightAnchor),
            
            horizontalScrollView.topAnchor.constraint(equalTo: topAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalScrollView.leftAnchor.constraint(equalTo: leftAnchor),
            horizontalScrollView.rightAnchor.constraint(equalTo: rightAnchor),
            
            liveTitleLabel.topAnchor.constraint(equalTo: liveInformationView.topAnchor, constant: 16),
            liveTitleLabel.leftAnchor.constraint(equalTo: liveInformationView.leftAnchor, constant: 16),
            liveTitleLabel.rightAnchor.constraint(equalTo: liveInformationView.rightAnchor, constant: -16),
            
            bandNameLabel.topAnchor.constraint(equalTo: liveTitleLabel.bottomAnchor, constant: 8),
            bandNameLabel.leftAnchor.constraint(equalTo: liveInformationView.leftAnchor, constant: 16),
            bandNameLabel.rightAnchor.constraint(equalTo: liveInformationView.rightAnchor, constant: -16),
            
            dateBadgeView.bottomAnchor.constraint(equalTo: liveInformationView.bottomAnchor, constant: -16),
            dateBadgeView.leftAnchor.constraint(equalTo: liveInformationView.leftAnchor, constant: 16),
            dateBadgeView.widthAnchor.constraint(equalToConstant: 160),
            dateBadgeView.heightAnchor.constraint(equalToConstant: 30),
            
            mapBadgeView.bottomAnchor.constraint(equalTo: dateBadgeView.topAnchor, constant: -8),
            mapBadgeView.leftAnchor.constraint(equalTo: liveInformationView.leftAnchor, constant: 16),
            mapBadgeView.widthAnchor.constraint(equalToConstant: 160),
            mapBadgeView.heightAnchor.constraint(equalToConstant: 30),
            
            arrowButton.rightAnchor.constraint(equalTo: liveInformationView.rightAnchor, constant: -16),
            arrowButton.bottomAnchor.constraint(equalTo: liveInformationView.bottomAnchor, constant: -16),
            arrowButton.widthAnchor.constraint(equalToConstant: 54),
            arrowButton.heightAnchor.constraint(equalToConstant: 28),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc private func nextPage() {
        UIView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x += UIScreen.main.bounds.width
        }
    }
}

extension LiveDetailHeaderView: UIScrollViewDelegate {
}
