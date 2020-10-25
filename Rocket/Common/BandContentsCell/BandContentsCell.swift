//
//  BandContentsCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import UIKit

class BandContentsCell: UITableViewCell, ReusableCell {
    static var reusableIdentifier: String { "BandContentsCell" }
    typealias Input = Void
    var input: Input!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var numOfViewers: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var playImageView: UIImageView!
    
    func inject(input: Input) {
        self.input = input
        setup()
    }
    
    func setup() {
        backgroundColor = style.color.background.get()
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = style.color.main.get().cgColor
        
        thumbnailImageView.image = UIImage(named: "live")
        thumbnailImageView.layer.opacity = 0.6
        
        titleLabel.text = "STORY TELLER TOUR 2020 TOKYO"
        titleLabel.font = style.font.large.get()
        titleLabel.textColor = style.color.main.get()
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = false
        titleLabel.sizeToFit()
        
        dateLabel.text = "2020/09/01"
        dateLabel.font = style.font.small.get()
        dateLabel.textColor = style.color.main.get()
        
        numOfViewers.text = "300,000 views"
        numOfViewers.font = style.font.small.get()
        numOfViewers.textColor = style.color.main.get()
        
        timeLabel.text = "4:32"
        timeLabel.font = style.font.small.get()
        timeLabel.textColor = style.color.main.get()
        
        playImageView.image = UIImage(named: "play")
    }
}
