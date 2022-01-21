//
//  UserCaroucel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/01.
//

import Endpoint
import UIKit
import ImagePipeline

final class StoryCaroucel: UICollectionViewCell, ReusableCell {
    typealias Input = StoryCaroucelContent.Input
    typealias Output = StoryCaroucelContent.Output
    static var reusableIdentifier: String { "StoryCaroucel" }
    private let _contentView: StoryCaroucelContent
    override init(frame: CGRect) {
        _contentView = StoryCaroucelContent()
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

public final class StoryCaroucelContent: UIButton {
    public typealias Input = (
        imageUrl: URL?,
        imagePipeline: ImagePipeline
    )
    enum Output {
    }
    
    private lazy var thumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 25
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
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
        if let url = input.imageUrl {
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
