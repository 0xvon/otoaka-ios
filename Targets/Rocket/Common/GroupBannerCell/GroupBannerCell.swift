//
//  BandBannerCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import DomainEntity
import UIKit

class GroupBannerCell: UIView {

    typealias Input = Group
    private lazy var groupArtworkView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    private lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .largeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = false
        label.sizeToFit()
        return label
    }()
    private lazy var button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        return button
    }()
    
    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func update(input: Input) {
        groupArtworkView.loadImageAsynchronously(url: input.artworkURL)
        groupNameLabel.text = input.name
    }

    func setup() {
        backgroundColor = .clear
        
        addSubview(groupArtworkView)
        NSLayoutConstraint.activate([
            groupArtworkView.widthAnchor.constraint(equalToConstant: 60),
            groupArtworkView.heightAnchor.constraint(equalToConstant: 60),
            groupArtworkView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            groupArtworkView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            groupArtworkView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
        
        addSubview(groupNameLabel)
        NSLayoutConstraint.activate([
            groupNameLabel.topAnchor.constraint(equalTo: groupArtworkView.topAnchor),
            groupNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            groupNameLabel.leftAnchor.constraint(equalTo: groupArtworkView.rightAnchor, constant: 8),
        ])
        
        addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.rightAnchor.constraint(equalTo: rightAnchor),
            button.leftAnchor.constraint(equalTo: leftAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
    
    @objc private func touchUpInside(_ sender: UIButton) {
        self.listener()
    }
}
