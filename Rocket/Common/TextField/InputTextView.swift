//
//  InputTextView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/1.
//

import UIKit

final class InputTextView: UIView {

    typealias Input = String
    var input: Input!

    private var textView: UITextView!
    private var underLine: UIView!

    init(input: Input) {
        self.input = input
        super.init(frame: .zero)
        self.inject(input: input)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func inject(input: Input) {
        self.input = input
        setup()
    }

    func setup() {
        self.backgroundColor = .clear
        let contentView = UIView(frame: self.frame)
        addSubview(contentView)

        contentView.backgroundColor = .clear
        contentView.layer.opacity = 0.8
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        textView = UITextView()
        textView.returnKeyType = .done
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textColor = style.color.main.get()
        textView.font = style.font.regular.get()
        textView.text = self.input
        contentView.addSubview(textView)

        underLine = UIView()
        underLine.translatesAutoresizingMaskIntoConstraints = false
        underLineColor()
        contentView.addSubview(underLine)

        let constraints = [
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftAnchor.constraint(equalTo: contentView.leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),

            textView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            textView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            textView.topAnchor.constraint(equalTo: contentView.topAnchor),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            underLine.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            underLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            underLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            underLine.heightAnchor.constraint(equalToConstant: 1),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func underLineColor() {
        guard let text = textView.text else { return }
        if text.isEmpty {
            underLine.backgroundColor = style.color.subBackground.get()
        } else {
            underLine.backgroundColor = style.color.second.get()
        }
    }

    func getText() -> String? {
        return textView.text
    }

    func setText(text: String) {
        self.textView.text = text
        underLineColor()
    }
}

extension InputTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        underLine.backgroundColor = style.color.main.get()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        underLineColor()
    }
}
