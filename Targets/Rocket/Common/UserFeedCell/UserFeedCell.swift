//
//  BandContentsCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import UIKit
import Endpoint
import ImagePipeline

class UserFeedCell: UITableViewCell, ReusableCell {
    typealias Input = UserFeedCellContent.Input
    typealias Output = UserFeedCellContent.Output
    static var reusableIdentifier: String { "UserFeedCell" }

    private let _contentView: UserFeedCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = UINib(nibName: "UserFeedCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! UserFeedCellContent
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(_contentView)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        // Proxy tap event to tableView(_:didSelectRowAt:)
        _contentView.cellButton.isUserInteractionEnabled = false
        backgroundColor = .clear
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            _contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            _contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            _contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
        ])
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func inject(input: Input) {
        _contentView.inject(input: input)
    }

    func listen(_ listener: @escaping (Output) -> Void) {
        _contentView.listen(listener)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        alpha = highlighted ? 0.6 : 1.0
        _contentView.alpha = highlighted ? 0.6 : 1.0
    }
}


class UserFeedCellContent: UIView {
    typealias Input = (
        user: User,
        feed: UserFeedSummary,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case commentButtonTapped
        case deleteFeedButtonTapped
        case shareButtonTapped
    }
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()

    @IBOutlet weak var feedTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var playImageView: UIImageView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var commentButton: ReactionIndicatorButton! {
        didSet {
            commentButton.setImage(
                UIImage(systemName: "bubble.right")!
                    .withTintColor(.white, renderingMode: .alwaysOriginal),
                for: .normal
            )
        }
    }
    @IBOutlet weak var deleteFeedButton: UIButton!
    private var highlightObservation: NSKeyValueObservation!
    @IBOutlet weak var cellButton: UIButton!

    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        cellButton.addTarget(target, action: action, for: controlEvents)
    }

    func inject(input: Input) {
        setup()
        
        switch input.feed.feedType {
        case .youtube(let url):
            let youTubeClient = YouTubeClient(url: url.absoluteString)
            let thumbnail = youTubeClient.getThumbnailUrl()
            input.imagePipeline.loadImage(thumbnail!, into: thumbnailImageView)
        }
        feedTitleLabel.text = input.feed.text
        dateLabel.text = dateFormatter.string(from: input.feed.createdAt)
        artistNameLabel.text = input.feed.author.name
        commentButton.setTitle("\(input.feed.commentCount)", for: .normal)
        
        deleteFeedButton.isHidden = input.feed.author.id != input.user.id
    }

    func setup() {
        backgroundColor = Brand.color(for: .background(.primary))

        thumbnailImageView.layer.opacity = 0.6
        thumbnailImageView.layer.cornerRadius = 16
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor

        feedTitleLabel.font = Brand.font(for: .largeStrong)
        feedTitleLabel.textColor = Brand.color(for: .text(.primary))
        feedTitleLabel.lineBreakMode = .byWordWrapping
        feedTitleLabel.numberOfLines = 0
        feedTitleLabel.adjustsFontSizeToFitWidth = false
        feedTitleLabel.sizeToFit()

        dateLabel.font = Brand.font(for: .small)
        dateLabel.textColor = Brand.color(for: .text(.primary))

        artistNameLabel.font = Brand.font(for: .medium)
        artistNameLabel.textColor = Brand.color(for: .text(.primary))
        
        deleteFeedButton.setImage(
            UIImage(systemName: "trash")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        deleteFeedButton.addTarget(self, action: #selector(deleteFeedButtonTapped), for: .touchUpInside)

        commentButton.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        
        shareButton.setImage(
            UIImage(systemName: "square.and.arrow.up")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)

        playImageView.image = UIImage(named: "play")
        playImageView.layer.opacity = 0.6
        highlightObservation = cellButton.observe(\.isHighlighted) { [unowned self] (button, change) in
            alpha = button.isHighlighted ? 0.6 : 1.0
        }
    }
    
    @objc private func deleteFeedButtonTapped() {
        listener(.deleteFeedButtonTapped)
    }

    @objc private func commentButtonTapped() {
        listener(.commentButtonTapped)
    }
    
    @objc private func shareButtonTapped() {
        listener(.shareButtonTapped)
    }

    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}