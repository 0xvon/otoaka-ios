//
//  MessageListCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/06/18.
//

import DomainEntity
import UIKit
import ImagePipeline

final class MessageListCell: UITableViewCell, ReusableCell {
    typealias Input = MessageListCellContent.Input
    typealias Output = MessageListCellContent.Output
    static var reusableIdentifier: String { "MessageListCell" }
    
    private let _contentView: MessageListCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = UINib(nibName: "MessageListCellContent", bundle: nil).instantiate(withOwner: nil, options: nil).first as! MessageListCellContent
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
}

class MessageListCellContent: UIButton {
    typealias Input = (
        room: MessageRoom,
        user: User,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case userTapped
        case roomTapped
        
    }
    
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    private lazy var roomImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        return imageView
    }()
    private lazy var roomNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .small)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var latestMessageTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isUserInteractionEnabled = false
        textView.isScrollEnabled = false
        textView.font = Brand.font(for: .medium)
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .left
        textView.backgroundColor = Brand.color(for: .background(.primary))
        textView.textColor = Brand.color(for: .text(.primary))
        return textView
    }()
    private lazy var unreadBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.backgroundColor = Brand.color(for: .brand(.light))
        view.isHidden = true
        return view
    }()
    
    func inject(input: Input) {
        let partner: User = input.room.members.filter { $0.id != input.user.id }.first ?? input.room.owner
        if let avatar = partner.thumbnailURL, let avatarUrl = URL(string: avatar) {
            input.imagePipeline.loadImage(avatarUrl, into: roomImageView)
        }
        roomNameLabel.text = partner.name
        if let latestMessage = input.room.latestMessage {
            latestMessageTextView.text = latestMessage.text
            unreadBadge.isHidden = latestMessage.readingUsers.map { $0.id }.contains(input.user.id)
            dateLabel.text = latestMessage.sentAt.toFormatString(format: "yyyy/MM/dd HH:mm")
        }
    }
    
    func setup() {
        self.backgroundColor = .clear
        
        self.addTarget(self, action: #selector(roomTapped), for: .touchUpInside)
        
        addSubview(roomImageView)
        NSLayoutConstraint.activate([
            roomImageView.heightAnchor.constraint(equalToConstant: 60),
            roomImageView.widthAnchor.constraint(equalTo: roomImageView.heightAnchor),
            roomImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            roomImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            roomImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
        ])
        
        addSubview(roomNameLabel)
        NSLayoutConstraint.activate([
            roomNameLabel.topAnchor.constraint(equalTo: roomImageView.topAnchor),
            roomNameLabel.leftAnchor.constraint(equalTo: roomImageView.rightAnchor, constant: 4),
            roomNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
        ])
        
        
        addSubview(dateLabel)
        NSLayoutConstraint.activate([
            dateLabel.leftAnchor.constraint(equalTo: roomNameLabel.leftAnchor),
            dateLabel.rightAnchor.constraint(equalTo: roomNameLabel.rightAnchor),
            dateLabel.topAnchor.constraint(equalTo: roomNameLabel.bottomAnchor, constant: 4),
        ])
        
        addSubview(latestMessageTextView)
        NSLayoutConstraint.activate([
            latestMessageTextView.leftAnchor.constraint(equalTo: roomNameLabel.leftAnchor),
            latestMessageTextView.rightAnchor.constraint(equalTo: roomNameLabel.rightAnchor),
            latestMessageTextView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            latestMessageTextView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -4),
        ])
        
        addSubview(unreadBadge)
        NSLayoutConstraint.activate([
            unreadBadge.heightAnchor.constraint(equalToConstant: 20),
            unreadBadge.widthAnchor.constraint(equalTo: unreadBadge.heightAnchor),
            unreadBadge.topAnchor.constraint(equalTo: roomImageView.topAnchor, constant: -4),
            unreadBadge.rightAnchor.constraint(equalTo: roomImageView.rightAnchor, constant: 4),
        ])
    }
    
    @objc private func userTapped() {
        self.listener(.userTapped)
    }
    
    @objc private func roomTapped() {
        self.listener(.roomTapped)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
