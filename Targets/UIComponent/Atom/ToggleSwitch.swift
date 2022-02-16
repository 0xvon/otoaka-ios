//
//  ToggleSwitch.swift
//  UIComponent
//
//  Created by Masato TSUTSUMI on 2022/02/16.
//

import UIKit

public final class ToggleSwitch: UIStackView {
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.font = Brand.font(for: .xsmall)
        label.textAlignment = .left
        return label
    }()
    private let switchButton: UISwitch = {
        let switchButton = UISwitch()
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.onTintColor = Brand.color(for: .brand(.primary))
        switchButton.isOn = true
        switchButton.addTarget(self, action: #selector(switchButtonTapped), for: .touchUpInside)
        return switchButton
    }()
    
    public init(title: String) {
        super.init(frame: .zero)
        label.text = title
        setup()
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setTitle(_ text: String) {
        label.text = text
    }
    
    public func isOn() -> Bool {
        return switchButton.isOn
    }
    
    func setup() {
        axis = .horizontal
        spacing = 4
        addArrangedSubview(label)
        addArrangedSubview(switchButton)
    }
    
    @objc private func switchButtonTapped() {
        self.listener(switchButton.isOn)
    }
    
    private var listener: (Bool) -> Void = { _ in }
    public func listen(_ listener: @escaping (Bool) -> Void) {
        self.listener = listener
    }
}
