//
//  PostView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/03/05.
//

import UIKit
import UITextView_Placeholder
import UIComponent

final class PostView: UIStackView {
    enum Output {
        case textDidChange(String?)
        case toggleIsPrivate(Bool)
        case buttonTapped
    }
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.placeholder = "あなたにとってどんなライブでしたか？\nライブの様子や感想を記録しよう！\nマイレポートはあなただけのものです。"
        textView.placeholderColor = Brand.color(for: .background(.light))
        textView.font = Brand.font(for: .mediumStrong)
        textView.textColor = Brand.color(for: .text(.primary))
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .left
        textView.layer.cornerRadius = 16
        textView.layer.borderColor = Brand.color(for: .brand(.primary)).cgColor
        textView.layer.borderWidth = 2
        textView.returnKeyType = .done
        NSLayoutConstraint.activate([
            textView.heightAnchor.constraint(equalToConstant: 140),
        ])
        return textView
    }()
    private lazy var toggleSwitch: ToggleSwitch = {
        let toggleSwitch = ToggleSwitch(title: "公開")
        toggleSwitch.listen { [unowned self] isOn in
            self.listener(.toggleIsPrivate(!isOn))
        }
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        return toggleSwitch
    }()
    private lazy var bottomStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = 8
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer)
        
        stackView.addArrangedSubview(toggleSwitch)
        NSLayoutConstraint.activate([
            toggleSwitch.widthAnchor.constraint(equalToConstant: 80),
        ])
        
        stackView.addArrangedSubview(postButton)
        NSLayoutConstraint.activate([
//            postButton.heightAnchor.constraint(equalToConstant: 24),
            postButton.widthAnchor.constraint(equalToConstant: 120),
        ])
        
        return stackView
    }()
    private let postButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isSelected = true
        button.setTitle("投稿", for: .normal)
        button.addTarget(self, action: #selector(postButtonTapped), for: .touchUpInside)
        return button
    }()
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        backgroundColor = .clear
        axis = .vertical
        spacing = 12
        
        addArrangedSubview(textView)
        addArrangedSubview(bottomStackView)
        
        textView.delegate = self
    }
    
    public func setText(_ text: String?) {
        textView.text = text
        postButton.isEnabled = (text != nil)
    }
    
    @objc private func postButtonTapped() {
        postButton.isEnabled = false
        self.listener(.buttonTapped)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}

extension PostView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        let message: String? = textView.text.isEmpty ? nil : textView.text
        postButton.isEnabled = message != nil
        self.listener(.textDidChange(message))
    }
}
