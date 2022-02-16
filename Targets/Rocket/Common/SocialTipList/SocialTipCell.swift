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
        case artworkTapped
    }
    
    private lazy var artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(artworkImageViewTapped)))
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = false
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.spacing = 4
        
        stackView.addArrangedSubview(toLabel)
        stackView.addArrangedSubview(themeLabel)
        stackView.addArrangedSubview(border)
        stackView.addArrangedSubview(textView)
        stackView.addArrangedSubview(dateLabel)
        
        return stackView
    }()
    private lazy var border: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Brand.color(for: .text(.primary))
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 2)
        ])
        return view
    }()
    private lazy var themeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .largeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 18)
        ])
        return label
    }()
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .xxsmall)
        label.textColor = Brand.color(for: .text(.primary))
        label.textAlignment = .right
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 14)
        ])
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
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 14)
        ])
        return label
    }()
    
    private lazy var fromBannerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userThumbnailImageView)
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        NSLayoutConstraint.activate([
            userThumbnailImageView.widthAnchor.constraint(equalToConstant: 28),
            userThumbnailImageView.heightAnchor.constraint(equalTo: userThumbnailImageView.widthAnchor),
            userThumbnailImageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
            userThumbnailImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            userThumbnailImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
        ])
        view.addSubview(fromLabel)
        NSLayoutConstraint.activate([
            fromLabel.rightAnchor.constraint(equalTo: userThumbnailImageView.leftAnchor, constant: -4),
            fromLabel.topAnchor.constraint(equalTo: userThumbnailImageView.topAnchor),
            fromLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: -12),
        ])
        view.addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.rightAnchor.constraint(equalTo: fromLabel.rightAnchor),
            countLabel.leftAnchor.constraint(equalTo: fromLabel.leftAnchor),
            countLabel.topAnchor.constraint(equalTo: fromLabel.bottomAnchor),
        ])
        
        return view
    }()
    private lazy var userThumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 14
        imageView.clipsToBounds = true
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    private lazy var fromLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .xsmallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        label.textAlignment = .right
        return label
    }()
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .xxsmallStrong)
        label.textAlignment = .right
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
        themeLabel.text = input.tip.theme
        if let url = input.tip.user.thumbnailURL.flatMap(URL.init(string:)) {
            input.imagePipeline.loadImage(url, into: userThumbnailImageView)
        }
        
        switch input.tip.type {
        case .group(let group):
            toLabel.text = "\(group.name)"
            if let url = group.artworkURL {
                input.imagePipeline.loadImage(url, into: artworkImageView)
            }
        case .live(let live):
            toLabel.text = "\(live.title)"
            if let url = live.artworkURL ?? live.hostGroup.artworkURL {
                input.imagePipeline.loadImage(url, into: artworkImageView)
            }
        }
        
        fromLabel.text = input.tip.user.name
        countLabel.text = "\(input.tip.tip) snacks"
        dateLabel.text = "\(input.tip.thrownAt.toFormatString(format: "yyyy/MM/dd"))"
        textView.text = input.tip.message
        
        if input.tip.isRealMoney {
            backgroundColor = Brand.color(for: .brand(.primary))
            fromBannerView.backgroundColor = Brand.color(for: .brand(.dark))
        } else {
            backgroundColor = Brand.color(for: .background(.light))
            fromBannerView.backgroundColor = Brand.color(for: .background(.milder))
        }
    }
    
    func setup() {
        self.backgroundColor = .clear
        self.layer.cornerRadius = 20
        self.layer.borderWidth = 2
        self.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        
//        addSubview(userThumbnailImageView)
//        NSLayoutConstraint.activate([
//            userThumbnailImageView.widthAnchor.constraint(equalToConstant: 50),
//            userThumbnailImageView.heightAnchor.constraint(equalTo: userThumbnailImageView.widthAnchor),
//            userThumbnailImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
//            userThumbnailImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
//        ])
        
        addSubview(artworkImageView)
        NSLayoutConstraint.activate([
            artworkImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
            artworkImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            artworkImageView.widthAnchor.constraint(equalToConstant: 72),
            artworkImageView.heightAnchor.constraint(equalToConstant: 92),
        ])
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: artworkImageView.topAnchor),
            stackView.leftAnchor.constraint(equalTo: artworkImageView.rightAnchor, constant: 8),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
//            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
        
        addSubview(fromBannerView)
        NSLayoutConstraint.activate([
            fromBannerView.leftAnchor.constraint(equalTo: leftAnchor),
            fromBannerView.rightAnchor.constraint(equalTo: rightAnchor),
            fromBannerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            fromBannerView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12),
            fromBannerView.topAnchor.constraint(greaterThanOrEqualTo: artworkImageView.bottomAnchor, constant: 12),
        ])
        
        addTarget(self, action: #selector(cellTapped), for: .touchUpInside)
    }
    
    func prepare() {
        artworkImageView.image = nil
        themeLabel.text = nil
        toLabel.text = nil
        dateLabel.text = nil
//        countLabel.text = nil
    }
    
    @objc private func cellTapped() {
        self.listener(.cellTapped)
    }
    
    @objc private func artworkImageViewTapped() {
        self.listener(.artworkTapped)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
