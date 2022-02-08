//
//  LiveScheduleCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/01.
//

import Endpoint
import UIKit
import ImagePipeline

public final class LiveScheduleTableView: UITableView {
    public var liveFeeds: [LiveFeed] = []
    public var imagePipeline: ImagePipeline
    
    public init(liveFeeds: [LiveFeed], imagePipeline: ImagePipeline) {
        self.liveFeeds = liveFeeds
        self.imagePipeline = imagePipeline
        
        super.init(frame: .zero, style: .plain)
        setup()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func inject(liveFeeds: [LiveFeed]) {
        self.liveFeeds = liveFeeds
        reloadData()
        setTableViewBackGroundView(isDisplay: liveFeeds.isEmpty)
    }
    
    func setup() {
        backgroundColor = .clear
        
        registerCellClass(LiveScheduleCell.self)
        separatorStyle = .none
        delegate = self
        dataSource = self
        showsHorizontalScrollIndicator = false
    }
    
    private var listener: (LiveFeed) -> Void = { _ in }
    public func listen(_ listener: @escaping (LiveFeed) -> Void) {
        self.listener = listener
    }
}

extension LiveScheduleTableView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return liveFeeds.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let liveFeed = liveFeeds[indexPath.row]
        let order: LiveScheduleCellContent.Order
        switch indexPath.row {
        case 0: order = .first
        case liveFeeds.count - 1: order = .last
        default: order = .middle
        }
        
        let cell = tableView.dequeueReusableCell(LiveScheduleCell.self, input: (live: liveFeed, imagePipeline: imagePipeline, order: order), for: indexPath)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let liveFeed = liveFeeds[indexPath.row]
        self.listener(liveFeed)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setTableViewBackGroundView(isDisplay: Bool = true) {
        let emptyCollectionView = EmptyCollectionView(emptyType: .liveSchedule, actionButtonTitle: nil)
        emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView = isDisplay ? emptyCollectionView : nil
        if let backgroundView = backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: topAnchor),
                backgroundView.widthAnchor.constraint(equalTo: widthAnchor, constant: -32),
                backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            ])
        }
    }
}

class LiveScheduleCell: UITableViewCell, ReusableCell {
    typealias Input = LiveScheduleCellContent.Input
    typealias Output = LiveScheduleCellContent.Output
    static var reusableIdentifier: String { "LiveScheduleCell" }
    
    private let _contentView: LiveScheduleCellContent
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        _contentView = LiveScheduleCellContent()
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
            _contentView.heightAnchor.constraint(equalToConstant: 76),
        ])
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func inject(input: LiveScheduleCellContent.Input) {
        _contentView.inject(input: input)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        alpha = highlighted ? 0.6 : 1.0
        _contentView.alpha = highlighted ? 0.6 : 1.0
    }
}

