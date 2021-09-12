//
//  FloatingButtonItem.swift
//  UIComponent
//
//  Created by kateinoigakukun on 2020/12/27.
//

import UIKit

public final class FloatingButtonItem: UIButton {

    public init(icon: UIImage) {
        super.init(frame: .zero)
        setup()
        setImage(icon, for: .normal)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public override var bounds: CGRect {
        didSet {
            layer.cornerRadius = bounds.width / 2
        }
    }

    public var isRotating: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.transform = self.transformation()
            }
        }
    }
    public override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.transform = self.transformation()
            }
        }
    }

    private func transformation() -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        if isRotating {
            transform = transform.rotated(by: .pi * 3 / 4)
        }
        if isHighlighted {
            transform = transform.scaledBy(x: 0.8, y: 0.8)
        }
        return transform
    }

    func setup() {
        layer.cornerRadius = bounds.width / 2
        backgroundColor = Brand.color(for: .background(.button))

        contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        imageView?.contentMode = .scaleAspectFit
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 60),
            widthAnchor.constraint(equalTo: heightAnchor),
        ])
    }
}

#if PREVIEW
import SwiftUI

struct FloatingButtonItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreviewWrapper(
                view: FloatingButtonItem(
                    icon: UIImage(systemName: "plus")!
                        .withTintColor(.white, renderingMode: .alwaysOriginal)
                )
            )
                .previewLayout(.fixed(width: 60, height: 60))
        }
        .background(Color.black)
    }
}
#endif
