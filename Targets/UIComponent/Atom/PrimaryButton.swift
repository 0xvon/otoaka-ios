//
//  PrimaryButton.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/21.
//

import UIKit

public final class PrimaryButton: UIButton {
    public enum Style {
        case normal
        case delete
    }
    
    public init(text: String) {
        super.init(frame: .zero)
        setup()
        setTitle(text, for: .normal)
    }
    
    public override var isEnabled: Bool {
        didSet {
            layer.opacity = isEnabled ? 1.0 : 0.6
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public func changeButtonStyle(_ style: Style) {
        switch style {
        case .normal:
            setTitleColor(Brand.color(for: .text(.button)), for: .normal)
        case .delete:
            setTitleColor(Brand.color(for: .text(.link)), for: .normal)
        }
    }

    func setup() {
        layer.cornerRadius = bounds.height / 2
        clipsToBounds = true
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)

        titleLabel?.font = Brand.font(for: .largeStrong)

        setBackgroundImage(Brand.color(for: .background(.button)).image(), for: .normal)
        setBackgroundImage(Brand.color(for: .background(.cellSelected)).image(), for: .highlighted)
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

fileprivate extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { context in
            self.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

#if PREVIEW
import SwiftUI

struct Button_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreviewWrapper(view: PrimaryButton(text: "Hello"))
                .previewLayout(.fixed(width: 180, height: 48))

            PreviewWrapper(view: {
                let button = PrimaryButton(text: "¥1500")
                button.setImage(BundleReference.image(named: "ticket"),
                                for: .normal)
                return button
            }())
            .previewLayout(.fixed(width: 150, height: 48))
            
            PreviewWrapper(view: {
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
