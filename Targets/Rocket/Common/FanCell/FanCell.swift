//
//  FanCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/08.
//

import UIKit
import Endpoint

final class FanCell: UITableViewCell, ReusableCell {
    typealias Input = User
    var input: Input!
    static var reusableIdentifier: String { "FanCell" }

    @IBOutlet weak var fanArtworkImageView: UIImageView!
    @IBOutlet weak var fanNameLabel: UILabel!
    @IBOutlet weak var biographyTextView: UITextView!

    func inject(input: Input) {
        self.input = input
        setup()
    }
    
    func setup() {
        backgroundColor = style.color.background.get()
        
        fanArtworkImageView.loadImageAsynchronously(url: URL(string: input.thumbnailURL!)!)
        fanArtworkImageView.clipsToBounds = true
        fanArtworkImageView.layer.cornerRadius = 30
        fanArtworkImageView.contentMode = .scaleAspectFill
        
        fanNameLabel.text = input.name
        fanNameLabel.font = style.font.large.get()
        fanNameLabel.backgroundColor = style.color.background.get()
        fanNameLabel.textColor = style.color.main.get()
        
        biographyTextView.text = input.biography
        biographyTextView.font = style.font.regular.get()
        biographyTextView.backgroundColor = style.color.background.get()
        biographyTextView.textColor = style.color.main.get()
    }
}
