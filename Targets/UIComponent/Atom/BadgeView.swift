//
//  BadgeView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/22.
//

import UIKit

public final class BadgeView: UIView {
    private let badgeImageView: UIImageView = {
        let badgeImageView = UIImageView()
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        return badgeImageView
    }()
    private let badgeTitle: UILabel = {
        let badgeTitle = UILabel()
        badgeTitle.translatesAutoresizingMaskIntoConstraints = false
        badgeTitle.textColor = Brand.color(for: .text(.primary))
        badgeTitle.font = Brand.font(for: .mediumStrong)
        return badgeTitle
    }()

    public var image: UIImage? {
        get { badgeImageView.image }
        set { badgeImageView.image = newValue }
    }

    public var title: String? {
        get { badgeTitle.text }
        set { badgeTitle.text = newValue }
    }

    public init(text: String? = nil, image: UIImage? = nil) {
        super.init(frame: .zero)
        self.title = text
        self.image = image
        self.setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    @available(*, deprecated)
    public func updateText(text: String) {
        self.title = text
    }

    func setup() {
        backgroundColor = .clear
        layer.opacity = 0.8

        addSubview(badgeTitle)
        addSubview(badgeImageView)

        let constraints = [
            badgeImageView.leftAnchor.constraint(equalTo: leftAnchor),
            badgeImageView.widthAnchor.constraint(equalToConstant: 24),
            badgeImageView.heightAnchor.constraint(
                equalTo: badgeImageView.widthAnchor),
            badgeImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            badgeTitle.leftAnchor.constraint(equalTo: badgeImageView.rightAnchor, constant: 8),
            badgeTitle.centerYAnchor.constraint(equalTo: centerYAnchor),
            badgeTitle.rightAnchor.constraint(equalTo: rightAnchor),

        ]
        NSLayoutConstraint.activate(constraints)
    }
}

#if PREVIEW
import SwiftUI

struct BadgeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(
                view: BadgeView(text: "Hello", image: BundleReference.image(named: "ticket"))
            )
                .previewLayout(.fixed(width: 100, height: 60))
        }
        .background(Color.black)
    }
}
#endif
