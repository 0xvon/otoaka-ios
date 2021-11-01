//
//  LiveScheduleCardView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/01.
//

import Endpoint
import UIKit
import ImagePipeline

final class LiveScheduleCardCell: UICollectionViewCell, ReusableCell {
    typealias Input = LiveScheduleCardCellContent.Input
    typealias Output = LiveScheduleCardCellContent.Output
    static var reusableIdentifier: String { "LiveScheduleCardCell" }
    private let _contentView: LiveScheduleCardCellContent
    override init(frame: CGRect) {
        _contentView = LiveScheduleCardCellContent()
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

public final class LiveScheduleCardCellContent: UIButton {
    public typealias Input = (
        live: LiveFeed,
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
    private lazy var participantsView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = -8
        return view
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
        if let url = input.live.live.artworkURL {
            input.imagePipeline.loadImage(url, into: thumbnailView)
        } else {
            thumbnailView.image = Brand.color(for: .background(.secondary)).image
        }
        liveTitleLabel.text = input.live.live.title
        switch input.live.live.style {
        case .oneman(let group):
            self.groupNameLabel.text = group.name
        case .battle(let groups):
            self.groupNameLabel.text = groups[0].name + "..."
        case .festival(let groups):
            self.groupNameLabel.text = groups[0].name + "..."
        }
        injectParticipants(participants: input.live.participatingFriends, imagePipeline: input.imagePipeline)
    }
    
    func prepare() {
        thumbnailView.image = nil
        liveTitleLabel.text = nil
        groupNameLabel.text = nil
    }
    
    func injectParticipants(participants: [User], imagePipeline: ImagePipeline) {
        participantsView.arrangedSubviews.forEach {
            participantsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        if participants.isEmpty {
            for _ in 1...3 {
                let imageView = UIImageView()
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 15
                imageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
                imageView.layer.borderWidth = 1
                imageView.image = Brand.color(for: .background(.cellSelected)).image
                participantsView.addArrangedSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.heightAnchor.constraint(equalToConstant: 30),
                    imageView.widthAnchor.constraint(equalToConstant: 30),
                ])
            }
        } else {
            participants.prefix(4).forEach {
                let imageView = UIImageView()
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 15
                imageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
                imageView.layer.borderWidth = 1
                if let url = $0.thumbnailURL.flatMap(URL.init(string: )) {
                    imagePipeline.loadImage(url, into: imageView)
                }
                participantsView.addArrangedSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.heightAnchor.constraint(equalToConstant: 30),
                    imageView.widthAnchor.constraint(equalToConstant: 30),
                ])
            }
        }
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        participantsView.addArrangedSubview(spacer)
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
            groupNameLabel.heightAnchor.constraint(equalToConstant: 13.4)
        ])
        
        addSubview(participantsView)
        NSLayoutConstraint.activate([
            participantsView.leftAnchor.constraint(equalTo: leftAnchor),
            participantsView.rightAnchor.constraint(equalTo: rightAnchor),
            participantsView.topAnchor.constraint(equalTo: groupNameLabel.bottomAnchor, constant: 4),
            participantsView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
