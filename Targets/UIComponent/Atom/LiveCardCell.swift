//
//  LiveCardCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/10/12.
//

import DomainEntity
import UIKit
import ImagePipeline

final class LiveCardCell: UICollectionViewCell, ReusableCell {
    typealias Input = LiveCardCellContent.Input
    typealias Output = LiveCardCellContent.Output
    static var reusableIdentifier: String { "LiveCardCell" }
    private let _contentView: LiveCardCellContent
    override init(frame: CGRect) {
        _contentView = LiveCardCellContent()
        super.init(frame: frame)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.isUserInteractionEnabled = false
        backgroundColor = .clear
        contentView.addSubview(_contentView)
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            _contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            _contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            _contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func inject(input: Input) {
        _contentView.inject(input: input)
    }
    
    public override func prepareForReuse() {
        _contentView.prepare()
    }
    
    override var isHighlighted: Bool {
        didSet { _contentView.isHighlighted = isHighlighted }
    }
}

public final class LiveCardCellContent: UIButton {
    public typealias Input = (
        live: Live,
        imagePipeline: ImagePipeline
    )
    enum Output {
    }
    
    private lazy var thumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    private lazy var liveTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .xsmallStrong)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .xxsmall)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    public override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.5 : 1.0 }
    }
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public func inject(input: Input) {
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
        liveTitleLabel.text = nil
        groupNameLabel.text = nil
    }
    
    func setup() {
        backgroundColor = .clear
        
        addSubview(thumbnailView)
        NSLayoutConstraint.activate([
            thumbnailView.rightAnchor.constraint(equalTo: rightAnchor),
            thumbnailView.leftAnchor.constraint(equalTo: leftAnchor),
            thumbnailView.topAnchor.constraint(equalTo: topAnchor),
        ])
        
        addSubview(liveTitleLabel)
        NSLayoutConstraint.activate([
            liveTitleLabel.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: 4),
            liveTitleLabel.leftAnchor.constraint(equalTo: leftAnchor),
            liveTitleLabel.rightAnchor.constraint(equalTo: rightAnchor),
            liveTitleLabel.heightAnchor.constraint(equalToConstant: 14.4)
        ])
        
        addSubview(groupNameLabel)
        NSLayoutConstraint.activate([
            groupNameLabel.topAnchor.constraint(equalTo: liveTitleLabel.bottomAnchor),
            groupNameLabel.leftAnchor.constraint(equalTo: leftAnchor),
            groupNameLabel.rightAnchor.constraint(equalTo: rightAnchor),
            groupNameLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            groupNameLabel.heightAnchor.constraint(equalToConstant: 13.4)
        ])
    }
}
