//
//  ReactionButtonView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import UIKit

public final class ReactionButtonView: UIButton {
    public typealias Input = (
        text: String,
        image: UIImage?
    )

    @available(*, deprecated)
    public init(input: Input) {
        super.init(frame: .zero)
        self.inject(input: input)
    }
    
    public init(text: String, icon: UIImage) {
        super.init(frame: .zero)
        setup()
        setImage(icon, for: .normal)
        setTitle(text, for: .normal)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    @available(*, deprecated)
    public func inject(input: Input) {
        setImage(input.image, for: .normal)
        setTitle(input.text, for: .normal)
    }

    func setup() {
        backgroundColor = Brand.color(for: .background(.button))
        setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        setTitleColor(Brand.color(for: .text(.primary)).pressed(), for: .highlighted)
        titleLabel?.font = Brand.font(for: .small)
        contentHorizontalAlignment = .left
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
    }

    @available(*, deprecated)
    @objc private func reactionButtonTapped() {
        self.listener(.reaction)
    }
    
    @available(*, deprecated)
    @objc private func numButtonTapped() {
        self.listener(.num)
    }
    
    public enum ListenerType {
        case num
        case reaction
    }

    private var listener: (ListenerType) -> Void = { type in }
    public func listen(_ listener: @escaping (ListenerType) -> Void) {
        self.listener = listener
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct ReactionButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(
                view: ReactionButtonView(text: "¥1500", icon: BundleReference.image(named: "ticket"))
            )
            .previewLayout(.fixed(width: 150, height: 48))
        }
        .background(Color.blue)
    }
}
#endif
