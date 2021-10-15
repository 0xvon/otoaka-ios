//
//  ImageGalleryCollectionView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/10/15.
//

import UIKit
import ImagePipeline

public final class ImageGalleryCollectionView: UICollectionView {
    public enum ImageType {
        case url([URL])
        case image([UIImage])
        case none
    }
    
    public var images: ImageType
    public var imagePipeline: ImagePipeline
    
    public init(images: ImageType, imagePipeline: ImagePipeline) {
        self.images = images
        self.imagePipeline = imagePipeline
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        super.init(frame: .zero, collectionViewLayout: layout)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func inject(images: ImageType) {
        self.images = images
        reloadData()
    }
    
    func setup() {
        backgroundColor = .clear
        
        registerCellClass(ImageGalleryCollectionCell.self)
        delegate = self
        dataSource = self
        isPagingEnabled = true
        showsHorizontalScrollIndicator = false
    }
    
    private var listener: (Int) -> Void = { _ in }
    public func listen(_ listener: @escaping (Int) -> Void) {
        self.listener = listener
    }
}

extension ImageGalleryCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.images {
        case .image(let images):
            return images.count
        case .url(let urls):
            return urls.count
        case .none:
            return 0
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch self.images {
        case .image(let images):
            let cell = collectionView.dequeueReusableCell(
                ImageGalleryCollectionCell.self,
                input: (image: .image(images[indexPath.item]), imagePipeline: self.imagePipeline),
                for: indexPath
            )
            return cell
        case .url(let urls):
            let cell = collectionView.dequeueReusableCell(
                ImageGalleryCollectionCell.self,
                input: (image: .url(urls[indexPath.item]), imagePipeline: self.imagePipeline),
                for: indexPath
            )
            return cell
        case .none: fatalError()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.listener(indexPath.item)
    }
}

extension ImageGalleryCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize = UIScreen.main.bounds
        return CGSize(width: screenSize.width, height: screenSize.width)
    }
}

class ImageGalleryCollectionCell: UICollectionViewCell, ReusableCell {
    typealias Input = ImageGalleryCollectionCellContent.Input
    static var reusableIdentifier: String { "ImageGalleryCollectionCell" }
    private let _contentView: ImageGalleryCollectionCellContent
    override init(frame: CGRect) {
        _contentView = ImageGalleryCollectionCellContent()
        super.init(frame: frame)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.isUserInteractionEnabled = false
        backgroundColor = .clear
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
    
    func inject(input: ImageGalleryCollectionCellContent.Input) {
        _contentView.inject(input: input)
    }
    
    override func prepareForReuse() {
        _contentView.prepare()
    }
    
    override var isHighlighted: Bool {
        didSet { _contentView.isHighlighted = isHighlighted }
    }
}

class ImageGalleryCollectionCellContent: UIButton {
    typealias Input = (
        image: ImageType,
        imagePipeline: ImagePipeline
    )
    enum ImageType {
        case url(URL)
        case image(UIImage)
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
    
    func prepare() {
        thumbnailView.image = nil
    }
    
    func inject(input: Input) {
        switch input.image {
        case .image(let image):
            thumbnailView.image = image
        case .url(let url):
            input.imagePipeline.loadImage(url, into: thumbnailView)
        }
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
