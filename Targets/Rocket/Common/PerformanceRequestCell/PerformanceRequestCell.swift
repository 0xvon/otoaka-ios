//
//  PerformanceRequestCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Endpoint
import UIKit

class PerformanceRequestCell: UITableViewCell, ReusableCell {
    static var reusableIdentifier: String { "PerformanceRequestCell" }

    typealias Input = PerformanceRequest
    var input: Input!
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日 HH:mm"
        return dateFormatter
    }()

    @IBOutlet weak var liveArtworkImageView: UIImageView!
    @IBOutlet weak var bandImageView: UIImageView!
    @IBOutlet weak var hostGroupNameLabel: UILabel!
    @IBOutlet weak var liveTitleLabel: UILabel!
    @IBOutlet weak var performersLabel: UILabel!
    @IBOutlet weak var livehouseBadgeView: BadgeView!
    @IBOutlet weak var dateBadgeLabel: BadgeView!
    @IBOutlet weak var ticketBadgeView: BadgeView!
    @IBOutlet weak var bandButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func inject(input: Input) {
        self.input = input
        setup()
    }

    func setup() {
        self.backgroundColor = .clear
        self.layer.borderWidth = 1
        self.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        self.layer.cornerRadius = 10

        liveArtworkImageView.loadImageAsynchronously(url: input.live.artworkURL)
        liveArtworkImageView.contentMode = .scaleAspectFill
        liveArtworkImageView.layer.opacity = 0.6
        liveArtworkImageView.layer.cornerRadius = 10
        liveArtworkImageView.clipsToBounds = true

        bandImageView.loadImageAsynchronously(url: input.live.hostGroup.artworkURL)
        bandImageView.contentMode = .scaleAspectFill
        bandImageView.layer.cornerRadius = 30
        bandImageView.clipsToBounds = true

        hostGroupNameLabel.text = "\(input.live.hostGroup.name)から"
        hostGroupNameLabel.font = Brand.font(for: .medium)
        hostGroupNameLabel.textColor = Brand.color(for: .text(.primary))
        hostGroupNameLabel.backgroundColor = .clear

        liveTitleLabel.text = input.live.title
        liveTitleLabel.font = Brand.font(for: .xlargeStrong)
        liveTitleLabel.textColor = Brand.color(for: .text(.primary))
        liveTitleLabel.backgroundColor = .clear
        liveTitleLabel.lineBreakMode = .byWordWrapping
        liveTitleLabel.numberOfLines = 0
        liveTitleLabel.adjustsFontSizeToFitWidth = false
        liveTitleLabel.sizeToFit()

        switch input.live.style {
        case .oneman(_):
            self.performersLabel.text = input.live.hostGroup.name
        case .battle(let groups):
            self.performersLabel.text = groups.map { $0.name }.joined(separator: ", ")
        case .festival(let groups):
            self.performersLabel.text = groups.map { $0.name }.joined(separator: ", ")
        }
        performersLabel.font = Brand.font(for: .medium)
        performersLabel.textColor = Brand.color(for: .text(.primary))
        performersLabel.lineBreakMode = .byWordWrapping
        performersLabel.numberOfLines = 0
        performersLabel.adjustsFontSizeToFitWidth = false
        performersLabel.sizeToFit()

        bandButton.backgroundColor = .clear

        let date: String =
            (input.live.startAt != nil) ? dateFormatter.string(from: input.live.startAt!) : "時間未定"
        dateBadgeLabel.title = date
        dateBadgeLabel.image = UIImage(named: "calendar")!
        livehouseBadgeView.title = input.live.liveHouse ?? "会場未定"
        livehouseBadgeView.image = UIImage(named: "map")!
        ticketBadgeView.title = "￥1500"
        ticketBadgeView.image = UIImage(named: "ticket")
    }

    @IBAction func bandButtonTapped(_ sender: Any) {
        self.listener()
    }

    private var listener: () -> Void = {}
    func jumbToBandPage(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}
