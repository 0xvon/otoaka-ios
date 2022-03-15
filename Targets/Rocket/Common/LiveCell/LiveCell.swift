//
//  LiveCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/22.
//

import Endpoint
import UIKit
import ImagePipeline
import UIComponent

class LiveCollectionCell: UICollectionViewCell, ReusableCell {
    typealias Input = LiveCellContent.Input
    typealias Output = LiveCellContent.Output
    static var reusableIdentifier: String { "LiveCollectionCell" }

    private let _contentView: LiveCellContent
    override init(frame: CGRect) {
        _contentView = UINib(nibName: "LiveCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! LiveCellContent
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

    func inject(input: LiveCellContent.Input) {
        _contentView.inject(input: input)
    }

    func listen(_ listener: @escaping (Output) -> Void) {
        _contentView.listen(listener)
    }
    
    override var isHighlighted: Bool {
        didSet { _contentView.isHighlighted = isHighlighted }
    }
    
    deinit {
        print("LiveCollectionCell.deinit")
    }
}

class LiveCell: UITableViewCell, ReusableCell {
    typealias Input = LiveCellContent.Input
    typealias Output = LiveCellContent.Output
    static var reusableIdentifier: String { "LiveCell" }

    private let _contentView: LiveCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = UINib(nibName: "LiveCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! LiveCellContent
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
            _contentView.heightAnchor.constraint(equalToConstant: 300),
        ])
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func inject(input: LiveCellContent.Input) {
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
        print("LiveCell.deinit")
    }
}

public class LiveCellContent: UIButton {
    typealias Input = (
        live: LiveFeed,
        imagePipeline: ImagePipeline,
        type: LiveCellContentType
    )
    
    var series: LiveSeries = .future
    
    enum LiveCellContentType {
        case normal
        case review
    }
    public enum Output {
        case likeButtonTapped
        case numOfLikeTapped
        case reportButtonTapped
        case numOfReportTapped
        case buyTicketButtonTapped
        case selfTapped
    }

    @IBOutlet weak var liveTitleLabel: UILabel!
    @IBOutlet weak var bandsLabel: UILabel!
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.backgroundColor = .clear
        
