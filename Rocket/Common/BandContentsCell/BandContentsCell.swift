//
//  BandContentsCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import UIKit
import Endpoint

class BandContentsCell: UITableViewCell, ReusableCell {
    static var reusableIdentifier: String { "BandContentsCell" }
    typealias Input = ArtistFeedSummary
    var input: Input!
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var playImageView: UIImageView!
    @IBOutlet weak var commentButton: ReactionIndicatorButton! {
        didSet {
            commentButton.setImage(
                UIImage(systemName: "bubble.right")!
                    .withTintColor(.white, renderingMode: .alwaysOriginal),
                for: .normal
            )

        }
    }

    func inject(input: Input) {
        self.input = input
        setup()
    }

    func setup() {
        backgroundColor = style.color.background.get()
        
        switch input.feedType {
        case .youtube(let url):
            let youTubeClient = YouTubeClient(url: url.absoluteString)
            let thumbnail = youTubeClient.getThumbnailUrl()
            thumbnailImageView.loadImageAsynchronously(url: thumbnail)
        }
        thumbnailImageView.layer.opacity = 0.6
        thumbnailImageView.layer.cornerRadius = 16
        thumbnailImageView.layer.borderWidth = 1
        thumbnailImageView.layer.borderColor = style.color.main.get().cgColor

        titleLabel.text = input.text
        titleLabel.font = style.font.large.get()
        titleLabel.textColor = style.color.main.get()
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = false
        titleLabel.sizeToFit()

        dateLabel.text = dateFormatter.string(from: input.createdAt)
        dateLabel.font = style.font.small.get()
        dateLabel.textColor = style.color.main.get()
        
        artistNameLabel.text = input.author.name
        artistNameLabel.font = style.font.regular.get()
        artistNameLabel.textColor = style.color.main.get()

        commentButton.setTitle("\(input.commentCount)", for: .normal)

        playImageView.image = UIImage(named: "play")
        playImageView.layer.opacity = 0.6
    }
    
    func comment(_ listener: @escaping (ReactionIndicatorButton.ListenerType) -> Void) {
        commentButton.listen(listener)
    }
}
