//
//  BandCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import DomainEntity
import UIKit
import UIComponent

final class BandCell: UITableViewCell, ReusableCell {
    typealias Input = Group
    var input: Input!
    static var reusableIdentifier: String { "BandCell" }

    @IBOutlet weak var bandName: UILabel!
    @IBOutlet weak var productionBadgeView: BadgeView!
    @IBOutlet weak var labelBadgeView: BadgeView!
    @IBOutlet weak var yearBadgeView: BadgeView!
    @IBOutlet weak var hometownBadgeView: BadgeView!
    @IBOutlet weak var jacketImageView: UIImageView!

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY年"
        return dateFormatter
    }()

    func inject(input: Input) {
        self.input = input
        setup()
    }

    func setup() {
        backgroundColor = Brand.color(for: .background(.primary))

        jacketImageView.loadImageAsynchronously(url: input.artworkURL)
        jacketImageView.layer.opacity = 0.6
        jacketImageView.layer.cornerRadius = 16
        jacketImageView.layer.borderWidth = 1
        jacketImageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        jacketImageView.clipsToBounds = true

        bandName.text = input.name
        bandName.font = Brand.font(for: .xlargeStrong)
        bandName.textColor = Brand.color(for: .text(.primary))

        productionBadgeView.isHidden = true
        productionBadgeView.inject(
            input: (text: "Japan Music Systems", image: UIImage(named: "production")))
        
        labelBadgeView.isHidden = true
        labelBadgeView.inject(input: (text: "Intact Records", image: UIImage(named: "record")))
        let startYear: String =
            (input.since != nil) ? dateFormatter.string(from: input.since!) : "不明"
        yearBadgeView.inject(input: (text: startYear, image: UIImage(named: "calendar")))
        hometownBadgeView.inject(
            input: (text: input.hometown ?? "不明", image: UIImage(named: "map")))
    }
}
