//
//  PartyCollectionView.swift
//  UIComponent
//
//  Created by Masato TSUTSUMI on 2022/02/15.
//

import UIKit
import ImagePipeline
import Endpoint

public final class PartyCollectionView: UICollectionView {
    public var items: [GroupFeed]
    public var imagePipeline: ImagePipeline
    
    public init(items: [GroupFeed], imagePipeline: ImagePipeline) {
        self.items = items
        self.imagePipeline = imagePipeline
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        super.init(frame: .zero, collectionViewLayout: layout)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func inject(items: [GroupFeed]) {
        self.items = items
        reloadData()
    }
    
    func setup() {
        backgroundColor = .clear
        
        registerCellClass(SquareCaroucel.self)
        delegate = self
        dataSource = self
        isPagingEnabled = false
        showsHorizontalScrollIndicator = false
    }
    
    private var listener: (GroupFeed) -> Void = { _ in }
    public func listen(_ listener: @escaping (GroupFeed) -> Void) {
        self.listener = listener
    }
}

extension PartyCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = self.items[indexPath.item]
        return collectionView.dequeueReusableCell(SquareCaroucel.self, input: (
            imageUrl: item.group.artworkURL,
            imagePipeline: imagePipeline
        ), for: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.items[indexPath.item]
        self.listener(item)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension PartyCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 60)
    }
}

final class SquareCaroucel: UICollectionViewCell, ReusableCell {
    typealias Input = SquareCaroucelContent.Input
    typealias Output = SquareCaroucelContent.Output
    static var reusableIdentifier: String { "SquareCaroucel" }
    private let _contentView: SquareCaroucelContent
    override init(frame: CGRect) {
        _contentView = SquareCaroucelContent()
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

public final class SquareCaroucelContent: UIButton {
    public typealias Input = (
        imageUrl: URL?,
        imagePipeline: ImagePipeline
    )
    enum Output {
    }
    
    private lazy var thumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 10
//        imageView.layer.borderWidth = 1
//        imageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
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
            thumbnailView.image = Brand.color(for: .background(.light)).image
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
