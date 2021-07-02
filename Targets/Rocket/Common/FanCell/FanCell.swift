//
//  FanCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/08.
//

import UIKit
import Endpoint
import ImagePipeline
import TagListView

final class FanCell: UITableViewCell, ReusableCell {
    typealias Input = FanCellContent.Input
    typealias Output = FanCellContent.Output
    static var reusableIdentifier: String { "FanCell" }
    
    public let _contentView: FanCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = UINib(nibName: "FanCellContent", bundle: nil).instantiate(withOwner: nil, options: nil).first as! FanCellContent
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
}

class FanCellContent: UIButton {
    typealias Input = (
        user: User,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case openMessageButtonTapped
        case userTapped
    }
    
    @IBOutlet weak var fanArtworkImageView: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    
    private lazy var fanNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var profileLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .small)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
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
    private lazy var seriousTagListView: TagListView = {
        let tagListView = TagListView()
        tagListView.translatesAutoresizingMaskIntoConstraints = false
        tagListView.textColor = Brand.color(for: .text(.primary))
        tagListView.textFont = Brand.font(for: .smallStrong)
        tagListView.tagBackgroundColor = Brand.color(for: .text(.link))
        tagListView.alignment = .leading
        tagListView.cornerRadius = 10
        tagListView.paddingY = 4
        tagListView.paddingX = 8
        tagListView.marginY = 8
        tagListView.marginX = 8
        return tagListView
    }()
    private lazy var dabbleTagListView: TagListView = {
        let tagListView = TagListView()
        tagListView.translatesAutoresizingMaskIntoConstraints = false
        tagListView.textColor = Brand.color(for: .text(.primary))
        tagListView.textFont = Brand.font(for: .smallStrong)
        tagListView.tagBackgroundColor = Brand.color(for: .text(.toggle))
        tagListView.alignment = .leading
        tagListView.cornerRadius = 10
        tagListView.paddingY = 4
        tagListView.paddingX = 8
        tagListView.marginY = 8
        tagListView.marginX = 8
        return tagListView
    }()
    public lazy var messageButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("メッセージしてみる", selected: false)
        button.isUserInteractionEnabled = true
        button.addTarget(self, action: #selector(openMessageButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    func inject(input: Input) {
        if let thumbnail = input.user.thumbnailURL {
            guard let url = URL(string: thumbnail) else { return }
            input.imagePipeline.loadImage(url, into: fanArtworkImageView)
        }
        fanNameLabel.text = input.user.name
        profileLabel.text = "21歳・男・ライブは前でガンガン派"
        addressLabel.text = "東京都在住"
        let seriousList = ["MY FIRST STORY", "RADWIMPS"]
        seriousTagListView.removeAllTags()
        seriousTagListView.addTags(seriousList)
        let dabbleList = ["04 Limited Sazabys", "SiM"]
        dabbleTagListView.removeAllTags()
        dabbleTagListView.addTags(dabbleList)
        biographyTextView.text = input.user.biography
    }
    
    func setup() {
        self.backgroundColor = .clear
        
        fanArtworkImageView.clipsToBounds = true
        fanArtworkImageView.layer.cornerRadius = 30
        fanArtworkImageView.contentMode = .scaleAspectFill
        fanArtworkImageView.isUserInteractionEnabled = true
        fanArtworkImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        
        stackView.spacing = 4
        stackView.axis = .vertical
        stackView.backgroundColor = .clear
        
        stackView.addArrangedSubview(fanNameLabel)
        NSLayoutConstraint.activate([
            fanNameLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
//            fanNameLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        stackView.addArrangedSubview(profileLabel)
        NSLayoutConstraint.activate([
            profileLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
//            profileLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        stackView.addArrangedSubview(addressLabel)
        NSLayoutConstraint.activate([
            addressLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
//            addressLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        stackView.addArrangedSubview(biographyTextView)
        NSLayoutConstraint.activate([
            biographyTextView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
//            biographyTextView.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        stackView.addArrangedSubview(seriousTagListView)
        NSLayoutConstraint.activate([
            seriousTagListView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(dabbleTagListView)
        NSLayoutConstraint.activate([
            dabbleTagListView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(messageButton)
        NSLayoutConstraint.activate([
            messageButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            messageButton.heightAnchor.constraint(equalToConstant: 48),
        ])
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
}
