//
//  CommentCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/18.
//

import UIKit
import Endpoint

class CommentCell: UITableViewCell, ReusableCell {
    typealias Input = String
    static var reusableIdentifier: String { "CommentCell" }
    var input: Input!

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    
    func inject(input: Input) {
        self.input = input
        setup()
    }
    
    func setup() {
        backgroundColor = style.color.background.get()
        
        thumbnailImageView.image = UIImage(named: "band")
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 32
        
        nameLabel.text = "jiro"
        nameLabel.font = style.font.large.get()
        nameLabel.textColor = style.color.main.get()
        
        dateLabel.text = "2h"
        dateLabel.font = style.font.small.get()
        dateLabel.textColor = style.color.main.get()
        
        commentTextView.text = "うーーーーん良いね！"
        commentTextView.font = style.font.regular.get()
        commentTextView.backgroundColor = .clear
        commentTextView.textColor = style.color.main.get()
    }
}
