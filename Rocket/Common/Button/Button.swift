//
//  Button.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/21.
//

import UIKit

final class Button: UIView, ViewInstantiable {
    static var xibName: String { "Button" }
    typealias Input = type
    
    var input: Input!
    
    enum type {
        case listen
        case play
        case buyTicket
    }
    
    @IBOutlet weak var buttonImageView: UIImageView!
    @IBOutlet weak var buttonTitleLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func inject(input: type) {
        self.input = input
        self.layout()
    }
    
    func layout() {
        self.layer.cornerRadius = 16
        self.backgroundColor = style.color.background.get()
        self.layer.cornerRadius = 16
        self.layer.borderWidth = 1
        self.layer.borderColor = style.color.main.get().cgColor
        
        self.buttonImageView.tintColor = style.color.main
            .get()
        
        self.button.layer.cornerRadius = 16
        self.button.backgroundColor = .clear
        
        self.buttonTitleLabel.textColor = style.color.main.get()
        self.buttonTitleLabel.font = style.font.regular.get()
        
        switch self.input {
        case .buyTicket:
            self.buttonImageView.image = UIImage(systemName: "ticket")
            self.buttonTitleLabel.text = "チケット購入"
        case .listen:
            self.buttonImageView.image = UIImage(systemName: "play")
            self.buttonTitleLabel.text = "曲を聴く"
        case .play:
            self.buttonImageView.image = UIImage(systemName: "play")
            self.buttonTitleLabel.text = "再生"
        default:
            print("hoa")
        }
    }
    
    @IBAction func button(_ sender: Any) {
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct Button_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper<Button>(
                input: .listen
            ).previewDisplayName("listening")
            ViewWrapper<Button>(
                input: .play
            ).previewDisplayName("playing")
            ViewWrapper<Button>(
                input: .buyTicket
            ).previewDisplayName("ticketing")
        }
        .previewLayout(.fixed(width: 180, height: 48))
    }
}
#endif
