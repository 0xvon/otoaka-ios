//
//  SocailTipEventCardCollectionView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/01/04.
//

import UIKit
import ImagePipeline
import Endpoint

public final class SocialTipEventCardCollectionView: UICollectionView {
    public var socialTipEvents: [SocialTipEvent] = []
    public var imagePipeline: ImagePipeline
    
    public init(socialTipEvents: [SocialTipEvent], imagePipeline: ImagePipeline) {
        self.socialTipEvents = socialTipEvents
        self.imagePipeline = imagePipeline
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
        
        super.init(frame: .zero, collectionViewLayout: layout)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func inject(socialTipEvents: [SocialTipEvent]) {
        self.socialTipEvents = socialTipEvents
        reloadData()
//        setBackgroundView()
    }
    
    func setup() {
        backgroundColor = .clear
        
        registerCellClass(SocialTipEventCardCell.self)
        delegate = self
        dataSource = self
        isPagingEnabled = false
        showsHorizontalScrollIndicator = false
    }
    
    private var listener: (SocialTipEvent) -> Void = { _ in }
    public func listen(_ listener: @escaping (SocialTipEvent) -> Void) {
        self.listener = listener
    }
}

extension SocialTipEventCardCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.socialTipEvents.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(SocialTipEventCardCell.self, input: (socialTipEvent: self.socialTipEvents[indexPath.item], imagePipeline: self.imagePipeline), for: indexPath)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.listener(self.socialTipEvents[indexPath.item])
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
//    func setBackgroundView() {
//        let emptyCollectionView = EmptyCollectionView(emptyType: .event, actionButtonTitle: nil)
//        backgroundView = self.socialTipEvents.isEmpty ? emptyCollectionView : nil
//        if let backgroundView = self.backgroundView {
//            NSLayoutConstraint.activate([
//                backgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 32),
//                backgroundView.widthAnchor.constraint(equalTo: widthAnchor, constant: -32),
//                backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
//                backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32),
//            ])
//        }
//    }
}

extension SocialTipEventCardCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width - 40, height: 160)
    }
}

final class SocialTipEventCardCell: UICollectionViewCell, ReusableCell {
    typealias Input = SocialTipEventCardCellContent.Input
    typealias Output = SocialTipEventCardCellContent.Output
    static var reusableIdentifier: String { "SocialTipEventCardCell" }
    private let _contentView: SocialTipEventCardCellContent
    override init(frame: CGRect) {
        _contentView = SocialTipEventCardCellContent()
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

public final class SocialTipEventCardCellContent: UIButton {
    public typealias Input = (
        socialTipEvent: SocialTipEvent,
        imagePipeline: ImagePipeline
    )
    enum Output {
    }
    
    private lazy var thumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = 0.3
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    private lazy var eventTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .largeStrong)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var liveTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .small)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Brand.color(for: .background(.secondary))
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
        if let url = input.socialTipEvent.live.artworkURL ?? input.socialTipEvent.live.hostGroup.artworkURL {
            input.imagePipeline.loadImage(url, into: thumbnailView)
        } else {
            thumbnailView.image = Brand.color(for: .background(.secondary)).image
        }
        eventTitleLabel.text = input.socialTipEvent.title
        liveTitleLabel.text = input.socialTipEvent.live.title
    }
    
    func prepare() {
        thumbnailView.image = nil
        eventTitleLabel.text = nil
    }
    
    func setup() {
        backgroundColor = .clear
        layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 16
        
        addSubview(thumbnailView)
        NSLayoutConstraint.activate([
            thumbnailView.rightAnchor.constraint(equalTo: rightAnchor),
            thumbnailView.leftAnchor.constraint(equalTo: leftAnchor),
            thumbnailView.topAnchor.constraint(equalTo: topAnchor),
            thumbnailView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        addSubview(eventTitleLabel)
        NSLayoutConstraint.activate([
            eventTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            eventTitleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            eventTitleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
        ])
        
        addSubview(liveTitleLabel)
        NSLayoutConstraint.activate([
            liveTitleLabel.topAnchor.constraint(equalTo: eventTitleLabel.bottomAnchor, constant: 4),
            liveTitleLabel.leftAnchor.constraint(equalTo: eventTitleLabel.leftAnchor),
            liveTitleLabel.rightAnchor.constraint(equalTo: eventTitleLabel.rightAnchor),
        ])
    }
}
