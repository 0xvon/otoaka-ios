//
//  LiveBannerCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/10/15.
//

import DomainEntity
import UIKit
import ImagePipeline

class LiveBannerCellContent: UIButton {
    typealias Input = (
        live: Live,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case selfTapped
    }
    
    private lazy var thumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.opacity = 0.3
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    private lazy var liveTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .mediumStrong)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .small)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.5 : 1.0 }
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func inject(input: Input) {
        if let url = input.live.artworkURL {
            input.imagePipeline.loadImage(url, into: thumbnailView)
        } else {
            thumbnailView.image = Brand.color(for: .background(.secondary)).image
        }
        liveTitleLabel.text = input.live.title
        switch input.live.style {
        case .oneman(let group):
            self.groupNameLabel.text = group.name
        case .battle(let groups):
            self.groupNameLabel.text = groups[0].name + "..."
        case .festival(let groups):
            self.groupNameLabel.text = groups[0].name + "..."
        }
    }
    
    func prepare() {
        thumbnailView.image = nil
    }
    
    func setup() {
        backgroundColor = .clear
        
        addSubview(thumbnailView)
        NSLayoutConstraint.activate([
            thumbnailView.rightAnchor.constraint(equalTo: rightAnchor),
            thumbnailView.leftAnchor.constraint(equalTo: leftAnchor),
            thumbnailView.topAnchor.constraint(equalTo: topAnchor),
            thumbnailView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        addSubview(liveTitleLabel)
        NSLayoutConstraint.activate([
            liveTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            liveTitleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            liveTitleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
        ])
        
        addSubview(groupNameLabel)
        NSLayoutConstraint.activate([
            groupNameLabel.topAnchor.constraint(equalTo: liveTitleLabel.bottomAnchor),
            groupNameLabel.leftAnchor.constraint(equalTo: liveTitleLabel.leftAnchor),
            groupNameLabel.rightAnchor.constraint(equalTo: liveTitleLabel.rightAnchor),
        ])
    }
}
