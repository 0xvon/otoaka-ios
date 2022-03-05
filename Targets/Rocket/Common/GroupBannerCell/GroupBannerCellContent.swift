//
//  BandBannerCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import Endpoint
import UIKit
import ImagePipeline
import UIComponent

final class GroupBannerCell: UITableViewCell, ReusableCell {
    typealias Input = GroupBannerCellContent.Input
    typealias Output = GroupBannerCellContent.Output
    static var reusableIdentifier: String { "GroupBannerCell" }
    private let _contentView: GroupBannerCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = GroupBannerCellContent()
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(_contentView)
        _contentView.isUserInteractionEnabled = true
        backgroundColor = .clear
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            _contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            _contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 8),
            _contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -8),
        ])
        selectionStyle = .none
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func inject(input: Input) {
        _contentView.update(input: input)
    }
    func listen(_ listener: @escaping (Output) -> Void) {
        _contentView.listen(listener)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        alpha = highlighted ? 0.6 : 1.0
        _contentView.alpha = highlighted ? 0.6 : 1.0
    }
    
    override func prepareForReuse() {
        _contentView.prepare()
    }
}

class GroupBannerCellContent: UIButton {

    typealias Input = (
        group: GroupFeed,
        imagePipeline: ImagePipeline,
        type: GroupBannerCellContentType
    )
    enum GroupBannerCellContentType {
        case normal, select
    }
    public enum Output {
        case followTapped
        case selfTapped
    }
    private lazy var groupArtworkView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 24
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    private lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .largeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = false
        label.sizeToFit()
        return label
    }()
    private lazy var officialMark: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(
            UIImage(systemName: "checkmark.seal.fill")!.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal),
            for: .normal
        )
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 24),
            button.widthAnchor.constraint(equalTo: button.heightAnchor),
        ])
        return button
    }()
    private lazy var followButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 16
        button.isUserInteractionEnabled = true
        button.setTitle("スキ", selected: false)
        button.setTitle("スキ", selected: true)
        button.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
        button.isEnabled = false
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
        if let artworkURL = input.group.group.artworkURL {
            input.imagePipeline.loadImage(artworkURL, into: groupArtworkView)
        } else {
            groupArtworkView.image = Brand.color(for: .background(.milder)).image
        }
        groupNameLabel.text = input.group.group.name
        officialMark.isHidden = !input.group.isEntried
        
        followButton.isEnabled = true
        followButton.isSelected = input.group.isFollowing
        switch input.type {
        case .normal:
            followButton.isHidden = false
        case .select:
            followButton.isHidden = true
        }
    }
    
    func prepare() {
        groupArtworkView.image = nil
        groupNameLabel.text = nil
    }

    func setup() {
        backgroundColor = .clear
        
        addSubview(groupArtworkView)
        NSLayoutConstraint.activate([
            groupArtworkView.widthAnchor.constraint(equalToConstant: 48),
            groupArtworkView.heightAnchor.constraint(equalToConstant: 48),
            groupArtworkView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            groupArtworkView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            groupArtworkView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
        
        addSubview(groupNameLabel)
        NSLayoutConstraint.activate([
            groupNameLabel.topAnchor.constraint(equalTo: groupArtworkView.topAnchor),
            groupNameLabel.leftAnchor.constraint(equalTo: groupArtworkView.rightAnchor, constant: 8),
        ])
        
        officialMark.isHidden = true
        addSubview(officialMark)
        NSLayoutConstraint.activate([
            officialMark.topAnchor.constraint(equalTo: groupNameLabel.topAnchor),
            officialMark.leftAnchor.constraint(equalTo: groupNameLabel.rightAnchor, constant: 4),
        ])
        
        addSubview(followButton)
        NSLayoutConstraint.activate([
            followButton.topAnchor.constraint(equalTo: groupNameLabel.topAnchor),
            followButton.leftAnchor.constraint(greaterThanOrEqualTo: officialMark.rightAnchor, constant: 4),
            followButton.widthAnchor.constraint(equalToConstant: 130),
            followButton.heightAnchor.constraint(equalToConstant: 32),
            followButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
        ])
        
        addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
    
    @objc private func followTapped() {
        followButton.isSelected.toggle()
        self.listener(.followTapped)
    }
    
    @objc private func touchUpInside(_ sender: UIButton) {
        self.listener(.selfTapped)
    }
}
