//
//  BandDetailHeaderView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import UIKit

final class BandDetailHeaderView: UIView {
    typealias Input = DependencyProvider
    
    var input: Input!
    
    private var horizontalScrollView: UIScrollView!
    private var bandInformationView: UIView!
    private var trackInformationView: UIView!
    private var bandNameLabel: UILabel!
    private var mapBadgeView: BadgeView!
    private var dateBadgeView: BadgeView!
    private var productionBadgeView: BadgeView!
    private var labelBadgeView: BadgeView!
    private var bandImageView: UIImageView!
    private var arrowButton: UIButton!
    
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
        
        bandImageView = UIImageView()
        bandImageView.translatesAutoresizingMaskIntoConstraints = false
        bandImageView.image = UIImage(named: "jacket")
        bandImageView.contentMode = .scaleAspectFill
        bandImageView.layer.opacity = 0.6
        addSubview(bandImageView)
        
        horizontalScrollView = UIScrollView()
        horizontalScrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalScrollView)
        horizontalScrollView.isPagingEnabled = true
        horizontalScrollView.isScrollEnabled = true
        horizontalScrollView.showsHorizontalScrollIndicator = false
        horizontalScrollView.showsVerticalScrollIndicator = false
        horizontalScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width * 2, height: self.frame.height)
        horizontalScrollView.delegate = self
        
        bandInformationView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: self.frame.height))
        bandInformationView.backgroundColor = .clear
        horizontalScrollView.addSubview(bandInformationView)
        
        trackInformationView = UIView(frame: CGRect(x: UIScreen.main.bounds.width, y: 0, width: UIScreen.main.bounds.width, height: self.bounds.height))
        trackInformationView.backgroundColor = .blue
        horizontalScrollView.addSubview(trackInformationView)
        
        bandNameLabel = UILabel()
        bandNameLabel.translatesAutoresizingMaskIntoConstraints = false
        bandNameLabel.text = "MY FIRST STORY"
        bandNameLabel.font = style.font.xlarge.get()
        bandNameLabel.textColor = style.color.main.get()
        bandNameLabel.lineBreakMode = .byWordWrapping
        bandNameLabel.numberOfLines = 0
        bandNameLabel.adjustsFontSizeToFitWidth = false
        bandNameLabel.sizeToFit()
        bandInformationView.addSubview(bandNameLabel)
        
        dateBadgeView = BadgeView(input: (text: "2011年", image: UIImage(named: "calendar")))
        bandInformationView.addSubview(dateBadgeView)
        
        mapBadgeView = BadgeView(input: (text: "東京", image: UIImage(named: "map")))
        bandInformationView.addSubview(mapBadgeView)
        
        labelBadgeView = BadgeView(input: (text: "Intact Records", image: UIImage(named: "record")))
        bandInformationView.addSubview(labelBadgeView)
        
        productionBadgeView = BadgeView(input: (text: "Japan Music Systems", image: UIImage(named: "production")))
        bandInformationView.addSubview(productionBadgeView)
        
        arrowButton = UIButton()
        arrowButton.translatesAutoresizingMaskIntoConstraints = false
        arrowButton.contentMode = .scaleAspectFit
        arrowButton.contentHorizontalAlignment = .fill
        arrowButton.contentVerticalAlignment = .fill
        arrowButton.setImage(UIImage(named: "arrow"), for: .normal)
        arrowButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)
        bandInformationView.addSubview(arrowButton)
        
        let constraints = [
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftAnchor.constraint(equalTo: contentView.leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),
            
            bandImageView.topAnchor.constraint(equalTo: topAnchor),
            bandImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bandImageView.leftAnchor.constraint(equalTo: leftAnchor),
            bandImageView.rightAnchor.constraint(equalTo: rightAnchor),
            
            horizontalScrollView.topAnchor.constraint(equalTo: topAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalScrollView.leftAnchor.constraint(equalTo: leftAnchor),
            horizontalScrollView.rightAnchor.constraint(equalTo: rightAnchor),
            
            bandNameLabel.topAnchor.constraint(equalTo: bandInformationView.topAnchor, constant: 16),
            bandNameLabel.leftAnchor.constraint(equalTo: bandInformationView.leftAnchor, constant: 16),
            bandNameLabel.rightAnchor.constraint(equalTo: bandInformationView.rightAnchor, constant: -16),
            
            dateBadgeView.bottomAnchor.constraint(equalTo: bandInformationView.bottomAnchor, constant: -16),
            dateBadgeView.leftAnchor.constraint(equalTo: bandInformationView.leftAnchor, constant: 16),
            dateBadgeView.widthAnchor.constraint(equalToConstant: 160),
            dateBadgeView.heightAnchor.constraint(equalToConstant: 30),
            
            mapBadgeView.bottomAnchor.constraint(equalTo: dateBadgeView.topAnchor, constant: -8),
            mapBadgeView.leftAnchor.constraint(equalTo: bandInformationView.leftAnchor, constant: 16),
            mapBadgeView.widthAnchor.constraint(equalToConstant: 160),
            mapBadgeView.heightAnchor.constraint(equalToConstant: 30),
            
            labelBadgeView.bottomAnchor.constraint(equalTo: mapBadgeView.topAnchor, constant: -8),
            labelBadgeView.leftAnchor.constraint(equalTo: bandInformationView.leftAnchor, constant: 16),
            labelBadgeView.widthAnchor.constraint(equalToConstant: 160),
            labelBadgeView.heightAnchor.constraint(equalToConstant: 30),
            
            productionBadgeView.bottomAnchor.constraint(equalTo: labelBadgeView.topAnchor, constant: -8),
            productionBadgeView.leftAnchor.constraint(equalTo: bandInformationView.leftAnchor, constant: 16),
            productionBadgeView.widthAnchor.constraint(equalToConstant: 160),
            productionBadgeView.heightAnchor.constraint(equalToConstant: 30),
            
            arrowButton.rightAnchor.constraint(equalTo: bandInformationView.rightAnchor, constant: -16),
            arrowButton.bottomAnchor.constraint(equalTo: bandInformationView.bottomAnchor, constant: -16),
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

extension BandDetailHeaderView: UIScrollViewDelegate {
}
