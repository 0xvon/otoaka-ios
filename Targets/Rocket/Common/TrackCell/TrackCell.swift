//
//  TrackCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import UIKit
import InternalDomain
import ImagePipeline
import Endpoint

final class TrackCell: UITableViewCell, ReusableCell {
    typealias Input = TrackCellContent.Input
    typealias Output = TrackCellContent.Output
    static var reusableIdentifier: String { "TrackCell" }
    
    private let _contentView: TrackCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = UINib(nibName: "TrackCellContent", bundle: nil)
            .instantiate(withOwner: nil, options: nil).first as! TrackCellContent
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(_contentView)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        // Proxy tap event to tableView(_:didSelectRowAt:)
        _contentView.cellButton.isUserInteractionEnabled = false
        backgroundColor = .clear
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            _contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            _contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            _contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            _contentView.heightAnchor.constraint(equalToConstant: 40),
        ])
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func inject(input: Input) {
        _contentView.inject(input: input)
    }

    func listen(_ listener: @escaping (Output) -> Void) {
        _contentView.listen(listener)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        alpha = highlighted ? 0.6 : 1.0
        _contentView.alpha = highlighted ? 0.6 : 1.0
    }
}

class TrackCellContent: UIView {
    typealias Input = (
        track: Track,
        imagePipeline: ImagePipeline
    )
    
    enum Output {
        case playButtonTapped
        case groupTapped
    }
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var bandNameLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var cellButton: UIButton!
    
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        cellButton.addTarget(target, action: action, for: controlEvents)
    }
    
    func inject(input: Input) {
        setup()
        trackTitleLabel.text = input.track.name
        bandNameLabel.text = input.track.artistName
        if let url = URL(string: input.track.artwork) {
            input.imagePipeline.loadImage(url, into: artworkImageView)
        }
    }
    
    func setup() {
        backgroundColor = .clear
        
        artworkImageView.layer.cornerRadius = 20
        artworkImageView.alpha = 0.8
        artworkImageView.clipsToBounds = true
        
        trackTitleLabel.font = Brand.font(for: .mediumStrong)
        trackTitleLabel.textColor = Brand.color(for: .text(.primary))
        
        bandNameLabel.font = Brand.font(for: .xsmall)
        bandNameLabel.textColor = Brand.color(for: .text(.link))
        
        playButton.setImage(UIImage(systemName: "play")!
                                .withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
    }
    
    @objc private func playButtonTapped() {
        listener(.playButtonTapped)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
