//
//  LiveCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/22.
//

import Endpoint
import UIKit

class LiveCell: UITableViewCell, ReusableCell {
    static var reusableIdentifier: String { "LiveCell" }

    typealias Input = Live
    var input: Input!
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日 HH:mm"
        return dateFormatter
    }()

    @IBOutlet weak var liveTitleLabel: UILabel!
    @IBOutlet weak var bandsLabel: UILabel!
    @IBOutlet weak var placeView: BadgeView!
    @IBOutlet weak var dateView: BadgeView!
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
    @IBOutlet weak var thumbnailView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func inject(input: Live) {
        self.input = input
        setup()
    }

    func setup() { 
        self.backgroundColor = .clear
        self.layer.borderWidth = 1
        self.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        self.layer.cornerRadius = 10

        self.liveTitleLabel.text = input.title
        self.liveTitleLabel.font = Brand.font(for: .xlargeStrong)
        self.liveTitleLabel.textColor = Brand.color(for: .text(.primary))
        self.liveTitleLabel.backgroundColor = .clear
        self.liveTitleLabel.lineBreakMode = .byWordWrapping
        self.liveTitleLabel.numberOfLines = 0
        self.liveTitleLabel.adjustsFontSizeToFitWidth = false
        self.liveTitleLabel.sizeToFit()

        switch input.style {
        case .oneman(_):
            self.bandsLabel.text = input.hostGroup.name
        case .battle(let groups):
            self.bandsLabel.text = groups.map { $0.name }.joined(separator: ", ")
        case .festival(let groups):
            self.bandsLabel.text = groups.map { $0.name }.joined(separator: ", ")
        }
        self.bandsLabel.font = Brand.font(for: .medium)
        self.bandsLabel.textColor = Brand.color(for: .text(.primary))
        self.bandsLabel.lineBreakMode = .byWordWrapping
        self.bandsLabel.numberOfLines = 0
        self.bandsLabel.adjustsFontSizeToFitWidth = false
        self.bandsLabel.sizeToFit()

        self.thumbnailView.loadImageAsynchronously(url: input.artworkURL)
        self.thumbnailView.contentMode = .scaleAspectFill
        self.thumbnailView.layer.opacity = 0.6
        self.thumbnailView.layer.cornerRadius = 10
        self.thumbnailView.clipsToBounds = true

        let date: String =
            (input.startAt != nil) ? dateFormatter.string(from: input.startAt!) : "時間未定"

        buyTicketButtonView.isHidden = true
        listenButtonView.isHidden = true
        dateView.title = date
        dateView.image = UIImage(named: "calendar")!
        placeView.title = input.liveHouse
        placeView.image = UIImage(named: "map")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func listen(_ listener: @escaping () -> Void) {
        listenButtonView.listen(listener)
    }

    func buyTicket(_ listener: @escaping () -> Void) {
        buyTicketButtonView.listen(listener)
    }
}
