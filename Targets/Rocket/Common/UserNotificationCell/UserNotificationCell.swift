//
//  UserNotificationCell.swift
//  ImagePipeline
//
//  Created by Masato TSUTSUMI on 2021/04/06.
//

import DomainEntity
import UIKit
import ImagePipeline

final class UserNotificationCell: UITableViewCell, ReusableCell {
    typealias Input = UserNotificationCellContent.Input
    typealias Output = UserNotificationCellContent.Output
    static var reusableIdentifier: String { "UserNotificationCell" }
    private let _contentView: UserNotificationCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = UINib(nibName: "UserNotificationCellContent", bundle: nil).instantiate(withOwner: nil, options: nil).first as! UserNotificationCellContent
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(_contentView)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.isUserInteractionEnabled = false
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

class UserNotificationCellContent: UIView {
    typealias Input = (
        notification: UserNotification,
        imagePipeline: ImagePipeline
    )
    enum Output {
    }
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var cellButton: UIButton!
    private var highlightObservation: NSKeyValueObservation!
    
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        cellButton.addTarget(target, action: action, for: controlEvents)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    func inject(input: Input) {
        titleLabel.textColor = input.notification.isRead ? Brand.color(for: .text(.primary)) : Brand.color(for: .text(.link))
        createdAtLabel.text = dateFormatter.string(from: input.notification.createdAt)
        switch input.notification.notificationType {
        case .like(let like):
            titleLabel.text = "\(like.likedBy.name)がいいね"
            if let url = like.feed.ogpUrl.flatMap(URL.init(string: )) {
                input.imagePipeline.loadImage(url, into: thumbnailImageView)
            }
        case .follow(let user):
            titleLabel.text = "\(user.name)がフォロー"
            if let url = user.thumbnailURL.flatMap(URL.init(string: )) {
                input.imagePipeline.loadImage(url, into: thumbnailImageView)
            }
        case .comment(let comment):
            titleLabel.text = "\(comment.text) from \(comment.author.name)"
        case .officialAnnounce(let announce):
            titleLabel.text = announce.title
        }
    }
    
    func setup() {
        backgroundColor = .clear
        titleLabel.font = Brand.font(for: .mediumStrong)
        titleLabel.textColor = Brand.color(for: .text(.primary))
        
        createdAtLabel.font = Brand.font(for: .small)
        createdAtLabel.textColor = Brand.color(for: .text(.primary))
        
        thumbnailImageView.layer.cornerRadius = 30
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        
        highlightObservation = cellButton.observe(\.isHighlighted) { [unowned self] (button, change) in
            alpha = button.isHighlighted ? 0.6 : 1.0
        }
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
