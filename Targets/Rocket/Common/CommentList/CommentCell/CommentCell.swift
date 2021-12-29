//
//  CommentCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/18.
//

import UIKit
import Endpoint
import ImagePipeline

class CommentCell: UITableViewCell, ReusableCell {
    typealias Input = (comment: Comment, imagePipeline: ImagePipeline)
    static var reusableIdentifier: String { "CommentCell" }

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    
    private lazy var editButton: UIButton = { // TODO
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "ellipsis")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        return button
    }()
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()
    
    func inject(input: Input) {
        setup()
        if let thumbnailURL = input.comment.author.thumbnailURL.flatMap(URL.init(string: )) {
            input.imagePipeline.loadImage(thumbnailURL, into: thumbnailImageView)
        }
        nameLabel.text = input.comment.author.name
        dateLabel.text = dateFormatter.string(from: input.comment.createdAt)
        commentTextView.text = input.comment.text
    }

    func setup() {
        backgroundColor = Brand.color(for: .background(.primary))

        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.layer.cornerRadius = 32
        
        nameLabel.font = Brand.font(for: .largeStrong)
        nameLabel.textColor = Brand.color(for: .text(.primary))

        dateLabel.font = Brand.font(for: .small)
        dateLabel.textColor = Brand.color(for: .text(.primary))

        commentTextView.font = Brand.font(for: .medium)
        commentTextView.backgroundColor = .clear
        commentTextView.textColor = Brand.color(for: .text(.primary))
    }
}
