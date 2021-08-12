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
        backgroundColor = .clear
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            _contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            _contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            _contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
            _contentView.heightAnchor.constraint(equalToConstant: 350),
        ])
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func inject(input: LiveCellContent.Input) {
        _contentView.inject(input: input)
        switch input.type {
        case .normal: _contentView.isUserInteractionEnabled = true
        case .review: _contentView.isUserInteractionEnabled = false
        }
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

class LiveCellContent: UIButton {
    typealias Input = (
        live: LiveFeed,
        imagePipeline: ImagePipeline,
        type: LiveCellContentType
    )
    
    enum LiveCellContentType {
        case normal
        case review
    }
    enum Output {
        case likeButtonTapped
        case numOfLikeTapped
        case reportButtonTapped
        case numOfReportTapped
        case buyTicketButtonTapped
    }
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"
        return dateFormatter
    }()
    let displayDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()

    @IBOutlet weak var liveTitleLabel: UILabel!
    @IBOutlet weak var bandsLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var thumbnailView: UIImageView! {
        didSet { thumbnailView.isUserInteractionEnabled = false }
    }
    
    private lazy var dateView: BadgeView = {
        let badgeView = BadgeView()
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.isUserInteractionEnabled = false
        badgeView.image = UIImage(named: "calendar")
        return badgeView
    }()
    private lazy var placeView: BadgeView = {
        let badgeView = BadgeView()
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.isUserInteractionEnabled = false
        badgeView.image = UIImage(named: "map")
        return badgeView
    }()
    private lazy var buyTicketStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.spacing = 4
        
        stackView.addArrangedSubview(buyTicketButtonView)
        NSLayoutConstraint.activate([
            buyTicketButtonView.heightAnchor.constraint(equalTo: stackView.heightAnchor)
        ])
        
//        let buyTicketButtonSpacer = UIView()
//        buyTicketButtonSpacer.translatesAutoresizingMaskIntoConstraints = false
//        buyTicketButtonSpacer.backgroundColor = .clear
//        stackView.addArrangedSubview(buyTicketButtonSpacer)
        
        return stackView
    }()
    private lazy var buyTicketButtonView: PrimaryButton = {
        let primaryButton = PrimaryButton(text: "チケット応募")
        primaryButton.layer.cornerRadius = 24
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.isUserInteractionEnabled = true
        primaryButton.setImage(UIImage(named: "ticket"), for: .normal)
        return primaryButton
    }()
    private lazy var actionButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        stackView.addArrangedSubview(likeButton)
        stackView.addArrangedSubview(reportButton)
        
        return stackView
    }()
    private lazy var numOfLikeView: CountSummaryView = {
        let summaryView = CountSummaryView()
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        summaryView.isUserInteractionEnabled = true
        summaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(numOfLikeTapped))
        )
        return summaryView
    }()
    private lazy var likeButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 24
        button.setTitle("行きたい", selected: false)
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var actionCountStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        
        stackView.addArrangedSubview(numOfLikeView)
        stackView.addArrangedSubview(numOfReportView)
        
        return stackView
    }()
    private lazy var numOfReportView: CountSummaryView = {
        let summaryView = CountSummaryView()
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        summaryView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(numOfReportTapped))
        )
        return summaryView
    }()
    private lazy var reportButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 24
        button.setTitle("レポートを書く", selected: false)
        button.addTarget(self, action: #selector(reportButtonTapped), for: .touchUpInside)
        return button
    }()

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        buyTicketButtonView.listen { [unowned self] in
            self.listener(.buyTicketButtonTapped)
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
            self.bandsLabel.text = groups.map { $0.name }.joined(separator: ", ")
        }
        
        if let date = input.live.live.date, let openAt = input.live.live.openAt, let formatted = dateFormatter.date(from: date) {
            let formattedDateString = displayDateFormatter.string(from: formatted)
            dateView.title = "\(formattedDateString) \(openAt)"
        }
        placeView.title = input.live.live.liveHouse ?? "未定"
        if let artworkURL = input.live.live.artworkURL {
            input.imagePipeline.loadImage(artworkURL, into: thumbnailView)
        } else {
            thumbnailView.image = nil
        }
        
        switch input.type {
        case .normal:
            numOfLikeView.update(input: (title: "", count: input.live.likeCount))
            likeButton.setTitle("行きたい", selected: input.live.isLiked)
            likeButton.isSelected = input.live.isLiked
            numOfReportView.update(input: (title: "", count: input.live.postCount))
        case .review:
            buyTicketStackView.isHidden = true
            actionButtonStackView.isHidden = true
            actionCountStackView.isHidden = true
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
        self.liveTitleLabel.lineBreakMode = .byWordWrapping
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

        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.backgroundColor = .clear
        
        stackView.addArrangedSubview(dateView)
        NSLayoutConstraint.activate([
            dateView.heightAnchor.constraint(equalToConstant: 20),
            dateView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(placeView)
        NSLayoutConstraint.activate([
            placeView.heightAnchor.constraint(equalToConstant: 20),
            placeView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        let middleSpacer = UIView()
        middleSpacer.backgroundColor = .clear
        stackView.addArrangedSubview(middleSpacer)
        
        stackView.addArrangedSubview(buyTicketStackView)
        NSLayoutConstraint.activate([
            buyTicketStackView.heightAnchor.constraint(equalToConstant: 48),
            buyTicketStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(actionButtonStackView)
        NSLayoutConstraint.activate([
            actionButtonStackView.heightAnchor.constraint(equalToConstant: 48),
            actionButtonStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(actionCountStackView)
        NSLayoutConstraint.activate([
            actionCountStackView.heightAnchor.constraint(equalToConstant: 24),
            actionCountStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
    }
    
    @objc private func numOfLikeTapped() {
        self.listener(.numOfLikeTapped)
    }
    
    @objc private func likeButtonTapped() {
        self.listener(.likeButtonTapped)
    }
    
    @objc private func numOfReportTapped() {
        self.listener(.numOfReportTapped)
    }
    
    @objc private func reportButtonTapped() {
        self.listener(.reportButtonTapped)
    }

    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
