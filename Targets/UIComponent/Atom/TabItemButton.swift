//
//  TabItemButton.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/21.
//

import UIKit

public final class TabItemButton: UIButton {
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    public override var isSelected: Bool {
        didSet { update() }
    }
    
    public override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        update()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public func update() {
//        backgroundColor = isSelected ? Brand.color(for: .background(.toggleSelected)) : Brand.color(for: .background(.primary))
        backgroundColor = Brand.color(for: .background(.toggleSelected))
        alpha = isSelected ? 1.0 : 0.4
        
        if let titleLabel = titleLabel, let titleImage = imageView {
            titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: -titleImage.bounds.size.width,
                bottom: -titleImage.bounds.size.height,
                right: 0
            )
            imageEdgeInsets = UIEdgeInsets(
                top: -titleLabel.bounds.size.height,
                left: 0,
                bottom: 0,
                right: -titleLabel.bounds.size.width
            )
        }
    }
    
    func setup() {
        clipsToBounds = true
        layer.masksToBounds = true
        titleLabel?.font = Brand.font(for: .mediumStrong)
        setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        setTitleColor(Brand.color(for: .text(.primary)), for: .selected)
    }
}
