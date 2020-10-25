//
//  TitleLabelView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/21.
//

import UIKit

final class TitleLabelView: UIView {
    
    typealias Input = String
    var input: Input!
    
    private var titleLabel: UILabel!
    
    init(input: Input) {
        self.input = input
        super.init(frame: .zero)
        self.inject(input: input)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
//        loadView()
    }
    
//    private func loadView() {
//        print("loadView")
//
//    }
    
    func inject(input: String) {
        self.input = input
        setup()
    }
    
    func setup() {
        self.backgroundColor = .clear
        let contentView = UIView(frame: self.frame)
        addSubview(contentView)
        
        contentView.backgroundColor = .clear
        contentView.layer.opacity = 0.8
        contentView.layer.cornerRadius = 24
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = style.color.main.get().cgColor
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        titleLabel.text = self.input
        titleLabel.textColor = style.color.main.get()
        titleLabel.font = style.font.xlarge.get()
        
        
        let constraints = [
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.rightAnchor.constraint(equalTo: rightAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 40)
        ]
        NSLayoutConstraint.activate(constraints)
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