        stackView.addArrangedSubview(placeView)
        NSLayoutConstraint.activate([
            placeView.heightAnchor.constraint(equalToConstant: 20),
            placeView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(dateView)
        NSLayoutConstraint.activate([
            dateView.heightAnchor.constraint(equalToConstant: 20),
            dateView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(numOfLikeButton)
        NSLayoutConstraint.activate([
            numOfLikeButton.heightAnchor.constraint(equalToConstant: 16),
            numOfLikeButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(numOfReportButton)
        NSLayoutConstraint.activate([
            numOfReportButton.heightAnchor.constraint(equalToConstant: 16),
            numOfReportButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        let middleSpacer = UIView()
        middleSpacer.backgroundColor = .clear
        stackView.addArrangedSubview(middleSpacer)
        
        stackView.addArrangedSubview(buyTicketStackView)
        NSLayoutConstraint.activate([
            buyTicketStackView.heightAnchor.constraint(equalToConstant: 48),
            buyTicketStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        return stackView
    }()
    @IBOutlet weak var thumbnailView: UIImageView! {
        didSet { thumbnailView.isUserInteractionEnabled = false }
    }
    
    private lazy var dateView: BadgeView = {
        let badgeView = BadgeView()
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.isUserInteractionEnabled = false
        badgeView.image = UIImage(systemName: "calendar")!
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        return badgeView
    }()
    private lazy var placeView: BadgeView = {
        let badgeView = BadgeView()
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.isUserInteractionEnabled = false
        badgeView.image = UIImage(systemName: "map.fill")!
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        return badgeView
    }()
    private lazy var buyTicketStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.spacing = 8
        
        stackView.addArrangedSubview(buyTicketButtonView)
        NSLayoutConstraint.activate([
            buyTicketButtonView.heightAnchor.constraint(equalTo: stackView.heightAnchor),
        ])
        
        stackView.addArrangedSubview(likeButton)
        NSLayoutConstraint.activate([
            likeButton.widthAnchor.constraint(equalToConstant: 120),
        ])
        
        return stackView
    }()
    private lazy var buyTicketButtonView: PrimaryButton = {
        let primaryButton = PrimaryButton(text: "")
        primaryButton.layer.cornerRadius = 24
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.isUserInteractionEnabled = true
        return primaryButton
    }()
    private lazy var numOfReportButton: CountButton = {
        let button = CountButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        
        button.listen { [unowned self] in
            self.listener(.numOfReportTapped)
        }
        
        return button
    }()
    private lazy var numOfLikeButton: CountButton = {
        let button = CountButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        
        button.listen { [unowned self] in
            self.listener(.numOfLikeTapped)
        }
        
        return button
    }()
    private lazy var likeButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 24
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()

    public override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        
        buyTicketButtonView.listen { [unowned self] in
            switch series {
            case .future: self.listener(.buyTicketButtonTapped)
            case .past: self.listener(.reportButtonTapped)
            case .all: break
            }
        }
        setup()
    }

    func inject(input: Input) {
        self.liveTitleLabel.text = input.live.live.title
        switch input.live.live.style {
        case .oneman(_):
            self.bandsLabel.text = input.live.live.hostGroup.name
        case .battle(let groups):
            self.bandsLabel.text = groups.map { $0.name }.joined(separator: ", ")
        case .festival(let groups):
            let groupNames = groups.map { $0.name }.prefix(3)
            self.bandsLabel.text = groupNames.joined(separator: ", ") + "..."
        }
        
        dateView.title = input.live.live.date?.toFormatString(from: "yyyyMMdd", to: "yyyy/MM/dd") ?? "未定"
        placeView.title = input.live.live.liveHouse ?? "未定"
        if let artworkURL = input.live.live.artworkURL ?? input.live.live.hostGroup.artworkURL {
            input.imagePipeline.loadImage(artworkURL, into: thumbnailView)
        } else {
            thumbnailView.image = nil
        }
        
        switch input.type {
        case .normal:
            numOfLikeButton.setTitle("参戦 \(input.live.likeCount)人", for: .normal)
            numOfReportButton.setTitle("感想 \(input.live.postCount)件", for: .normal)
            likeButton.isSelected = input.live.isLiked
            likeButton.isEnabled = true
            
            if let date = input.live.live.date, date >= Date().toFormatString(format: "yyyyMMdd") {
                self.series = .future
                buyTicketButtonView.isEnabled = input.live.live.piaEventUrl != nil
                buyTicketButtonView.setTitle("チケット申込", for: .normal)
            } else {
                self.series = .past
                buyTicketButtonView.isEnabled = true
                buyTicketButtonView.setTitle("感想を書く", for: .normal)
            }
            likeButtonStyle()
        case .review:
            buyTicketStackView.isHidden = true
        }
        
    }
    
    func likeButtonStyle() {
        switch self.series {
        case .future:
            if likeButton.isSelected {
                likeButton.setTitle("参戦予定！", for: .normal)
            } else {
                likeButton.setTitle("参戦する？", for: .normal)
            }
            
        case .past:
            if likeButton.isSelected {
                likeButton.setTitle("参戦済！", for: .normal)
            } else {
                likeButton.setTitle("参戦した？", for: .normal)
            }
            
        case .all: break
        }
    }

    func setup() {
        self.backgroundColor = .clear
        self.layer.borderWidth = 1
        self.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        self.layer.cornerRadius = 10
        
        self.liveTitleLabel.font = Brand.font(for: .xlargeStrong)
        self.liveTitleLabel.textColor = Brand.color(for: .text(.primary))
        self.liveTitleLabel.backgroundColor = .clear
        self.liveTitleLabel.lineBreakMode = .byTruncatingTail
        self.liveTitleLabel.numberOfLines = 0
        self.liveTitleLabel.adjustsFontSizeToFitWidth = false
        self.liveTitleLabel.sizeToFit()

        self.bandsLabel.font = Brand.font(for: .medium)
        self.bandsLabel.textColor = Brand.color(for: .text(.primary))
        self.bandsLabel.lineBreakMode = .byWordWrapping
        self.bandsLabel.numberOfLines = 0
        self.bandsLabel.adjustsFontSizeToFitWidth = false
        self.bandsLabel.sizeToFit()

        self.thumbnailView.contentMode = .scaleAspectFill
        self.thumbnailView.alpha = 0.2
        self.thumbnailView.backgroundColor = .clear
        self.thumbnailView.layer.cornerRadius = 10
        self.thumbnailView.clipsToBounds = true
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: bandsLabel.bottomAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16)
        ])
        
        addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
    }
    
    @objc private func numOfLikeTapped() {
        self.listener(.numOfLikeTapped)
    }
    
    @objc private func likeButtonTapped() {
//        likeButton.isSelected.toggle()
//        likeButtonStyle()
        likeButton.isEnabled = false
        self.listener(.likeButtonTapped)
    }
    
    @objc private func numOfReportTapped() {
        self.listener(.numOfReportTapped)
    }
    
    @objc private func reportButtonTapped() {
        self.listener(.reportButtonTapped)
    }
    
    @objc private func selfTapped() {
        self.listener(.selfTapped)
    }

    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
