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

    private var reactionButton: UIButton!
    private var numButton: UIButton!
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
        subviews.forEach { $0.removeFromSuperview() }
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

        reactionButton = UIButton()
        reactionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(reactionButton)
        reactionButton.addTarget(self, action: #selector(reactionButtonTapped), for: .touchUpInside)
        
        numButton = UIButton()
        numButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(numButton)
        numButton.addTarget(self, action: #selector(numButtonTapped), for: .touchUpInside)

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
                equalTo: reactionImageView.rightAnchor, constant: 8),
            numOfReaction.rightAnchor.constraint(equalTo: rightAnchor, constant: 8),
            numOfReaction.centerYAnchor.constraint(equalTo: centerYAnchor),

            reactionButton.topAnchor.constraint(equalTo: reactionImageView.topAnchor),
            reactionButton.bottomAnchor.constraint(equalTo: reactionImageView.bottomAnchor),
            reactionButton.leftAnchor.constraint(equalTo: reactionImageView.leftAnchor),
            reactionButton.rightAnchor.constraint(equalTo: reactionImageView.rightAnchor),
            
            numButton.topAnchor.constraint(equalTo: numOfReaction.topAnchor),
            numButton.bottomAnchor.constraint(equalTo: numOfReaction.bottomAnchor),
            numButton.leftAnchor.constraint(equalTo: numOfReaction.leftAnchor),
            numButton.rightAnchor.constraint(equalTo: numOfReaction.rightAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func setItem(text: String, image: UIImage?) {
        self.numOfReaction.text = text
        self.reactionImageView.image = image
    }
    
    func updateImage(image: UIImage?) {
        self.reactionImageView.image = image
    }
    
    func updateText(text: String) {
        self.numOfReaction.text = text
    }

    @objc private func reactionButtonTapped() {
        self.listener(.reaction)
    }
    
    @objc private func numButtonTapped() {
        self.listener(.num)
    }
    
    enum ListenerType {
        case num
        case reaction
    }

    private var listener: (ListenerType) -> Void = { type in }
    func listen(_ listener: @escaping (ListenerType) -> Void) {
        self.listener = listener
    }
}
