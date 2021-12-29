//
//  GroupRankingCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/29.
//

import UIKit
import Endpoint
import ImagePipeline

final class GroupRankingCell: UITableViewCell, ReusableCell {
    typealias Input = GroupRankingCellContent.Input
    typealias Output = GroupRankingCellContent.Output
    static var reusableIdentifier: String { "GroupRankingCell" }
    
    private let _contentView: GroupRankingCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = GroupRankingCellContent()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(_contentView)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.isUserInteractionEnabled = true
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        _contentView.prepare()
    }
}

class GroupRankingCellContent: UIButton {
    typealias Input = (
        group: Group,
        count: Int,
        unit: String,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case cellTapped
    }
    
    private lazy var artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = false
        
        return imageView
    }()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = false
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.spacing = 4
        
        stackView.addArrangedSubview(groupNameLabel)
        stackView.addArrangedSubview(countLabel)
        let spacer = UIView()
        spacer.backgroundColor = .clear
        stackView.addArrangedSubview(spacer)
        
        return stackView
    }()
    
    private lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .smallStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Brand.font(for: .small)
        label.textColor = Brand.color(for: .background(.secondary))
        return label
    }()
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func inject(input: Input) {
        if let url = input.group.artworkURL {
            input.imagePipeline.loadImage(url, into: artworkImageView)
        }
        groupNameLabel.text = input.group.name
        countLabel.text = "\(input.count)\(input.unit)"
    }
    
    func setup() {
        self.backgroundColor = .clear
        
        addSubview(artworkImageView)
        NSLayoutConstraint.activate([
            artworkImageView.widthAnchor.constraint(equalToConstant: 60),
            artworkImageView.heightAnchor.constraint(equalTo: artworkImageView.widthAnchor),
            artworkImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            artworkImageView.leftAnchor.constraint(equalTo: leftAnchor),
            artworkImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: artworkImageView.topAnchor),
            stackView.leftAnchor.constraint(equalTo: artworkImageView.rightAnchor, constant: 8),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
        ])
        
        addTarget(self, action: #selector(cellTapped), for: .touchUpInside)
    }
    
    func prepare() {
        artworkImageView.image = nil
        groupNameLabel.text = nil
        countLabel.text = nil
    }
    
    @objc private func cellTapped() {
        self.listener(.cellTapped)
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
