//
//  TitleLabelView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/21.
//

import UIKit

final class TitleLabelView: UIView, ViewInstantiable {
    static var xibName: String { "TitleLabelView" }
    
    typealias Input = String
    var input: Input!
    
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func inject(input: String) {
        self.input = input
        setup()
    }
    
    func setup() {
        self.backgroundColor = .clear
        titleLabel.text = self.input
        titleLabel.textColor = style.color.main.get()
        titleLabel.font = style.font.xlarge.get()
    }
}

//#if DEBUG && canImport(SwiftUI)
//import SwiftUI
//
//struct TitleLabelView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            ViewWrapper<TitleLabelView>(input: "LIVE").previewDisplayName("LIVE")
//            ViewWrapper<TitleLabelView>(input: "CONTENTS").previewDisplayName("CONTENTS")
//            ViewWrapper<TitleLabelView>(input: "SETLIST").previewDisplayName("SETLIST")
//            ViewWrapper<TitleLabelView>(input: "BAND(100)").previewDisplayName("BAND")
//            ViewWrapper<TitleLabelView>(input: "吾輩は猫である").previewDisplayName("Japanese")
//        }
//        .previewLayout(.fixed(width: 300, height: 70))
//        .preferredColorScheme(.dark)
//    }
//}
//#endif
