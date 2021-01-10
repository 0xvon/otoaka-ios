//
//  LiveCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/22.
//

import Endpoint
import UIKit
import ImagePipeline

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
        // Proxy tap event to tableView(_:didSelectRowAt:)
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
}

class LiveCellContent: UIButton {
    typealias Input = (
        live: Live,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case listenButtonTapped
        case buyTicketButtonTapped
    }
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日 HH:mm"
        return dateFormatter
    }()

    @IBOutlet weak var liveTitleLabel: UILabel!
    @IBOutlet weak var bandsLabel: UILabel!
    @IBOutlet weak var placeView: BadgeView! {
        didSet { placeView.isUserInteractionEnabled = false }
    }
    @IBOutlet weak var dateView: BadgeView! {
        didSet { dateView.isUserInteractionEnabled = false }
    }
    @IBOutlet weak var listenButtonView: PrimaryButton! {
        didSet {
            listenButtonView.setTitle("曲を聴く", for: .normal)
            listenButtonView.setImage(UIImage(named: "play"), for: .normal)
        }
    }
    @IBOutlet weak var buyTicketButtonView: PrimaryButton! {
        didSet {
            buyTicketButtonView.setTitle("チケット購入", for: .normal)
            buyTicketButtonView.setImage(UIImage(named: "ticket"), for: .normal)
        }
    }
    @IBOutlet weak var thumbnailView: UIImageView! {
        didSet { thumbnailView.isUserInteractionEnabled = false }
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        listenButtonView.listen { [unowned self] in
            self.listener(.listenButtonTapped)
        }
        buyTicketButtonView.listen { [unowned self] in
            self.listener(.buyTicketButtonTapped)
        }
        setup()
    }

    func inject(input: Input) {
        self.liveTitleLabel.text = input.live.title
        switch input.live.style {
        case .oneman(_):
            self.bandsLabel.text = input.live.hostGroup.name
        case .battle(let groups):
            self.bandsLabel.text = groups.map { $0.name }.joined(separator: ", ")
        case .festival(let groups):
            self.bandsLabel.text = groups.map { $0.name }.joined(separator: ", ")
        }
        
        dateView.title = input.live.startAt.map { dateFormatter.string(from: $0) } ?? "時間未定"
        placeView.title = input.live.liveHouse ?? "会場未定"
        if let artworkURL = input.live.artworkURL {
            input.imagePipeline.loadImage(artworkURL, into: thumbnailView)
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
        self.thumbnailView.layer.opacity = 0.6
        self.thumbnailView.layer.cornerRadius = 10
        self.thumbnailView.clipsToBounds = true

        buyTicketButtonView.isHidden = true
        listenButtonView.isHidden = true

        dateView.image = UIImage(named: "calendar")!
        placeView.image = UIImage(named: "map")
    }

    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
