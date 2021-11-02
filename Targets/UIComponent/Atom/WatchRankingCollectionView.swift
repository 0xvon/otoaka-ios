//
//  WatchRankingCollectionView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/02.
//

import UIKit
import ImagePipeline
import Endpoint

public final class WatchRankingCollectionView: UIStackView {
    public var groups: [GroupFeed]
    public var imagePipeline: ImagePipeline
    
    private lazy var firstRankingContent: WatchRankingCellContent = {
        let content = WatchRankingCellContent()
        content.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            content.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 48) / 3)
//        ])
        return content
    }()
    private lazy var secondRankingContent: WatchRankingCellContent = {
        let content = WatchRankingCellContent()
        content.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            content.widthAnchor.constraint(equalTo: firstRankingContent.widthAnchor)
//        ])
        return content
    }()
    private lazy var otherRankingContent: WatchRankingCellContent = {
        let content = WatchRankingCellContent()
        content.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            content.widthAnchor.constraint(equalTo: firstRankingContent.widthAnchor)
//        ])
        return content
    }()
    private lazy var emptyView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.font = Brand.font(for: .medium)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .center
        return textView
    }()
    
    public init(groups: [GroupFeed], imagePipeline: ImagePipeline) {
        self.groups = groups
        self.imagePipeline = imagePipeline
        
        super.init(frame: .zero)
        setup()
    }
    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func inject(group: [GroupFeed]) {
        self.groups = group
        switch group.count {
        case 0:
            firstRankingContent.isHidden = true
            secondRankingContent.isHidden = true
            otherRankingContent.isHidden = true
            emptyView.text = "（’・_・｀）\n\nライブ参戦履歴がありません。"
        case 1:
            firstRankingContent.isHidden = false
            firstRankingContent.inject(input: (group: group[0], imagePipeline: imagePipeline, ranking: .first))
            secondRankingContent.isHidden = true
            otherRankingContent.isHidden = true
            emptyView.isHidden = true
        case 2:
            firstRankingContent.isHidden = false
            firstRankingContent.inject(input: (group: group[0], imagePipeline: imagePipeline, ranking: .first))
            secondRankingContent.isHidden = false
            secondRankingContent.inject(input: (group: group[1], imagePipeline: imagePipeline, ranking: .second))
            otherRankingContent.isHidden = true
            emptyView.isHidden = true
        case 3:
            firstRankingContent.isHidden = false
            firstRankingContent.inject(input: (group: group[0], imagePipeline: imagePipeline, ranking: .first))
            secondRankingContent.isHidden = false
            secondRankingContent.inject(input: (group: group[1], imagePipeline: imagePipeline, ranking: .second))
            otherRankingContent.isHidden = false
            otherRankingContent.inject(input: (group: group[2], imagePipeline: imagePipeline, ranking: .other))
            emptyView.isHidden = true
        default: break
        }
    }
    
    func setup() {
        backgroundColor = .clear
        axis = .horizontal
        distribution = .fillEqually
        spacing = 8
        
        addArrangedSubview(firstRankingContent)
        firstRankingContent.isHidden = true
        firstRankingContent.addTarget(self, action: #selector(firstGroupTapped), for: .touchUpInside)
        addArrangedSubview(secondRankingContent)
        secondRankingContent.isHidden = true
        secondRankingContent.addTarget(self, action: #selector(secondGroupTapped), for: .touchUpInside)
        addArrangedSubview(otherRankingContent)
        otherRankingContent.isHidden = true
        otherRankingContent.addTarget(self, action: #selector(otherGroupTapped), for: .touchUpInside)
        addArrangedSubview(emptyView)
    }
    
    @objc private func firstGroupTapped() {
        self.listener(groups[0])
    }
    
    @objc private func secondGroupTapped() {
        self.listener(groups[1])
    }
    
    @objc private func otherGroupTapped() {
        self.listener(groups[2])
    }
    
    private var listener: (GroupFeed) -> Void = { _ in }
    public func listen(_ listener: @escaping (GroupFeed) -> Void) {
        self.listener = listener
    }
}

public final class WatchRankingCellContent: UIButton {
    public typealias Input = (
        group: GroupFeed,
        imagePipeline: ImagePipeline,
        ranking: Ranking
    )
    public enum Ranking {
        case first, second, other
    }
    enum Output {
    }
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(watchCountLabel)
        stackView.addArrangedSubview(thumbnailImageView)
        stackView.addArrangedSubview(groupNameLabel)
        return stackView
    }()
    private lazy var watchCountLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .largeStrong)
//        NSLayoutConstraint.activate([
//            watchCountLabel.heightAnchor.constraint(equalToConstant: 32),
//        ])
        return label
    }()
    private lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 10
        imageView.layer.borderWidth = 4
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    private lazy var thumbnailImageViewHeightConstraint: NSLayoutConstraint = NSLayoutConstraint(
        item: thumbnailImageView,
        attribute: .height,
        relatedBy: .equal,
        toItem: nil,
        attribute: .height,
        multiplier: 1,
        constant: 144
    )
    private lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .mediumStrong)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = Brand.color(for: .text(.primary))
//        NSLayoutConstraint.activate([
//            watchCountLabel.heightAnchor.constraint(equalToConstant: 14),
//        ])
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
        watchCountLabel.text = "\(input.group.watchingCount)回"
        groupNameLabel.text = input.group.group.name
        if let url = input.group.group.artworkURL {
            input.imagePipeline.loadImage(url, into: thumbnailImageView)
        } else {
            thumbnailImageView.image = Brand.color(for: .background(.secondary)).image
        }
        
        switch input.ranking {
        case .first:
            watchCountLabel.textColor = Brand.color(for: .ranking(.first))
            thumbnailImageView.layer.borderColor = Brand.color(for: .ranking(.first)).cgColor
            thumbnailImageViewHeightConstraint.constant = 144
        case .second:
            watchCountLabel.textColor = Brand.color(for: .ranking(.second))
            thumbnailImageView.layer.borderColor = Brand.color(for: .ranking(.second)).cgColor
            thumbnailImageViewHeightConstraint.constant = 124
        case .other:
            watchCountLabel.textColor = Brand.color(for: .ranking(.other))
            thumbnailImageView.layer.borderColor = Brand.color(for: .ranking(.other)).cgColor
            thumbnailImageViewHeightConstraint.constant = 100
        }
    }
    
    func prepare() {
        watchCountLabel.text = nil
        thumbnailImageView.image = nil
        groupNameLabel.text = nil
    }
    
    func setup() {
        backgroundColor = .clear
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            thumbnailImageViewHeightConstraint,
        ])
    }
}
