//
//  CollectionListCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/22.
//

import Endpoint
import UIKit
import ImagePipeline
import UIComponent

final class CollectionListCell: UICollectionViewCell, ReusableCell {
    typealias Input = CollectionListCellContent.Input
    typealias Output = CollectionListCellContent.Output
    static var reusableIdentifier: String { "CollectionListCell" }
    private let _contentView: CollectionListCellContent
    override init(frame: CGRect) {
        _contentView = CollectionListCellContent()
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
    
    func inject(input: Input) {
        _contentView.inject(input: input)
    }
    
    override func prepareForReuse() {
        _contentView.prepare()
    }
    
    override var isHighlighted: Bool {
        didSet { _contentView.isHighlighted = isHighlighted }
    }
}

class CollectionListCellContent: UIButton {
    typealias Input = (
        post: PostSummary,
        imagePipeline: ImagePipeline
    )
    enum Output {
    }
    
    private lazy var thumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        imageView.alpha = 0.7
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private lazy var heartView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "heart")!
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private lazy var likeCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .xsmallStrong)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var liveTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .xxsmall)
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
        liveTitleLabel.text = input.post.live?.title
        switch input.post.live?.style {
        case .oneman(let group):
            self.groupNameLabel.text = group.name
        case .battle(let groups):
            self.groupNameLabel.text = groups[0].name + "..."
        case .festival(let groups):
            self.groupNameLabel.text = groups[0].name + "..."
        case .none:
            self.groupNameLabel.text = nil
        }
        likeCountLabel.text = String(input.post.likeCount)
        if let url = input.post.live?.artworkURL ?? input.post.live?.hostGroup.artworkURL {
            input.imagePipeline.loadImage(url, into: thumbnailView)
        } else {
            thumbnailView.image = Brand.color(for: .background(.light)).image
        }
    }
    
    func prepare() {
        liveTitleLabel.text = nil
        groupNameLabel.text = nil
        likeCountLabel.text = nil
        thumbnailView.image = nil
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
        
        addSubview(heartView)
        NSLayoutConstraint.activate([
            heartView.widthAnchor.constraint(equalToConstant: 20),
            heartView.heightAnchor.constraint(equalTo: heartView.widthAnchor),
            heartView.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -8),
            heartView.leftAnchor.constraint(equalTo: thumbnailView.leftAnchor, constant: 8),
        ])

        addSubview(likeCountLabel)
        NSLayoutConstraint.activate([
            likeCountLabel.centerYAnchor.constraint(equalTo: heartView.centerYAnchor),
            likeCountLabel.leftAnchor.constraint(equalTo: heartView.rightAnchor, constant: 4),
            likeCountLabel.rightAnchor.constraint(equalTo: thumbnailView.rightAnchor, constant: -8)
        ])
    }
}
