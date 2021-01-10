//
//  FanCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/08.
//

import UIKit
import Endpoint
import ImagePipeline

final class FanCell: UITableViewCell, ReusableCell {
    typealias Input = FanCellContent.Input
    typealias Output = FanCellContent.Output
    static var reusableIdentifier: String { "FanCell" }
    
    private let _contentView: FanCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = UINib(nibName: "FanCellContent", bundle: nil).instantiate(withOwner: nil, options: nil).first as! FanCellContent
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(_contentView)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.isUserInteractionEnabled = false
        backgroundColor = .clear
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            _contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            _contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            _contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
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

class FanCellContent: UIButton {
    typealias Input = (
        user: User,
        imagePipeline: ImagePipeline
    )
    typealias Output = Void
    
    @IBOutlet weak var fanArtworkImageView: UIImageView!
    @IBOutlet weak var fanNameLabel: UILabel!
    @IBOutlet weak var biographyTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    func inject(input: Input) {
        if let thumbnail = input.user.thumbnailURL {
            guard let url = URL(string: thumbnail) else { return }
            input.imagePipeline.loadImage(url, into: fanArtworkImageView)
        }
        fanNameLabel.text = input.user.name
        biographyTextView.text = input.user.biography
    }
    
    func setup() {
        self.backgroundColor = .clear
        
        fanArtworkImageView.clipsToBounds = true
        fanArtworkImageView.layer.cornerRadius = 30
        fanArtworkImageView.contentMode = .scaleAspectFill
        
        fanNameLabel.font = Brand.font(for: .largeStrong)
        fanNameLabel.backgroundColor = Brand.color(for: .background(.primary))
        fanNameLabel.textColor = Brand.color(for: .text(.primary))
        
        biographyTextView.isUserInteractionEnabled = false
        biographyTextView.font = Brand.font(for: .medium)
        biographyTextView.backgroundColor = Brand.color(for: .background(.primary))
        biographyTextView.textColor = Brand.color(for: .text(.primary))
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
