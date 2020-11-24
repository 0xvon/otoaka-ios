//
//  BandBannerCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import UIKit
import Endpoint

class BandBannerCell: UITableViewCell, ReusableCell {
    
    static var reusableIdentifier: String { "BandBannerCell" }
    typealias Input = Group
    var input: Input!
    @IBOutlet weak var bandImageView: UIImageView!
    @IBOutlet weak var bandNameLabel: UILabel!
    @IBOutlet weak var likeButtonView: ReactionButtonView!
    @IBOutlet weak var listenButtonView: Button!
    
    func inject(input: Input) {
        self.input = input
        setup()
    }
    
    override func awakeFromNib() {
        superview?.awakeFromNib()
        backgroundColor = .clear
    }
    
    func setup() {        
        likeButtonView.inject(input: (text: "10000", image: UIImage(named: "heart")))
        listenButtonView.inject(input: (text: "曲を聴く", image: UIImage(named: "play")))
        
        bandImageView.image = UIImage(named: "band")
        bandImageView.layer.cornerRadius = 30
        bandImageView.layer.borderWidth = 1
        bandImageView.layer.borderColor = style.color.main.get().cgColor
        bandImageView.clipsToBounds = true
        
        bandNameLabel.text = input.name
        bandNameLabel.font = style.font.large.get()
        bandNameLabel.textColor = style.color.main.get()
        bandNameLabel.lineBreakMode = .byWordWrapping
        bandNameLabel.numberOfLines = 0
        bandNameLabel.adjustsFontSizeToFitWidth = false
        bandNameLabel.sizeToFit()
    }
    
    func listen(_ listener: @escaping () -> Void) {
        listenButtonView.listen(listener)
    }
    
    func like(_ listener: @escaping () -> Void) {
        likeButtonView.listen(listener)
    }
}
