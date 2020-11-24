//
//  BandCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import UIKit
import Endpoint

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
        dateFormatter.dateFormat = "YY年"
        return dateFormatter
    }()
    
    func inject(input: Input) {
        self.input = input
        setup()
    }
    
    func setup() {
        backgroundColor = style.color.background.get()
        
        jacketImageView.loadImageAsynchronously(url: input.artworkURL)
        jacketImageView.layer.opacity = 0.6
        jacketImageView.layer.cornerRadius = 16
        jacketImageView.layer.borderWidth = 1
        jacketImageView.layer.borderColor = style.color.main.get().cgColor
        jacketImageView.clipsToBounds = true
        
        bandName.text = input.name
        bandName.font = style.font.xlarge.get()
        bandName.textColor = style.color.main.get()
        
        productionBadgeView.inject(input: (text: "Japan Music Systems", image: UIImage(named: "production")))
        labelBadgeView.inject(input: (text: "Intact Records", image: UIImage(named: "record")))
        let startYear: String = (input.since != nil) ? dateFormatter.string(from: input.since!) : "不明"
        yearBadgeView.inject(input: (text: startYear, image: UIImage(named: "calendar")))
        hometownBadgeView.inject(input: (text: input.hometown ?? "不明", image: UIImage(named: "map")))
    }
}
