//
//  PrimaryButton.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/21.
//

import UIKit

public final class PrimaryButton: UIButton {
    public init(text: String) {
        super.init(frame: .zero)
        setup()
        setTitle(text, for: .normal)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        backgroundColor = Brand.color(for: .background(.button))
        layer.cornerRadius = bounds.height / 2
        clipsToBounds = true
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)

        titleLabel?.font = Brand.font(for: .largeStrong)
        setTitleColor(Brand.color(for: .text(.button)), for: .normal)
        setTitleColor(Brand.color(for: .text(.button)).pressed(), for: .highlighted)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
    }

    @objc private func touchUpInside() {
        self.listener()
    }

    private var listener: () -> Void = {}
    public func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct Button_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(view: PrimaryButton(text: "Hello"))
                .previewLayout(.fixed(width: 180, height: 48))

            ViewWrapper(view: {
                let button = PrimaryButton(text: "¥1500")
                button.setImage(BundleReference.image(named: "ticket"),
                                for: .normal)
                return button
            }())
            .previewLayout(.fixed(width: 150, height: 48))
            
            ViewWrapper(view: {
                let button = PrimaryButton(text: "再生")
                button.setImage(
                    UIImage(systemName: "play")!
                        .withTintColor(.white, renderingMode: .alwaysOriginal),
                    for: .normal)
                return button
            }())
            .previewLayout(.fixed(width: 150, height: 48))
        }
    }
}
#endif
