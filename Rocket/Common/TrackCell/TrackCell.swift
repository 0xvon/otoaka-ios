//
//  TrackCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import UIKit

final class TrackCell: UITableViewCell, ReusableCell {
    typealias Input = Void
    static var reusableIdentifier: String { "TrackCell" }
    var input: Input!
    
    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var releasedYearLabel: UILabel!
    @IBOutlet weak var bandNameLabel: UILabel!
    @IBOutlet weak var likeButtonView: ReactionButtonView!
    @IBOutlet weak var artWorkImageView: UIImageView!
    @IBOutlet weak var playImageView: UIImageView!
    @IBOutlet weak var bandThumbnailView: UIImageView!
    
    func inject(input: Input) {
        self.input = input
        setup()
    }
    
    func setup() {
        backgroundColor = style.color.background.get()
        trackTitleLabel.text = "不可逆リプレイス"
        trackTitleLabel.font = style.font.xlarge.get()
        trackTitleLabel.textColor = style.color.main.get()
        
        releasedYearLabel.text = "2016年"
        releasedYearLabel.font = style.font.small.get()
        releasedYearLabel.textColor = style.color.main.get()
        
        playImageView.image = UIImage(named: "play")
        
        artWorkImageView.image = UIImage(named: "track")
        artWorkImageView.layer.opacity = 0.6
        artWorkImageView.layer.cornerRadius = 16
        artWorkImageView.layer.borderWidth = 1
        artWorkImageView.layer.borderColor = style.color.main.get().cgColor
        artWorkImageView.clipsToBounds = true
        
        bandThumbnailView.image = UIImage(named: "band")
        bandThumbnailView.layer.cornerRadius = 30
        
        bandNameLabel.text = "MY FIRST STORY"
        bandNameLabel.font = style.font.regular.get()
        bandNameLabel.textColor = style.color.main.get()
        
        likeButtonView.inject(input: (text: "1,000,000", image: UIImage(named: "heart")))
        likeButtonView.listen {
            self.like()
        }
    }
    
    private func like() {
        print("like")
    }
    
    
}
