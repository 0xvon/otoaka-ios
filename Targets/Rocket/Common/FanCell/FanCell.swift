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
        backgroundColor = Brand.color(for: .background(.primary))
        
        fanArtworkImageView.loadImageAsynchronously(url: URL(string: input.thumbnailURL!)!)
        fanArtworkImageView.clipsToBounds = true
        fanArtworkImageView.layer.cornerRadius = 30
        fanArtworkImageView.contentMode = .scaleAspectFill
        
        fanNameLabel.text = input.name
        fanNameLabel.font = Brand.font(for: .largeStrong)
        fanNameLabel.backgroundColor = Brand.color(for: .background(.primary))
        fanNameLabel.textColor = Brand.color(for: .text(.primary))
        
        biographyTextView.text = input.biography
        biographyTextView.isUserInteractionEnabled = false
        biographyTextView.font = Brand.font(for: .medium)
        biographyTextView.backgroundColor = Brand.color(for: .background(.primary))
        biographyTextView.textColor = Brand.color(for: .text(.primary))
    }
}
