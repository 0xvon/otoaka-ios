//
//  CollectionListCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/22.
//

import DomainEntity
import UIKit
import ImagePipeline

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
        imageUrl: String?,
        imagePipeline: ImagePipeline
    )
    enum Output {
    }
    
    private lazy var thumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
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
        if let thumbnail = input.imageUrl, let url = URL(string: thumbnail) {
            input.imagePipeline.loadImage(url, into: thumbnailView)
        } else {
            thumbnailView.image = Brand.color(for: .background(.secondary)).image
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
    }
}
