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
        case likeFeedButtonTapped
        case unlikeFeedButtonTapped
        case shareButtonTapped
        case downloadButtonTapped
        case instagramButtonTapped
        case userTapped
    }
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()

    @IBOutlet weak var feedTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var instagramButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var likeButton: ReactionIndicatorButton! {
        didSet {
            likeButton.setImage(
                UIImage(systemName: "heart")!
                    .withTintColor(.white, renderingMode: .alwaysOriginal),
                for: .normal)
            likeButton.setImage(
                UIImage(systemName: "heart.fill")!
                    .withTintColor(.white, renderingMode: .alwaysOriginal),
                for: .selected)
        }
    }
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
            if let thumbnail = youTubeClient.getThumbnailUrl() {
                input.imagePipeline.loadImage(thumbnail, into: thumbnailImageView)
            }
        case .appleMusic(_):
            if let artwork = input.feed.thumbnailUrl, let thumbnail = URL(string: artwork) {
                input.imagePipeline.loadImage(thumbnail, into: thumbnailImageView)
            }
        }
        if let profileImage = input.feed.author.thumbnailURL, let url = URL(string: profileImage) {
            input.imagePipeline.loadImage(url, into: profileImageView)
        }
        feedTitleLabel.text = input.feed.title
        textView.text = input.feed.text
        dateLabel.text = dateFormatter.string(from: input.feed.createdAt)
        artistNameLabel.text = input.feed.author.name
        commentButton.setTitle("\(input.feed.commentCount)", for: .normal)
        likeButton.isSelected = input.feed.isLiked
        likeButton.setTitle("\(input.feed.likeCount)", for: .normal)
        
        deleteFeedButton.isHidden = input.feed.author.id != input.user.id
    }

    func setup() {
        backgroundColor = Brand.color(for: .background(.primary))

        thumbnailImageView.layer.opacity = 0.6
        thumbnailImageView.layer.cornerRadius = 16
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor

        dateLabel.font = Brand.font(for: .xsmall)
        dateLabel.textColor = Brand.color(for: .text(.primary))

        artistNameLabel.font = Brand.font(for: .smallStrong)
        artistNameLabel.textColor = Brand.color(for: .text(.primary))
        
        feedTitleLabel.font = Brand.font(for: .small)
        feedTitleLabel.textColor = Brand.color(for: .text(.primary))
        
        textView.font = Brand.font(for: .xlargeStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textAlignment = .center
        textView.isScrollEnabled = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = .clear
        
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        
        downloadButton.setImage(
            UIImage(systemName: "arrow.down.to.line")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        
        instagramButton.addTarget(self, action: #selector(instagramButtonTapped), for: .touchUpInside)
        
        deleteFeedButton.setImage(
            UIImage(systemName: "trash")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        deleteFeedButton.addTarget(self, action: #selector(deleteFeedButtonTapped), for: .touchUpInside)
        
        
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)

        commentButton.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        
        shareButton.setImage(
            UIImage(named: "twitterMargin"),
            for: .normal
        )
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)

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
    
    @objc private func likeButtonTapped() {
        likeButton.isSelected ? listener(.unlikeFeedButtonTapped) : listener(.likeFeedButtonTapped)
        likeButton.isSelected.toggle()
    }
    
    @objc private func shareButtonTapped() {
        listener(.shareButtonTapped)
    }
    
    @objc private func downloadButtonTapped() {
        listener(.downloadButtonTapped)
    }
    
    @objc private func instagramButtonTapped() {
        listener(.instagramButtonTapped)
    }
    
    @objc private func userTapped() {
        listener(.userTapped)
    }

    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
