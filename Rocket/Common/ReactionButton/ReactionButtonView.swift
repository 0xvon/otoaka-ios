//
//  ReactionButtonView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import UIKit

final class ReactionButtonView: UIView {
    typealias Input = (
        text: String,
        image: UIImage?
    )

    var input: Input!

    private var button: UIButton!
    private var reactionImageView: UIImageView!
    private var numOfReaction: UILabel!

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
        backgroundColor = .clear
        let contentView = UIView(frame: self.frame)
        addSubview(contentView)

        contentView.backgroundColor = .clear
        contentView.layer.opacity = 0.8
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        reactionImageView = UIImageView()
        reactionImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(reactionImageView)
        reactionImageView.image = input.image
        reactionImageView.contentMode = .scaleAspectFit

        numOfReaction = UILabel()
        numOfReaction.translatesAutoresizingMaskIntoConstraints = false
        addSubview(numOfReaction)
        numOfReaction.text = input.text
        numOfReaction.textColor = style.color.main.get()
        numOfReaction.font = style.font.small.get()
        numOfReaction.textAlignment = .left

        button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)

        let constraints = [
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftAnchor.constraint(equalTo: contentView.leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),

            reactionImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            //            reactionImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            //            reactionImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8),
            reactionImageView.leftAnchor.constraint(equalTo: leftAnchor),
            reactionImageView.widthAnchor.constraint(equalToConstant: 20),
            reactionImageView.heightAnchor.constraint(equalTo: reactionImageView.widthAnchor),

            numOfReaction.leftAnchor.constraint(
                equalTo: reactionImageView.rightAnchor, constant: 4),
            numOfReaction.rightAnchor.constraint(equalTo: rightAnchor, constant: 8),
            numOfReaction.centerYAnchor.constraint(equalTo: centerYAnchor),

            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leftAnchor.constraint(equalTo: leftAnchor),
            button.rightAnchor.constraint(equalTo: rightAnchor),
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
