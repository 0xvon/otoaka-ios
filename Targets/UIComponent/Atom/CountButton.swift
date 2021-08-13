//
//  CountButton.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/13.
//

import UIKit

public final class CountButton: UIButton {
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
        clipsToBounds = true
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        
        titleLabel?.font = Brand.font(for: .mediumStrong)
        titleLabel?.textColor = Brand.color(for: .background(.secondary))
        contentHorizontalAlignment = .left
        setTitleColor(Brand.color(for: .background(.secondary)), for: .normal)
        setTitleColor(Brand.color(for: .background(.secondary)).pressed(), for: .highlighted)
    }
    
    @objc private func touchUpInside() {
        self.listener()
    }

    private var listener: () -> Void = {}
    public func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}
