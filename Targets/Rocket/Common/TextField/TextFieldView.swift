//
//  TextFieldView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/31.
//

import UIKit

final class TextFieldView: UIView {

    typealias Input = (
        section: String,
        text: String?,
        maxLength: Int
    )
    var input: Input!

    private var section: UILabel!
    private var textField: UITextField!
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
        section.font = Brand.font(for: .medium)
        section.textColor = Brand.color(for: .brand(.primary))
        contentView.addSubview(section)

        textField = UITextField()
        textField.returnKeyType = .done
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.textColor = Brand.color(for: .text(.primary))
        textField.font = Brand.font(for: .medium)
        textField.attributedPlaceholder = NSAttributedString(
            string: "未入力",
            attributes: [NSAttributedString.Key.foregroundColor: Brand.color(for: .background(.light))])
        textField.text = input.text
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        contentView.addSubview(textField)

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
            section.heightAnchor.constraint(equalToConstant: 24),

            textField.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            textField.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            textField.topAnchor.constraint(equalTo: section.bottomAnchor),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            underLine.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            underLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            underLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            underLine.heightAnchor.constraint(equalToConstant: 1),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func keyboardType(_ type: UIKeyboardType = .default) {
        textField.keyboardType = type
        underLineColor()
    }

    func underLineColor() {
        guard let text = textField.text else { return }
        if text.isEmpty {
            underLine.backgroundColor = Brand.color(for: .text(.primary))
        } else {
            underLine.backgroundColor = Brand.color(for: .brand(.primary))
        }
        
        if textField.keyboardType == .numberPad {
            textField.rightViewMode = .always
            let unitLabel = UILabel()
            unitLabel.textColor = Brand.color(for: .background(.milder))
            unitLabel.text = "円"
            textField.rightView = unitLabel
        }
    }
    
    @objc func textFieldEditingChanged() {
        underLineColor()
        self.listener()
    }

    func getText() -> String? {
        return ((textField.text != nil) && !textField.text!.isEmpty) ? textField.text : nil
    }

    func setText(text: String) {
        self.textField.text = text
        underLineColor()
    }
    
    func focus() {
        self.textField.becomeFirstResponder()
    }

    func selectInputView(inputView: UIView) {
        let toolBar = UIToolbar()
        toolBar.isTranslucent = true
//        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.setItems([
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(
                barButtonSystemItem: .done, target: self, action: #selector(donePicker)
            ),
        ], animated: true)
        toolBar.sizeToFit()
        self.textField.inputAccessoryView = toolBar
        self.textField.inputView = inputView
    }

    @objc private func donePicker() {
        self.textField.endEditing(true)
    }
    
    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}

extension TextFieldView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        underLine.backgroundColor = Brand.color(for: .text(.primary))
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        underLineColor()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.listener()
        underLineColor()
    }
}
