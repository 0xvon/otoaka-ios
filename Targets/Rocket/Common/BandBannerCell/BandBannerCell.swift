//
//  BandBannerCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import Endpoint
import UIKit

class BandBannerCell: UITableViewCell, ReusableCell {

    static var reusableIdentifier: String { "BandBannerCell" }
    typealias Input = Group
    var input: Input!
    @IBOutlet weak var bandImageView: UIImageView!
    @IBOutlet weak var bandNameLabel: UILabel!
    @IBOutlet weak var likeButtonView: ReactionIndicatorButton!
    @IBOutlet weak var listenButtonView: PrimaryButton! {
        didSet {
            listenButtonView.setTitle("曲を聴く", for: .normal)
            listenButtonView.setImage(UIImage(named: "play"), for: .normal)
        }
    }

    func inject(input: Input) {
        self.input = input
        setup()
    }

    override func awakeFromNib() {
        superview?.awakeFromNib()
        backgroundColor = .clear
    }

    func setup() {
        likeButtonView.isHidden  = true
        likeButtonView.inject(input: (text: "10000", image: UIImage(named: "heart")))
        listenButtonView.isHidden = true
        selectionStyle = .none

        bandImageView.loadImageAsynchronously(url: input.artworkURL)
        bandImageView.layer.cornerRadius = 30
        bandImageView.layer.borderWidth = 1
        bandImageView.contentMode = .scaleAspectFill
        bandImageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        bandImageView.clipsToBounds = true

        bandNameLabel.text = input.name
        bandNameLabel.font = Brand.font(for: .largeStrong)
        bandNameLabel.textColor = Brand.color(for: .text(.primary))
        bandNameLabel.lineBreakMode = .byWordWrapping
        bandNameLabel.numberOfLines = 0
        bandNameLabel.adjustsFontSizeToFitWidth = false
        bandNameLabel.sizeToFit()
    }

    func listen(_ listener: @escaping () -> Void) {
        listenButtonView.listen(listener)
    }

    func like(_ listener: @escaping (ReactionIndicatorButton.ListenerType) -> Void) {
        likeButtonView.listen(listener)
    }
}
