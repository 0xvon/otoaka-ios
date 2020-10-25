//
//  BadgeView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/22.
//

import UIKit

final class BadgeView: UIView, ViewInstantiable {
    typealias Input = BadgeType
    static var xibName: String { "BadgeView" }
    
    var input: Input!
    enum BadgeType {
        case place(String)
        case date(String)
//        case production
//        case label
    }
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var badgeTitle: UILabel!
    
    func inject(input: BadgeType) {
        self.input = input
        setup()
    }
    
    func setup() {
        self.backgroundColor = .clear
        self.badgeTitle.textColor = style.color.main.get()
        self.badgeTitle.font = style.font.small.get()
        
        switch input {
        case .place(let placeText):
            badgeImageView.image = UIImage(named: "map")
            badgeTitle.text = placeText
        case .date(let dateText):
            badgeImageView.image = UIImage(named: "calendar")
            badgeTitle.text = dateText
        case .none:
            print("nyan")
        }
    }
}

//#if DEBUG && canImport(SwiftUI)
//import SwiftUI
//
//struct BadgeView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            ViewWrapper<BadgeView>(
//                input: .date("明日12時")
//            ).previewDisplayName("date")
//            ViewWrapper<BadgeView>(
//                input: .place("代々木公園")
//            ).previewDisplayName("place")
//        }
//        .previewLayout(.fixed(width: 150, height: 48))
//        .preferredColorScheme(.dark)
//        
//    }
//}
//#endif
