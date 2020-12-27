//
//  Button.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/21.
//

import UIKit

public final class Button: UIView, InputAppliable {
    public typealias Input = (
        text: String,
        image: UIImage?
    )

    var input: Input

    private var buttonImageView: UIImageView!
    private var buttonTitleLabel: UILabel!
    private var button: UIButton!

    public init(input: Input) {
        self.input = input
        super.init(frame: .zero)
        self.inject(input: input)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("unavailable")
    }

    public func inject(input: Input) {
        self.input = input
        self.setup()
    }

    func setup() {
        backgroundColor = Brand.color(for: .background(.button))
        layer.cornerCurve = .circular
        layer.cornerRadius = self.bounds.height / 2
        clipsToBounds = true

        let contentView = UIView(frame: self.frame)
        addSubview(contentView)

        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false

        buttonImageView = UIImageView()
        buttonImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonImageView)
        buttonImageView.image = input.image

        buttonImageView.tintColor = Brand.color(for: .brand(.primary))

        buttonTitleLabel = UILabel()
        buttonTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonTitleLabel)
        buttonTitleLabel.textColor = Brand.color(for: .text(.button))
        buttonTitleLabel.font = Brand.font(for: .mediumStrong)
        buttonTitleLabel.text = input.text
        buttonTitleLabel.textAlignment = .center

        button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.layer.cornerRadius = button.bounds.height / 2
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)

        let constraints = [
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftAnchor.constraint(equalTo: contentView.leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),

            buttonImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            buttonImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            buttonImageView.widthAnchor.constraint(equalToConstant: 24),
            buttonImageView.heightAnchor.constraint(equalTo: buttonImageView.widthAnchor),
            buttonTitleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
            buttonTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            buttonTitleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),

            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leftAnchor.constraint(equalTo: leftAnchor),
            button.rightAnchor.constraint(equalTo: rightAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    public func setText(text: String) {
        self.buttonTitleLabel.text = text
    }

    @objc private func touchUpInside() {
        self.listener()
    }

    private var listener: () -> Void = {}
    public func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct Button_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(view: Button(input: (text: "Hello", image: nil)))
        }
        .previewLayout(.fixed(width: 180, height: 48))
    }
}
#endif
