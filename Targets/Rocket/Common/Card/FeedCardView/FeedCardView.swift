//
//  FeedCardView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/07.
//

import Foundation
import UIKit
import Endpoint

class FeedCardView: UIView {
    typealias Input = (
        feed: UserFeedSummary,
        artwork: URL?
    )
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var artworkImageViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func inject(input: Input) {
        if let profileImage = input.feed.author.thumbnailURL {
            profileImageView.image = UIImage(url: profileImage)
        }
        if let artistImage = input.feed.group.artworkURL {
            artistImageView.image = UIImage(url: artistImage.absoluteString)
        }
        if let artwork = input.artwork {
            artworkImageView.image = UIImage(url: artwork.absoluteString)
        }
        userNameLabel.text = input.feed.author.name
        artistNameLabel.text = input.feed.title
        textView.text = input.feed.text
    }
    
    func setup() {
        layer.cornerRadius = 16
        backgroundColor = Brand.color(for: .background(.primary))
        
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        userNameLabel.font = Brand.font(for: .smallStrong)
        userNameLabel.textColor = Brand.color(for: .text(.primary))
        
        artworkImageView.clipsToBounds = true
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.layer.opacity = 0.6
        
        artistImageView.layer.cornerRadius = 10
        artistImageView.clipsToBounds = true
        artistImageView.contentMode = .scaleAspectFill
        
        artistNameLabel.font = Brand.font(for: .smallStrong)
        artistNameLabel.textColor = Brand.color(for: .text(.primary))
        
        textView.font = Brand.font(for: .largeStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textAlignment = .left
        textView.isScrollEnabled = false
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        artworkImageViewHeightConstraint.constant = 330 / 1.91
    }
}
