//
//  ReactionButtonView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import UIKit

public final class ReactionIndicatorButton: UIButton {
    public typealias Input = (
        text: String,
        image: UIImage?
    )

    @available(*, deprecated)
    public init(input: Input) {
        super.init(frame: .zero)
        self.inject(input: input)
    }
    
    public init() {
        super.init(frame: .zero)
        setup()
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
    
    public override var intrinsicContentSize: CGSize {
        let originalContentSize = super.intrinsicContentSize
        let adjustedWidth = originalContentSize.width + titleEdgeInsets.left + titleEdgeInsets.right
        let adjustedHeight = originalContentSize.width + titleEdgeInsets.top + titleEdgeInsets.bottom
        return CGSize(width: adjustedWidth, height: adjustedHeight)
    }

    func setup() {
        layer.cornerRadius = bounds.height / 2
        clipsToBounds = true
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
                view: ReactionIndicatorButton(text: "1", icon: BundleReference.image(named: "ticket"))
            )
            ViewWrapper(
                view: {
                    let button = ReactionIndicatorButton(text: "1", icon: BundleReference.image(named: "ticket"))
                    let container = UIView()
                    container.addSubview(button)
                    button.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                        button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                        button.leftAnchor.constraint(greaterThanOrEqualTo: container.leftAnchor),
                        button.rightAnchor.constraint(greaterThanOrEqualTo: container.rightAnchor),
                        button.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
                        button.bottomAnchor.constraint(greaterThanOrEqualTo: container.bottomAnchor),
                    ])
                    return container
                }()
            )
        }
        .background(Color.blue)
        .previewLayout(.fixed(width: 150, height: 48))
    }
}
#endif
