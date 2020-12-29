//
//  TrackCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import UIKit

final class TrackCell: UITableViewCell, ReusableCell {
    typealias Input = ChannelDetail.ChannelItem
    static var reusableIdentifier: String { "TrackCell" }
    var input: Input!

    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var releasedYearLabel: UILabel!
    @IBOutlet weak var bandNameLabel: UILabel!
    @IBOutlet weak var likeButtonView: ReactionIndicatorButton!
    @IBOutlet weak var artWorkImageView: UIImageView!
    @IBOutlet weak var playImageView: UIImageView!
    @IBOutlet weak var bandThumbnailView: UIImageView!

    func inject(input: Input) {
        self.input = input
        setup()
    }

    func setup() {
        backgroundColor = style.color.background.get()
        trackTitleLabel.text = input.snippet.title
        trackTitleLabel.font = style.font.xlarge.get()
        trackTitleLabel.textColor = style.color.main.get()

        releasedYearLabel.text = "20xx年"
        releasedYearLabel.font = style.font.small.get()
        releasedYearLabel.textColor = style.color.main.get()

        playImageView.image = UIImage(named: "play")

        artWorkImageView.loadImageAsynchronously(url: URL(string: input.snippet.thumbnails.high.url))
        artWorkImageView.layer.opacity = 0.6
        artWorkImageView.layer.cornerRadius = 16
        artWorkImageView.layer.borderWidth = 1
        artWorkImageView.layer.borderColor = style.color.main.get().cgColor
        artWorkImageView.clipsToBounds = true

        bandThumbnailView.image = UIImage(named: "band")
        bandThumbnailView.layer.cornerRadius = 30

        bandNameLabel.text = input.snippet.channelTitle
        bandNameLabel.font = style.font.regular.get()
        bandNameLabel.textColor = style.color.main.get()

        likeButtonView.inject(input: (text: "1,000,000", image: UIImage(named: "heart")))
        likeButtonView.listen { type in
            switch type {
            case .reaction:
                self.like()
            case .num:
                self.num()
            }
            
        }
    }

    private func like() {
        print("like")
    }
    
    private func num() {
        print("num")
    }

}
