//
//  BadgeView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/22.
//

import UIKit

final class BadgeView: UIView {
    typealias Input = (
        text: String,
        image: UIImage?
    )

    var input: Input!

    private var badgeImageView: UIImageView!
    private var badgeTitle: UILabel!

    init(input: Input) {
        self.input = input
        super.init(frame: .zero)
        self.inject(input: input)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func inject(input: Input) {
        self.input = input
        self.setup()
    }

    func updateText(text: String) {
        input.text = text
        badgeTitle.text = input.text
    }

    func setup() {
        backgroundColor = .clear
        let contentView = UIView(frame: self.frame)
        addSubview(contentView)

        contentView.backgroundColor = .clear
        contentView.layer.opacity = 0.8
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        badgeTitle = UILabel()
        badgeTitle.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeTitle)
        badgeTitle.textColor = style.color.main.get()
        badgeTitle.font = style.font.small.get()
        badgeTitle.text = input.text

        badgeImageView = UIImageView()
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeImageView)
        badgeImageView.image = input.image

        let constraints = [
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftAnchor.constraint(equalTo: contentView.leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),

            badgeImageView.leftAnchor.constraint(equalTo: leftAnchor),
            badgeImageView.widthAnchor.constraint(equalToConstant: 24),
            badgeImageView.heightAnchor.constraint(
                equalTo: badgeImageView.widthAnchor, multiplier: 1),
            badgeImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            badgeTitle.leftAnchor.constraint(equalTo: badgeImageView.rightAnchor, constant: 8),
            badgeTitle.centerYAnchor.constraint(equalTo: centerYAnchor),
            badgeTitle.rightAnchor.constraint(equalTo: rightAnchor),

        ]
        NSLayoutConstraint.activate(constraints)
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
