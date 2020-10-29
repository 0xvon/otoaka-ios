//
//  AccountCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/29.
//

import UIKit

class AccountCell: UITableViewCell, ReusableCell {
    static var reusableIdentifier: String { "AccountCell" }
    typealias Input = (
        title: String,
        image: UIImage?
    )
    var input: Input!
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var notifView: UIView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    
    func inject(input: Input) {
        self.input = input
        setup()
    }
    
    func setup() {
        backgroundColor = .clear
        preservesSuperviewLayoutMargins = false
        separatorInset = .zero
        layoutMargins = .zero        
        
        itemImageView.image = input.image
        
        itemTitleLabel.text = input.title
        itemTitleLabel.textColor = style.color.main.get()
        itemTitleLabel.font = style.font.regular.get()
        
        notifView.backgroundColor = style.color.second.get()
        notifView.layer.cornerRadius = 5
    }
}
