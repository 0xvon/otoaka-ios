//
//  BandCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import UIKit

final class BandCell: UITableViewCell, ReusableCell {
    typealias Input = Void
    var input: Input!
    static var reusableIdentifier: String { "BandCell" }
    
    @IBOutlet weak var bandName: UILabel!
    @IBOutlet weak var productionBadgeView: BadgeView!
    @IBOutlet weak var labelBadgeView: BadgeView!
    @IBOutlet weak var yearBadgeView: BadgeView!
    @IBOutlet weak var hometownBadgeView: BadgeView!
    @IBOutlet weak var jacketImageView: UIImageView!
    
    func inject(input: Input) {
        self.input = input
        setup()
    }
    
    func setup() {
        backgroundColor = style.color.background.get()
        
        jacketImageView.image = UIImage(named: "jacket")
        jacketImageView.layer.opacity = 0.6
        jacketImageView.layer.cornerRadius = 16
        jacketImageView.layer.borderWidth = 1
        jacketImageView.layer.borderColor = style.color.main.get().cgColor
        jacketImageView.clipsToBounds = true
        
        bandName.text = "MY FIRST STORY"
        bandName.font = style.font.xlarge.get()
        bandName.textColor = style.color.main.get()
        
        productionBadgeView.inject(input: (text: "Japan Music Systems", image: UIImage(named: "production")))
        labelBadgeView.inject(input: (text: "Intact Records", image: UIImage(named: "record")))
        yearBadgeView.inject(input: (text: "2011年", image: UIImage(named: "calendar")))
        hometownBadgeView.inject(input: (text: "東京都", image: UIImage(named: "map")))
        
    }
}
