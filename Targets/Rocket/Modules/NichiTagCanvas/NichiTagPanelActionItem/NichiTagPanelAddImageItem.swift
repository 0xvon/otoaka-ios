//
//  NichiTagPanelAddImageItem.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/16.
//

import UIKit

public final class NichiTagPanelAddImageItem: UIButton {
    public init() {
        super.init(frame: .zero)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public override var isEnabled: Bool {
        didSet {
            layer.opacity = isEnabled ? 1.0 : 0.6
        }
    }
    
    func setup() {
        backgroundColor = .clear
        clipsToBounds = true
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        
        titleLabel?.font = Brand.font(for: .xxsmall)
        setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        
        setTitle("背景画像", for: .normal)
        setImage(UIImage(systemName: "photo")?.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal), for: .normal)
        
        self.alignVertical()
//        imageEdgeInsets = UIEdgeInsets(
//            top: -titleLabel!.bounds.size.height,
//            left: 0,
//            bottom: 0,
//            right: -titleLabel!.bounds.size.width
//        )
//        titleEdgeInsets = UIEdgeInsets(
//            top: 0,
//            left: -imageView!.bounds.size.width,
//            bottom: -imageView!.bounds.size.height,
//            right: 0
//        )
//        if let titleLabel = titleLabel, let titleImage = imageView {
//            titleEdgeInsets = UIEdgeInsets(top: 0,
//                                                  left: -titleImage.bounds.size.width,
//                                                  bottom: -titleImage.bounds.size.height,
//                                                  right: 0)
//            imageEdgeInsets = UIEdgeInsets(top: -titleLabel.bounds.size.height,
//                                                  left: 0,
//                                                  bottom: 0,
//                                                  right: -titleLabel.bounds.size.width)
//        }
    }
    
    @objc private func touchUpInside() {
        self.listener()
    }
    
    private var listener: () -> Void = {}
    public func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}

extension UIButton {
  func alignVertical(spacing: CGFloat = 6.0) {
    guard let imageSize = imageView?.image?.size,
      let text = titleLabel?.text,
      let font = titleLabel?.font
    else { return }

    titleEdgeInsets = UIEdgeInsets(
      top: 0.0,
      left: -imageSize.width,
      bottom: -(imageSize.height + spacing),
      right: 0.0
    )

    let titleSize = text.size(withAttributes: [.font: font])
    imageEdgeInsets = UIEdgeInsets(
      top: -(titleSize.height + spacing),
      left: 0.0,
      bottom: 0.0,
      right: -titleSize.width
    )

    let edgeOffset = abs(titleSize.height - imageSize.height) / 2.0
    contentEdgeInsets = UIEdgeInsets(
      top: edgeOffset,
      left: 0.0,
      bottom: edgeOffset,
      right: 0.0
    )
  }
}
