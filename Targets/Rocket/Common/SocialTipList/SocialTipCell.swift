//
//  SocialTipListCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/29.
//

import UIKit
import Endpoint
import ImagePipeline

final class SocialTipCell: UITableViewCell, ReusableCell {
    typealias Input = SocialTipCellContent.Input
    typealias Output = SocialTipCellContent.Output
    static var reusableIdentifier: String { "SocialTipCell" }
    
    private let _contentView: SocialTipCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = SocialTipCellContent()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(_contentView)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.isUserInteractionEnabled = true
        backgroundColor = .clear
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            _contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        _contentView.prepare()
    }
}

class SocialTipCellContent: UIButton {
    typealias Input = (
        tip: SocialTip,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case cellTapped
    }
    
    private lazy var artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 25
        imageView.clipsToBounds = true
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        
        return imageView
    }()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = false
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.spacing = 4
        
        stackView.addArrangedSubview(usernameLabel)
        stackView.addArrangedSubview(toLabel)
        stackView.addArrangedSubview(countLabel)
        stackView.addArrangedSubview(textView)
        stackView.addArrangedSubview(dateLabel)
        
        let spacer = UIView()
        spacer.backgroundColor = .clear
        stackView.addArrangedSubview(spacer)
        
        return stackView
    }()
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .xxsmall)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isUserInteractionEnabled = false
        textView.isScrollEnabled = false
        textView.font = Brand.font(for: .mediumStrong)
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .left
        textView.backgroundColor = .clear
        textView.textColor = Brand.color(for: .text(.primary))
        return textView
    }()
    private lazy var toLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func inject(input: Input) {
        usernameLabel.text = input.tip.user.name
        if let url = input.tip.user.thumbnailURL.flatMap(URL.init(string:)) {
            input.imagePipeline.loadImage(url, into: artworkImageView)
        }
        
        switch input.tip.type {
        case .group(let group):
            toLabel.text = "Dear: \(group.name)"
        case .live(let live):
            toLabel.text = "Dear: \(live.title)"
        }
        
        countLabel.text = "\(input.tip.tip)snacks"
        dateLabel.text = input.tip.thrownAt.toFormatString(format: "yyyy/MM/dd")
        textView.text = input.tip.message
        
        if input.tip.tip < 1500 {
            backgroundColor = Brand.color(for: .ranking(.other))
        } else if input.tip.tip < 5000 {
            backgroundColor = Brand.color(for: .ranking(.second))
        } else {
            backgroundColor = Brand.color(for: .ranking(.first))
        }
    }
    
    func setup() {
        self.backgroundColor = .clear
        self.layer.cornerRadius = 20
        self.layer.borderWidth = 2
        self.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        
        addSubview(artworkImageView)
        NSLayoutConstraint.activate([
            artworkImageView.widthAnchor.constraint(equalToConstant: 50),
            artworkImageView.heightAnchor.constraint(equalTo: artworkImageView.widthAnchor),
            artworkImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            artworkImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            artworkImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8)
        ])
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: artworkImageView.topAnchor),
            stackView.leftAnchor.constraint(equalTo: artworkImageView.rightAnchor, constant: 8),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
        ])
        
        addTarget(self, action: #selector(cellTapped), for: .touchUpInside)
    }
    
    func prepare() {
        artworkImageView.image = nil
        usernameLabel.text = nil
        countLabel.text = nil
    }
    
    @objc private func cellTapped() {
        self.listener(.cellTapped)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
