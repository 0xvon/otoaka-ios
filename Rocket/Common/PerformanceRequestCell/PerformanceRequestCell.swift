//
//  PerformanceRequestCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import UIKit
import Endpoint

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
        self.layer.borderColor = style.color.main.get().cgColor
        self.layer.cornerRadius = 10
        
        liveArtworkImageView.loadImageAsynchronously(url: input.live.artworkURL)
        liveArtworkImageView.contentMode = .scaleAspectFill
        liveArtworkImageView.layer.opacity = 0.6
        liveArtworkImageView.layer.cornerRadius = 10
        liveArtworkImageView.clipsToBounds = true
        
        bandImageView.loadImageAsynchronously(url: input.live.hostGroup.artworkURL)
        liveArtworkImageView.contentMode = .scaleAspectFill
        liveArtworkImageView.layer.cornerRadius = 30
        liveArtworkImageView.clipsToBounds = true
        
        hostGroupNameLabel.text = input.live.hostGroup.name
        hostGroupNameLabel.font = style.font.regular.get()
        hostGroupNameLabel.textColor = style.color.main.get()
        hostGroupNameLabel.backgroundColor = .clear
        
        liveTitleLabel.text = input.live.title
        liveTitleLabel.font = style.font.xlarge.get()
        liveTitleLabel.textColor = style.color.main.get()
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
        performersLabel.font = style.font.regular.get()
        performersLabel.textColor = style.color.main.get()
        performersLabel.lineBreakMode = .byWordWrapping
        performersLabel.numberOfLines = 0
        performersLabel.adjustsFontSizeToFitWidth = false
        performersLabel.sizeToFit()
        
        bandButton.backgroundColor = .clear
        
        let date: String = (input.live.startAt != nil) ? dateFormatter.string(from: input.live.startAt!) : "時間未定"
        dateBadgeLabel.inject(input: (text: date, image: UIImage(named: "calendar")))
        livehouseBadgeView.inject(input: (text: "代々木公園", image: UIImage(named: "map")))
        ticketBadgeView.inject(input: (text: "￥1500", image: UIImage(named: "ticket")))
    }
    
    @IBAction func bandButtonTapped(_ sender: Any) {
        self.listener()
    }
    
    private var listener: () -> Void = {}
    func jumbToBandPage(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}
