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
        _contentView.isUserInteractionEnabled = true
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
    
    deinit {
        print("PostCell.deinit")
    }
}

class PostCellContent: UIButton {
    typealias Input = (
        post: PostSummary,
        user: User,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case selfTapped
        case userTapped
        case liveTapped
        case trackTapped
        case commentTapped
        case likeTapped
        case settingTapped
    }
    let postDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
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
        
        let textStackView = UIStackView()
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.axis = .horizontal
        textStackView.distribution = .fill
        textStackView.spacing = 8
        
        textStackView.addArrangedSubview(textView)
        textStackView.addSubview(seeMoreButton)
        NSLayoutConstraint.activate([
            seeMoreButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
            seeMoreButton.leftAnchor.constraint(equalTo: textView.leftAnchor),
            seeMoreButton.rightAnchor.constraint(equalTo: textView.rightAnchor),
        ])
        textStackView.addArrangedSubview(liveCardCell)
        NSLayoutConstraint.activate([
            textStackView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 2 / 3),
            liveCardCell.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width / 3),
        ])
        
        postView.addArrangedSubview(textStackView)
        NSLayoutConstraint.activate([
            textStackView.widthAnchor.constraint(equalTo: postView.widthAnchor),
        ])
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        postView.addArrangedSubview(spacer)
        
        postView.addArrangedSubview(sectionView)
        NSLayoutConstraint.activate([
            sectionView.widthAnchor.constraint(equalTo: postView.widthAnchor),
            sectionView.heightAnchor.constraint(equalToConstant: 32),
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
            avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        view.addSubview(usernameLabel)
        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            usernameLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 8),
        ])
        
        view.addSubview(settingButton)
        NSLayoutConstraint.activate([
            settingButton.widthAnchor.constraint(equalToConstant: 24),
            settingButton.heightAnchor.constraint(equalTo: settingButton.widthAnchor),
            settingButton.topAnchor.constraint(equalTo: usernameLabel.topAnchor),
            settingButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
            settingButton.leftAnchor.constraint(equalTo: usernameLabel.rightAnchor, constant: 4),
        ])
        
        view.addSubview(trackNameLabel)
        NSLayoutConstraint.activate([
            trackNameLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor),
            trackNameLabel.leftAnchor.constraint(equalTo: usernameLabel.leftAnchor),
            trackNameLabel.rightAnchor.constraint(equalTo: usernameLabel.rightAnchor),
        ])
        
        return view
    }()
    private lazy var liveCardCell: LiveCardCellContent = {
        let contentView = LiveCardCellContent()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.isUserInteractionEnabled = true
        contentView.addTarget(self, action: #selector(liveTapped), for: .touchUpInside)
        return contentView
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = ""
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = true
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.textContainer.maximumNumberOfLines = 10
        textView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selfTapped)))
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.font = Brand.font(for: .mediumStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .left
        return textView
    }()
    private lazy var seeMoreButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = Brand.color(for: .background(.primary))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("続きを読む", for: .normal)
        button.setTitleColor(Brand.color(for: .brand(.primary)), for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = Brand.font(for: .medium)
        button.addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
        return button
    }()
    private lazy var settingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(
            UIImage(systemName: "ellipsis")!
                .withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal),
            for: .normal
        )
        button.addTarget(self, action: #selector(settingTapped), for: .touchUpInside)
        return button
    }()
    private lazy var sectionView: UIStackView = {
        let sectionView = UIStackView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.distribution = .fill
        sectionView.axis = .horizontal
        
        sectionView.addArrangedSubview(commentButtonView)
        NSLayoutConstraint.activate([
            commentButtonView.widthAnchor.constraint(equalToConstant: 80),
        ])
        
        sectionView.addArrangedSubview(likeButtonView)
        NSLayoutConstraint.activate([
            likeButtonView.widthAnchor.constraint(equalToConstant: 60),
        ])
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        sectionView.addArrangedSubview(spacer)
        
        sectionView.addArrangedSubview(dateLabel)
        
        return sectionView
    }()
    private lazy var commentButtonView: ReactionIndicatorButton = {
        let commentButton = ReactionIndicatorButton()
        commentButton.translatesAutoresizingMaskIntoConstraints = false
        commentButton.setImage(
            UIImage(systemName: "message")!
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
    private lazy var trackNameLabel: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = Brand.font(for: .xsmall)
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(trackTapped), for: .touchUpInside)
        return button
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
        textView.text = input.post.text
        trackNameLabel.setTitle(input.post.tracks.first?.trackName, for: .normal)
        commentButtonView.setTitle("DM", for: .normal)
        commentButtonView.isEnabled = true
        likeButtonView.setTitle("\(input.post.likeCount)", for: .normal)
        likeButtonView.isSelected = input.post.isLiked
        likeButtonView.isEnabled = true
        if let live = input.post.live {
            liveCardCell.inject(input: (live: live, imagePipeline: input.imagePipeline))
        }
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
        
        addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
    }
    
    deinit {
        print("PostCellContent.deinit")
    }
    
    @objc private func selfTapped() {
        self.listener(.selfTapped)
    }
    
    @objc private func liveTapped() {
        self.listener(.liveTapped)
    }
    
    @objc private func commentButtonTapped() {
        self.listener(.commentTapped)
    }
    
    @objc private func likeButtonTapped() {
        likeButtonView.isSelected.toggle()
        self.listener(.likeTapped)
    }
    
    @objc private func settingTapped() {
        self.listener(.settingTapped)
    }
    
    @objc private func trackTapped() {
        self.listener(.trackTapped)
    }
    
    @objc private func userTapped() {
        self.listener(.userTapped)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
