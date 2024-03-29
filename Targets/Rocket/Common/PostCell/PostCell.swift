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

class PostCollectionCell: UICollectionViewCell, ReusableCell {
    typealias Input = PostCellContent.Input
    typealias Output = PostCellContent.Output
    static var reusableIdentifier: String { "PostCollectionCell" }
    
    private let _contentView: PostCellContent
    override init(frame: CGRect) {
        _contentView = UINib(nibName: "PostCellContent", bundle: nil).instantiate(withOwner: nil, options: nil).first as! PostCellContent
        super.init(frame: frame)
        contentView.addSubview(_contentView)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.isUserInteractionEnabled = true
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
        _contentView.inject(input: input)
    }

    func listen(_ listener: @escaping (Output) -> Void) {
        _contentView.listen(listener)
    }
    
    override var isHighlighted: Bool {
        didSet { _contentView.isHighlighted = isHighlighted }
    }
    
    deinit {
        print("PostCollectionCell.deinit")
    }
}

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

public class PostCellContent: UIButton {
    typealias Input = (
        post: PostSummary,
        user: User,
        imagePipeline: ImagePipeline
    )
    public enum Output {
        case selfTapped
        case userTapped
        case liveTapped
        case trackTapped
        case commentTapped
        case likeTapped
        case settingTapped
    }
    
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
        
        postView.addArrangedSubview(textStackView)
        NSLayoutConstraint.activate([
            textStackView.widthAnchor.constraint(equalTo: postView.widthAnchor),
        ])
        
//        let spacer = UIView()
//        spacer.translatesAutoresizingMaskIntoConstraints = false
//        postView.addArrangedSubview(spacer)
        
        postView.addArrangedSubview(sectionView)
        NSLayoutConstraint.activate([
            sectionView.widthAnchor.constraint(equalTo: postView.widthAnchor),
            sectionView.heightAnchor.constraint(equalToConstant: 20),
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
            usernameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
        ])
//
//        view.addSubview(settingButton)
//        NSLayoutConstraint.activate([
//            settingButton.widthAnchor.constraint(equalToConstant: 24),
//            settingButton.heightAnchor.constraint(equalTo: settingButton.widthAnchor),
//            settingButton.topAnchor.constraint(equalTo: usernameLabel.topAnchor),
//            settingButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
//            settingButton.leftAnchor.constraint(equalTo: usernameLabel.rightAnchor, constant: 4),
//        ])
        
//        view.addSubview(trackNameLabel)
//        NSLayoutConstraint.activate([
//            trackNameLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor),
//            trackNameLabel.leftAnchor.constraint(equalTo: usernameLabel.leftAnchor),
//            trackNameLabel.rightAnchor.constraint(equalTo: usernameLabel.rightAnchor),
//        ])
        
        return view
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = ""
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = true
        textView.textContainer.lineBreakMode = .byTruncatingTail
//        textView.textContainer.maximumNumberOfLines = 10
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
//    private lazy var settingButton: UIButton = {
//        let button = UIButton()
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.setImage(
//            UIImage(systemName: "ellipsis")!
//                .withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal),
//            for: .normal
//        )
//        button.addTarget(self, action: #selector(settingTapped), for: .touchUpInside)
//        return button
//    }()
    private lazy var sectionView: UIStackView = {
        let sectionView = UIStackView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.distribution = .fill
        sectionView.axis = .horizontal
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        sectionView.addArrangedSubview(spacer)
        
        sectionView.addArrangedSubview(dateLabel)
        
        return sectionView
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
    
    public override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    func inject(input: Input) {
        if let avatar = input.post.author.thumbnailURL, let avatarUrl = URL(string: avatar) {
            input.imagePipeline.loadImage(avatarUrl, into: avatarImageView)
        }
        usernameLabel.text = input.post.author.name
        dateLabel.text = input.post.createdAt.toFormatString(format: "yyyy/MM/dd")
        textView.text = input.post.text
//        trackNameLabel.setTitle(input.post.tracks.first?.trackName, for: .normal)
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
        
//        addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
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
