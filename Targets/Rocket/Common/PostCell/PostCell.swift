//
//  PostCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/23.
//

import UIKit
import Endpoint
import ImagePipeline
import ImageViewer
import UIComponent

class PostCell: UITableViewCell, ReusableCell {
    typealias Input = PostCellContent.Input
    typealias Output = PostCellContent.Output
    static var reusableIdentifier: String { "PostCell" }
    
    private let _contentView: PostCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = UINib(nibName: "PostCellContent", bundle: nil).instantiate(withOwner: nil, options: nil).first as! PostCellContent
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(_contentView)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
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

class PostCellContent: UIButton {
    typealias Input = (
        post: PostSummary,
        user: User,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case userTapped
        case groupTapped
        case trackTapped(Track)
        case playTapped(Track)
        case imageTapped(GalleryItemsDataSource)
        case cellTapped
        case commentTapped
        case likeTapped
        case twitterTapped
        case instagramTapped
        case postListTapped
        case postTapped
        case deleteTapped
    }
    let postDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd HH:mm"
        return dateFormatter
    }()
    let liveDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"
        return dateFormatter
    }()
    let liveDisplayDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()
    
    private lazy var postView: UIStackView = {
        let postView = UIStackView()
        postView.translatesAutoresizingMaskIntoConstraints = false
        postView.backgroundColor = Brand.color(for: .background(.primary))
        postView.axis = .vertical
        postView.spacing = 16
        
        postView.addArrangedSubview(textContainerView)
        NSLayoutConstraint.activate([
            textContainerView.widthAnchor.constraint(equalTo: postView.widthAnchor)
        ])
        
        postView.addArrangedSubview(textView)
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalTo: postView.widthAnchor),
        ])
        
        postView.addArrangedSubview(postContentStackView)
        NSLayoutConstraint.activate([
            postContentStackView.widthAnchor.constraint(equalTo: postView.widthAnchor),
        ])
        
        postView.addArrangedSubview(writeReportButton)
        NSLayoutConstraint.activate([
            writeReportButton.heightAnchor.constraint(equalToConstant: 48),
            writeReportButton.widthAnchor.constraint(equalTo: postView.widthAnchor),
        ])
        
        postView.addArrangedSubview(sectionView)
        NSLayoutConstraint.activate([
            sectionView.widthAnchor.constraint(equalTo: postView.widthAnchor),
        ])
        
        return postView
    }()
    private lazy var textContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.topAnchor),
            avatarImageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
        ])
        
        view.addSubview(usernameLabel)
        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            usernameLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 8),
            usernameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 8),
        ])
        
        view.addSubview(dateLabel)
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            dateLabel.leftAnchor.constraint(equalTo: usernameLabel.leftAnchor),
            dateLabel.rightAnchor.constraint(equalTo: usernameLabel.rightAnchor),
        ])
        
        view.addSubview(liveInfoLabel)
        NSLayoutConstraint.activate([
            liveInfoLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            liveInfoLabel.leftAnchor.constraint(equalTo: dateLabel.leftAnchor),
            liveInfoLabel.rightAnchor.constraint(equalTo: dateLabel.rightAnchor),
            liveInfoLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        return view
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = ""
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.font = Brand.font(for: .mediumStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .left
        return textView
    }()
    private lazy var postContentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 4
        stackView.axis = .horizontal
        stackView.backgroundColor = .clear
        stackView.distribution = .fillEqually
        
        stackView.addArrangedSubview(uploadedImageView)
        stackView.addArrangedSubview(selectedGroupView)
        stackView.addArrangedSubview(playlistView)
        
        return stackView
    }()
    private lazy var uploadedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(uploadedImageTapped)))
        imageView.isHidden = true
        return imageView
    }()
    private lazy var selectedGroupView: GroupCellContent = {
        let content = UINib(nibName: "GroupCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! GroupCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 300),
        ])
        content.addTarget(self, action: #selector(selectedGroupTapped), for: .touchUpInside)
        content.isHidden = true
        return content
    }()
    private lazy var playlistView: PlaylistCellContent = {
        let content = UINib(nibName: "PlaylistCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! PlaylistCellContent
        content.translatesAutoresizingMaskIntoConstraints = false
        content.isUserInteractionEnabled = true
        content.listen { [unowned self] output in
            switch output {
            case .playButtonTapped(let track): self.listener(.playTapped(track))
            case .trackTapped(let track):
                self.listener(.trackTapped(track))
            }
        }
        NSLayoutConstraint.activate([
            content.heightAnchor.constraint(equalToConstant: 300),
        ])
        content.isHidden = true
        return content
    }()
    private lazy var writeReportButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("このライブのレポートを書く", selected: false)
        button.addTarget(self, action: #selector(postButtonTapped), for: .touchUpInside)
        button.layer.cornerRadius = 24
        return button
    }()
    private lazy var sectionView: UIStackView = {
        let sectionView = UIStackView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.distribution = .fill
        sectionView.axis = .horizontal
        
        sectionView.addArrangedSubview(showPostListButton)
        NSLayoutConstraint.activate([
            showPostListButton.widthAnchor.constraint(equalToConstant: 44),
            showPostListButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        sectionView.addArrangedSubview(commentButtonView)
        NSLayoutConstraint.activate([
            commentButtonView.widthAnchor.constraint(equalToConstant: 60),
            commentButtonView.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        sectionView.addArrangedSubview(likeButtonView)
        NSLayoutConstraint.activate([
            likeButtonView.widthAnchor.constraint(equalToConstant: 60),
            likeButtonView.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        sectionView.addArrangedSubview(twitterButton)
        NSLayoutConstraint.activate([
            twitterButton.widthAnchor.constraint(equalToConstant: 44),
            twitterButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        sectionView.addArrangedSubview(instagramButton)
        NSLayoutConstraint.activate([
            instagramButton.widthAnchor.constraint(equalToConstant: 44),
            instagramButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        sectionView.addArrangedSubview(deleteButton)
        NSLayoutConstraint.activate([
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        sectionView.addArrangedSubview(spacer)
        
        return sectionView
    }()
    private lazy var commentButtonView: ReactionIndicatorButton = {
        let commentButton = ReactionIndicatorButton()
        commentButton.translatesAutoresizingMaskIntoConstraints = false
        commentButton.setImage(
            UIImage(systemName: "bubble.right")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal
        )
        commentButton.addTarget(self, action: #selector(commentButtonTapped), for: .touchUpInside)
        return commentButton
    }()
    private lazy var likeButtonView: ReactionIndicatorButton = {
        let likeButton = ReactionIndicatorButton()
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.setImage(
            UIImage(systemName: "heart")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal)
        likeButton.setImage(
            UIImage(systemName: "heart.fill")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .selected)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return likeButton
    }()
    private lazy var twitterButton: UIButton = {
        let twitterButton = UIButton()
        twitterButton.translatesAutoresizingMaskIntoConstraints = false
        twitterButton.setImage(
            UIImage(named: "twitterMargin"),
            for: .normal)
        twitterButton.addTarget(self, action: #selector(shareTwitterButtonTapped), for: .touchUpInside)
        return twitterButton
    }()
    private lazy var instagramButton: UIButton = {
        let shareButton = UIButton()
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setImage(
            UIImage(named: "instaMargin"),
            for: .normal)
        shareButton.addTarget(self, action: #selector(shareInstagramButtonTapped), for: .touchUpInside)
        return shareButton
    }()
    private lazy var showPostListButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "note.text")!.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(showPostListButtonTapped), for: .touchUpInside)
        return button
    }()
    private lazy var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(
            UIImage(systemName: "trash")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteFeedButtonTapped), for: .touchUpInside)
        deleteButton.isHidden = true
        return deleteButton
    }()
    private lazy var avatarImageView: UIImageView = {
        let avatarImageView = UIImageView()
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        return avatarImageView
    }()
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .xsmall)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var liveInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .xsmall)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    func inject(input: Input) {
        if let avatar = input.post.author.thumbnailURL, let avatarUrl = URL(string: avatar) {
            input.imagePipeline.loadImage(avatarUrl, into: avatarImageView)
        }
        usernameLabel.text = input.post.author.name
        dateLabel.text = postDateFormatter.string(from: input.post.createdAt)
        if let live = input.post.live, let date = live.date, let formatted = liveDateFormatter.date(from: date) {
            let formattedDateString = liveDisplayDateFormatter.string(from: formatted)
            liveInfoLabel.text = "\(formattedDateString) \(live.title) (\(live.liveHouse ?? "場所不明"))"
        }
        textView.text = input.post.text
        
        selectedGroupView.isHidden = input.post.groups.isEmpty
        uploadedImageView.isHidden = input.post.imageUrls.isEmpty
        playlistView.isHidden = input.post.tracks.isEmpty
        
        if let group = input.post.groups.first {
            selectedGroupView.inject(input: (group: group, imagePipeline: input.imagePipeline))
        }
        if let image = input.post.imageUrls.first, let imageUrl = URL(string: image) {
            input.imagePipeline.loadImage(imageUrl, into: uploadedImageView)
        }
        let tracks = input.post.tracks.map {
            Track(name: $0.trackName, artistName: $0.groupName, artwork: $0.thumbnailUrl!, trackType: $0.type)
        }
        if (!tracks.isEmpty) {
            playlistView.inject(input: (tracks: tracks, imagePipeline: input.imagePipeline))
        }
        
        commentButtonView.setTitle("\(input.post.commentCount)", for: .normal)
        likeButtonView.setTitle("\(input.post.likeCount)", for: .normal)
        likeButtonView.isSelected = input.post.isLiked
        deleteButton.isHidden = input.post.author.id != input.user.id
    }
    
    func setup() {
        self.backgroundColor = .clear
        
        addSubview(postView)
        NSLayoutConstraint.activate([
            postView.topAnchor.constraint(equalTo: topAnchor),
            postView.rightAnchor.constraint(equalTo: rightAnchor),
            postView.leftAnchor.constraint(equalTo: leftAnchor),
            postView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    @objc private func commentButtonTapped() {
        self.listener(.commentTapped)
    }
    
    @objc private func likeButtonTapped() {
        self.listener(.likeTapped)
    }
    
    @objc private func shareInstagramButtonTapped() {
        self.listener(.instagramTapped)
    }
    
    @objc private func showPostListButtonTapped() {
        self.listener(.postListTapped)
    }
    
    @objc private func postButtonTapped() {
        self.listener(.postTapped)
    }
    
    @objc private func shareTwitterButtonTapped() {
        self.listener(.twitterTapped)
    }
    
    @objc private func deleteFeedButtonTapped() {
        self.listener(.deleteTapped)
    }
    
    @objc private func uploadedImageTapped() {
        self.listener(.imageTapped(self))
    }
    
    @objc private func selectedGroupTapped() {
        self.listener(.groupTapped)
    }
    
    @objc private func userTapped() {
        self.listener(.userTapped)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}

extension PostCellContent: GalleryItemsDataSource {
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        return GalleryItem.image(fetchImageBlock: { $0(self.uploadedImageView.image)} )
    }
    
    func itemCount() -> Int {
        return 1
    }
}
