//
//  PlaylistCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/23.
//

import UIKit
import Endpoint
import ImagePipeline
import UIComponent

class PlaylistCell: UIButton {
    typealias Input = (
        tracks: [Track],
        isEdittable: Bool,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case playButtonTapped(Track)
        case trackTapped(Track)
        case groupTapped(Track)
        case seeMoreTapped
    }
    private lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.opacity = 0.3
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    private lazy var trackStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    private lazy var seeMoreButton: CountButton = {
        let button = CountButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("すべてみる", for: .normal)
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.listen { [unowned self] in
            self.listener(.seeMoreTapped)
        }
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 20),
        ])
        return button
    }()
    
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func inject(input: Input) {
        if let artwork = input.tracks.first?.artwork, let artworkURL = URL(string: artwork) {
            input.imagePipeline.loadImage(artworkURL, into: thumbnailImageView)
        }
        trackStackView.arrangedSubviews.forEach {
            trackStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        input.tracks.prefix(5).forEach { track in
            let _contentView = UINib(nibName: "TrackCellContent", bundle: nil)
                .instantiate(withOwner: nil, options: nil).first as! TrackCellContent
            _contentView.translatesAutoresizingMaskIntoConstraints = false
            _contentView.cellButton.isUserInteractionEnabled = false
            _contentView.inject(input: (
                track: track,
                isEdittable: input.isEdittable,
                imagePipeline: input.imagePipeline
            ))
            trackStackView.addArrangedSubview(_contentView)
            _contentView.listen { [unowned self] output in
                switch output {
                case .playButtonTapped: self.listener(.playButtonTapped(track))
                case .groupTapped: self.listener(.groupTapped(track))
                }
            }
        }
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        trackStackView.addArrangedSubview(spacer)
        if (input.tracks.count > 5) {
            trackStackView.addArrangedSubview(seeMoreButton)
        }
    }
    
    func setup() {
        self.backgroundColor = .clear
        self.layer.borderWidth = 1
        self.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        self.layer.cornerRadius = 10
        
        addSubview(thumbnailImageView)
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: topAnchor),
            thumbnailImageView.rightAnchor.constraint(equalTo: rightAnchor),
            thumbnailImageView.leftAnchor.constraint(equalTo: leftAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        addSubview(trackStackView)
        NSLayoutConstraint.activate([
            trackStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            trackStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            trackStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            trackStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
