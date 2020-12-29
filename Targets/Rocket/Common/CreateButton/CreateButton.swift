//
//  CreateButton.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/05.
//

import UIKit

@available(*, deprecated)
final class CreateButton: UIView {
    typealias Input = UIImage

    var input: Input!

    private var imageView: UIImageView!
    private var button: UIButton!

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
        self.setup()
    }

    func setup() {
        self.layer.cornerRadius = self.bounds.width / 2
        self.layer.borderWidth = 1
        self.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        self.backgroundColor = Brand.color(for: .background(.primary))

        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = input
        addSubview(imageView)

        button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        addSubview(button)

        let constraints = [
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),

            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.rightAnchor.constraint(equalTo: rightAnchor),
            button.leftAnchor.constraint(equalTo: leftAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    @objc private func touchUpInside() {
        self.listener()
    }

    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}
