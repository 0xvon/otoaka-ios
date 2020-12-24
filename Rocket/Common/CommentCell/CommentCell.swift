//
//  CommentCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/18.
//

import UIKit
import Endpoint

class CommentCell: UITableViewCell, ReusableCell {
    typealias Input = ArtistFeedComment
    static var reusableIdentifier: String { "CommentCell" }
    var input: Input!

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()
    
    func inject(input: Input) {
        self.input = input
        setup()
    }
    
    func setup() {
        backgroundColor = style.color.background.get()
        
        if let thumbnailUrl = input.author.thumbnailURL {
            thumbnailImageView.loadImageAsynchronously(url: URL(string: thumbnailUrl))
        }
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 32
        
        nameLabel.text = input.author.name
        nameLabel.font = style.font.large.get()
        nameLabel.textColor = style.color.main.get()
        
        dateLabel.text = dateFormatter.string(from: input.createdAt)
        dateLabel.font = style.font.small.get()
        dateLabel.textColor = style.color.main.get()
        
        commentTextView.text = input.text
        commentTextView.font = style.font.regular.get()
        commentTextView.backgroundColor = .clear
        commentTextView.textColor = style.color.main.get()
    }
}
