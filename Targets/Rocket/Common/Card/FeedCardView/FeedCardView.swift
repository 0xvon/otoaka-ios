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
        post: Post,
        artwork: URL?
    )
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var artworkImageViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func inject(input: Input) {
        if let profileImage = input.post.author.thumbnailURL {
            profileImageView.image = UIImage(url: profileImage)
        }
//        if let liveImage = input.post.live?.artworkURL {
//            artistImageView.image = UIImage(url: liveImage.absoluteString)
//        }
        if let artwork = input.post.live?.artworkURL {
            artworkImageView.image = UIImage(url: artwork.absoluteString)
        }
        userNameLabel.text = input.post.author.name
        artistNameLabel.text = input.post.live?.title
        textView.text = input.post.text
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