class LiveScheduleCellContent: UIButton {
    typealias Input = (
        live: LiveFeed,
        imagePipeline: ImagePipeline,
        order: Order
    )
    enum Output {}
    enum Order {
        case first, last, middle
    }
    private lazy var dateView: UIView = {
        let view = UIView()
        view.backgroundColor = Brand.color(for: .brand(.primary))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 26
        view.clipsToBounds = true
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 52),
            view.widthAnchor.constraint(equalTo: view.heightAnchor),
        ])
        view.addSubview(monthLabel)
        NSLayoutConstraint.activate([
            monthLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            monthLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
        ])
        view.addSubview(dayLabel)
        NSLayoutConstraint.activate([
            dayLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            dayLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
        ])
        view.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            separator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        return view
    }()
    private lazy var monthLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .mediumStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .mediumStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var separator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Brand.color(for: .text(.primary))
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 2),
            view.heightAnchor.constraint(equalToConstant: 28),
        ])
        view.transform = CGAffineTransform(rotationAngle: .pi / 4);
        return view
    }()
    private lazy var topDirection: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Brand.color(for: .brand(.primary))
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 8),
        ])
        view.isHidden = true
        return view
    }()
    private lazy var bottomDirection: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Brand.color(for: .brand(.primary))
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 8),
        ])
        view.isHidden = true
        return view
    }()
    private lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = Brand.color(for: .text(.primary)).cgColor
        imageView.clipsToBounds = true
        imageView.alpha = 0.3
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    private lazy var liveTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .mediumStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .xsmall)
        label.textColor = Brand.color(for: .text(.light))
        return label
    }()
    private lazy var livehouseLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .xsmall)
        label.textColor = Brand.color(for: .text(.light))
        return label
    }()
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.5 : 1.0 }
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func inject(input: Input) {
        liveTitleLabel.text = input.live.live.title
        switch input.live.live.style {
        case .oneman(_):
            self.groupNameLabel.text = input.live.live.hostGroup.name
        case .battle(let groups):
            self.groupNameLabel.text = groups.map { $0.name }.joined(separator: ", ")
        case .festival(let groups):
            let groupNames = groups.map { $0.name }.prefix(3)
            self.groupNameLabel.text = groupNames.joined(separator: ", ") + "..."
        }
        livehouseLabel.text = input.live.live.liveHouse.map { "@\($0)" }
        if let url = input.live.live.artworkURL ?? input.live.live.hostGroup.artworkURL {
            input.imagePipeline.loadImage(url, into: thumbnailImageView)
        } else {
            thumbnailImageView.image = Brand.color(for: .background(.light)).image
        }
        monthLabel.text = input.live.live.date.map { String($0.suffix(4).prefix(2)) } ?? "??"
        dayLabel.text = input.live.live.date.map { String($0.suffix(2)) } ?? "??"
        
        switch input.order {
        case .first:
            topDirection.isHidden = true
            bottomDirection.isHidden = false
        case .last:
            topDirection.isHidden = false
            bottomDirection.isHidden = true
        case .middle:
            topDirection.isHidden = false
            bottomDirection.isHidden = false
        }
    }
    
    func setup() {
        self.backgroundColor = .clear
        
        addSubview(dateView)
        NSLayoutConstraint.activate([
            dateView.centerYAnchor.constraint(equalTo: centerYAnchor),
            dateView.leftAnchor.constraint(equalTo: leftAnchor),
        ])
        
        addSubview(topDirection)
        NSLayoutConstraint.activate([
            topDirection.topAnchor.constraint(equalTo: topAnchor),
            topDirection.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
            topDirection.bottomAnchor.constraint(equalTo: dateView.topAnchor, constant: 4),
        ])
        
        addSubview(bottomDirection)
        NSLayoutConstraint.activate([
            bottomDirection.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomDirection.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
            bottomDirection.topAnchor.constraint(equalTo: dateView.bottomAnchor, constant: -4),
        ])
        
        addSubview(thumbnailImageView)
        NSLayoutConstraint.activate([
            thumbnailImageView.leftAnchor.constraint(equalTo: dateView.rightAnchor, constant: 16),
            thumbnailImageView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            thumbnailImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            thumbnailImageView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
        
        addSubview(liveTitleLabel)
        NSLayoutConstraint.activate([
            liveTitleLabel.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 8),
            liveTitleLabel.leftAnchor.constraint(equalTo: thumbnailImageView.leftAnchor, constant: 8),
            liveTitleLabel.rightAnchor.constraint(equalTo: thumbnailImageView.rightAnchor, constant: -8),
        ])
        
        addSubview(groupNameLabel)
        NSLayoutConstraint.activate([
            groupNameLabel.topAnchor.constraint(equalTo: liveTitleLabel.bottomAnchor, constant: 4),
            groupNameLabel.leftAnchor.constraint(equalTo: liveTitleLabel.leftAnchor),
            groupNameLabel.rightAnchor.constraint(equalTo: liveTitleLabel.rightAnchor),
        ])
        
        addSubview(livehouseLabel)
        NSLayoutConstraint.activate([
            livehouseLabel.topAnchor.constraint(equalTo: groupNameLabel.bottomAnchor),
            livehouseLabel.leftAnchor.constraint(equalTo: liveTitleLabel.leftAnchor),
            livehouseLabel.rightAnchor.constraint(equalTo: liveTitleLabel.rightAnchor),
        ])
    }
}
