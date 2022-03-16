//
//  GroupCollectionCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/03/16.
//

import Endpoint
import UIKit
import ImagePipeline
import UIComponent

final class GroupCollectionCell: UICollectionViewCell, ReusableCell {
    typealias Input = GroupCollectionCellContent.Input
    typealias Output = GroupCollectionCellContent.Output
    static var reusableIdentifier: String { "GroupCollectionCell" }
    private let _contentView: GroupCollectionCellContent
    override init(frame: CGRect) {
        _contentView = GroupCollectionCellContent()
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: frame)
        contentView.addSubview(_contentView)
        _contentView.isUserInteractionEnabled = false
        backgroundColor = .clear
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
        _contentView.update(input: input)
    }
    
    func listen(_ listener: @escaping (Output) -> Void) {
        _contentView.listen(listener)
    }
    
    override var isHighlighted: Bool {
        didSet { _contentView.isHighlighted = isHighlighted }
    }
    
    override func prepareForReuse() {
        _contentView.prepare()
    }
}

final class GroupCollectionCellContent: UIButton {
    typealias Input = (
        group: GroupFeed,
        imagePipeline: ImagePipeline
    )
    public enum Output {
        case selfTapped
    }
    private lazy var groupArtworkView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 24
        imageView.layer.borderWidth = 1
        imageView.alpha = 0.3
        imageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    private lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .largeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = false
        label.sizeToFit()
        return label
    }()
    
    public override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }
    
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
    }
    
    func prepare() {
        groupArtworkView.image = nil
        groupNameLabel.text = nil
    }

    func setup() {
        backgroundColor = .clear
        
        addSubview(groupArtworkView)
        NSLayoutConstraint.activate([
            groupArtworkView.leftAnchor.constraint(equalTo: leftAnchor),
            groupArtworkView.rightAnchor.constraint(equalTo: rightAnchor),
            groupArtworkView.topAnchor.constraint(equalTo: topAnchor),
            groupArtworkView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        addSubview(groupNameLabel)
        NSLayoutConstraint.activate([
            groupNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            groupNameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            groupNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
        ])
        
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
    
    @objc private func touchUpInside() {
        self.listener(.selfTapped)
    }
}
