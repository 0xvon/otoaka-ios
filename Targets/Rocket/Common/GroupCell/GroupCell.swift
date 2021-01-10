//
//  BandCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import DomainEntity
import UIKit
import ImagePipeline

final class GroupCell: UITableViewCell, ReusableCell {
    typealias Input = GroupCellContent.Input
    typealias Output = GroupCellContent.Output
    static var reusableIdentifier: String { "GroupCell" }
    
    private let _contentView: GroupCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = UINib(nibName: "GroupCellContent", bundle: nil).instantiate(withOwner: nil, options: nil).first as! GroupCellContent
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(_contentView)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.isUserInteractionEnabled = false
        backgroundColor = .clear
        NSLayoutConstraint.activate([
            _contentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            _contentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
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

class GroupCellContent: UIButton {
    typealias Input = (
        group: Group,
        imagePipeline: ImagePipeline
    )
    enum Output {
        case listenButtonTapped
    }
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY年"
        return dateFormatter
    }()
    
    @IBOutlet weak var jacketImageView: UIImageView!
    @IBOutlet weak var bandNameLabel: UILabel!
    @IBOutlet weak var productionBadgeView: BadgeView!
    @IBOutlet weak var labelBadgeView: BadgeView!
    @IBOutlet weak var sinceBadgeView: BadgeView!
    @IBOutlet weak var hometownBadgeView: BadgeView!
    
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    func inject(input: Input) {
        bandNameLabel.text = input.group.name
        if let artworkURL = input.group.artworkURL {
            input.imagePipeline.loadImage(artworkURL, into: jacketImageView)
        }
        let startYear: String = input.group.since.map { "\(dateFormatter.string(from: $0))結成" } ?? "結成年不明"
        sinceBadgeView.title = startYear
        hometownBadgeView.title = input.group.hometown.map { "\($0)出身" } ?? "出身不明"

    }
    
    func setup() {
        self.backgroundColor = .clear
        self.layer.borderWidth = 1
        self.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        self.layer.cornerRadius = 10
        
        jacketImageView.layer.opacity = 0.6
        jacketImageView.layer.cornerRadius = 10
        jacketImageView.layer.borderWidth = 1
        jacketImageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        jacketImageView.clipsToBounds = true

        bandNameLabel.font = Brand.font(for: .xlargeStrong)
        bandNameLabel.textColor = Brand.color(for: .text(.primary))

        productionBadgeView.isHidden = true
        productionBadgeView.title = "Japan Music Systems"
        productionBadgeView.image = UIImage(named: "production")!

        labelBadgeView.isHidden = true
        labelBadgeView.title = "Intact Records"
        labelBadgeView.image = UIImage(named: "record")!
        
        sinceBadgeView.image = UIImage(named: "calendar")!
        hometownBadgeView.image = UIImage(named: "map")!
    }
    
    private var listener: (Output) -> Void = { _ in }
    func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
}
