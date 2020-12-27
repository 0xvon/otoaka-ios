//
//  ToggleButton.swift
//  UIComponent
//
//  Created by kateinoigakukun on 2020/12/27.
//

import UIKit

public final class ToggleButton: UIButton {
    public init(text: String) {
        super.init(frame: .zero)
        setTitle(text, for: .normal)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private var titlesByIsSelected: [Bool: String] = [:]
    
    public override var isSelected: Bool {
        didSet { update() }
    }
    public override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }

    func update() {
        backgroundColor = isSelected ?
            Brand.color(for: .background(.toggleSelected)) : .clear
        let titleColor = isSelected ? Brand.color(for: .text(.primary)) :
            Brand.color(for: .text(.toggle))
        setTitleColor(titleColor, for: .normal)
        setTitleColor(titleColor.pressed(), for: .highlighted)
        setTitle(titlesByIsSelected[isSelected], for: .normal)
    }

    func setup() {
        clipsToBounds = true
        layer.cornerRadius = frame.height/2
        layer.borderWidth = 1
        layer.borderColor = Brand.color(for: .background(.toggleSelected)).cgColor
        titleLabel?.font = Brand.font(for: .mediumStrong)
        
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        
        update()
    }

    @objc private func touchUpInside() {
        isSelected = !isSelected
    }
    public func setTitle(_ title: String?, selected: Bool) {
        titlesByIsSelected[selected] = title
        update()
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct ToggleButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(view: ToggleButton(text: "+ フォロー"))
                .previewLayout(.fixed(width: 180, height: 48))
            ViewWrapper(view: {
                let button = ToggleButton(text: "フォロー中")
                button.isSelected = true
                return button
            }())
            .previewLayout(.fixed(width: 180, height: 48))
        }
        .background(Color.black)
    }
}
#endif
