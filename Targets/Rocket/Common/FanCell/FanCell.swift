//
//  FanCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/08.
//

import UIKit
import Endpoint
import ImagePipeline

final class FanCell: UITableViewCell, ReusableCell {
    typealias Input = FanCellContent.Input
    typealias Output = FanCellContent.Output
    static var reusableIdentifier: String { "FanCell" }
    
    private let _contentView: FanCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = FanCellContent()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(_contentView)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.isUserInteractionEnabled = true
        backgroundColor = .clear
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            _contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
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
    
    deinit {
        print("FanCell.deinit")
    }
}

class FanCellContent: UIButton {
    typealias Input = (
        user: User,
        isMe: Bool,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case openMessageButtonTapped
        case userTapped
    }
    
    private lazy var fanArtworkImageView: UIImageView = {
        let fanArtworkImageView = UIImageView()
        fanArtworkImageView.translatesAutoresizingMaskIntoConstraints = false
        fanArtworkImageView.layer.cornerRadius = 30
        fanArtworkImageView.clipsToBounds = true
        fanArtworkImageView.image = nil
        fanArtworkImageView.contentMode = .scaleAspectFill
        fanArtworkImageView.isUserInteractionEnabled = true
        fanArtworkImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        
        return fanArtworkImageView
    }()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.spacing = 8
        
        stackView.addArrangedSubview(topStackView)
        stackView.addArrangedSubview(profileLabel)
        NSLayoutConstraint.activate([
            profileLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(liveStyleLabel)
        NSLayoutConstraint.activate([
            liveStyleLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(biographyTextView)
        NSLayoutConstraint.activate([
            biographyTextView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        let spacer = UIView()
        spacer.backgroundColor = .clear
        stackView.addArrangedSubview(spacer)
        
        return stackView
    }()
    
    private lazy var topStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.spacing = 4
        
        stackView.addArrangedSubview(fanNameLabel)
        stackView.addArrangedSubview(messageButton)
        NSLayoutConstraint.activate([
            messageButton.widthAnchor.constraint(equalToConstant: 32),
            messageButton.heightAnchor.constraint(equalToConstant: 32),
        ])
        
        return stackView
    }()
    private lazy var fanNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var profileLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .small)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var liveStyleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .small)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var biographyTextView: UITextView = {
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
    private lazy var messageButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("", selected: false)
        button.setImage(
            UIImage(systemName: "message")!.withTintColor(Brand.color(for: .text(.toggle)), renderingMode: .alwaysOriginal),
            for: .normal
        )
        button.isUserInteractionEnabled = true
        button.addTarget(self, action: #selector(openMessageButtonTapped), for: .touchUpInside)
        return button
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
        if let thumbnail = input.user.thumbnailURL, let url = URL(string: thumbnail) {
            input.imagePipeline.loadImage(url, into: fanArtworkImageView)
        }
        fanNameLabel.text = input.user.name
        profileLabel.text = [
            input.user.age.map {String($0)},
            input.user.sex,
            input.user.residence
        ].compactMap {$0}.joined(separator: "・")
        liveStyleLabel.text = input.user.liveStyle ?? ""
        messageButton.isHidden = input.isMe
        biographyTextView.text = input.user.biography
    }
    
    func setup() {
        self.backgroundColor = .clear
        
        addSubview(fanArtworkImageView)
        NSLayoutConstraint.activate([
            fanArtworkImageView.widthAnchor.constraint(equalToConstant: 60),
            fanArtworkImageView.heightAnchor.constraint(equalTo: fanArtworkImageView.widthAnchor),
            fanArtworkImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            fanArtworkImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
        ])
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: fanArtworkImageView.topAnchor),
            stackView.leftAnchor.constraint(equalTo: fanArtworkImageView.rightAnchor, constant: 8),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }
    
    func prepare() {
        fanArtworkImageView.image = nil
        fanNameLabel.text = nil
        profileLabel.text = nil
        liveStyleLabel.text = nil
        messageButton.isHidden = true
        biographyTextView.text = nil
    }
    
    @objc private func userTapped() {
        self.listener(.userTapped)
    }
    
    @objc private func openMessageButtonTapped() {
        self.listener(.openMessageButtonTapped)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
    
    deinit {
        print("FanCellContent.deinit")
    }
}
