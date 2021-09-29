//
//  PerformanceRequestCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Endpoint
import UIKit
import ImagePipeline

class PerformanceRequestCell: UITableViewCell, ReusableCell {
    static var reusableIdentifier: String { "PerformanceRequestCell" }

    typealias Input = (request: PerformanceRequest, imagePipeline: ImagePipeline)
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
        setup()
        let imagePipeline = input.imagePipeline
        let input = input.request

        if let liveArtworkURL = input.live.artworkURL {
            imagePipeline.loadImage(liveArtworkURL, into: liveArtworkImageView)
        }
        if let hostGroupArtworkURL = input.live.hostGroup.artworkURL {
            imagePipeline.loadImage(hostGroupArtworkURL, into: bandImageView)
        }
        hostGroupNameLabel.text = "\(input.live.hostGroup.name)から"
        liveTitleLabel.text = input.live.title
        switch input.live.style {
        case .oneman(_):
            self.performersLabel.text = input.live.hostGroup.name
        case .battle(let groups):
            self.performersLabel.text = groups.map { $0.name }.joined(separator: ", ")
        case .festival(let groups):
            self.performersLabel.text = groups.map { $0.name }.joined(separator: ", ")
        }
        let date: String = input.live.startAt ?? "時間未定"
        dateBadgeLabel.title = date
        livehouseBadgeView.title = input.live.liveHouse ?? "会場未定"
    }

    func setup() {
        self.backgroundColor = .clear
        self.layer.borderWidth = 1
        self.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        self.layer.cornerRadius = 10

        liveArtworkImageView.contentMode = .scaleAspectFill
        liveArtworkImageView.layer.opacity = 0.6
        liveArtworkImageView.layer.cornerRadius = 10
        liveArtworkImageView.clipsToBounds = true
        
        bandImageView.contentMode = .scaleAspectFill
        bandImageView.layer.cornerRadius = 30
        bandImageView.clipsToBounds = true
        
        hostGroupNameLabel.font = Brand.font(for: .medium)
        hostGroupNameLabel.textColor = Brand.color(for: .text(.primary))
        hostGroupNameLabel.backgroundColor = .clear

        liveTitleLabel.font = Brand.font(for: .xlargeStrong)
        liveTitleLabel.textColor = Brand.color(for: .text(.primary))
        liveTitleLabel.backgroundColor = .clear
        liveTitleLabel.lineBreakMode = .byTruncatingTail
        liveTitleLabel.numberOfLines = 0
        liveTitleLabel.adjustsFontSizeToFitWidth = false
        liveTitleLabel.sizeToFit()

        performersLabel.font = Brand.font(for: .medium)
        performersLabel.textColor = Brand.color(for: .text(.primary))
        performersLabel.lineBreakMode = .byTruncatingTail
        performersLabel.numberOfLines = 0
        performersLabel.adjustsFontSizeToFitWidth = false
        performersLabel.sizeToFit()

        bandButton.backgroundColor = .clear


        dateBadgeLabel.image = UIImage(named: "calendar")!
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
