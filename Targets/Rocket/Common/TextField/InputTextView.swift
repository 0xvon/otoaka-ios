//
//  InputTextView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/1.
//

import UIKit

final class InputTextView: UIView {

    typealias Input = (
        section: String,
        text: String?,
        maxLength: Int
    )
    var input: Input!

    private var textView: UITextView!
    private var section: UILabel!
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
        
        section = UILabel()
        section.translatesAutoresizingMaskIntoConstraints = false
        section.text = input.section
        section.textColor = Brand.color(for: .text(.toggle))
        section.font = Brand.font(for: .medium)
        contentView.addSubview(section)

        textView = UITextView()
        textView.delegate = self
        textView.returnKeyType = .done
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textColor = Brand.color(for: .text(.primary))
        textView.font = Brand.font(for: .medium)
        textView.text = input.text
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
            
            section.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            section.topAnchor.constraint(equalTo: contentView.topAnchor),
            section.rightAnchor.constraint(equalTo: contentView.rightAnchor),

            textView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            textView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            textView.topAnchor.constraint(equalTo: section.bottomAnchor),
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
            underLine.backgroundColor = Brand.color(for: .text(.primary))
        } else {
            underLine.backgroundColor = Brand.color(for: .text(.toggle))
        }
    }

    func getText() -> String? {
        return textView.text
    }

    func setText(text: String) {
        self.textView.text = text
        underLineColor()
    }
    
    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}

extension InputTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        underLine.backgroundColor = Brand.color(for: .text(.primary))
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.listener()
        underLineColor()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textView.text = textView.text.prefix(input.maxLength).description
        underLineColor()
    }
}
