//
//  LiveDetailHeaderView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/25.
//

import Endpoint
import UIKit

final class LiveDetailHeaderView: UIView {
    typealias Input = (
        dependencyProvider: LoggedInDependencyProvider,
        live: Live,
        groups: [Group]
    )

    var input: Input!
    var listen: ((Int) -> Void)?
    var like: ((Int) -> Void)?
    var numOfLike: ((Int) -> Void)?
    var pushToBandViewController: ((UIViewController) -> Void)?
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日 HH:mm"
        return dateFormatter
    }()

    private var horizontalScrollView: UIScrollView!
    private var liveInformationView: UIView!
    private var bandInformationView: UIView!
    private var liveTitleLabel: UILabel!
    private var bandNameLabel: UILabel!
    private var mapBadgeView: BadgeView!
    private var dateBadgeView: BadgeView!
    private var liveImageView: UIImageView!
    private var arrowButton: UIButton!
    private var bandsTableView: UITableView!

    init(input: Input) {
        self.input = input
        super.init(frame: .zero)

        self.setup()
        self.inject(input: input)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func update(input: Input) {
        self.input = input

        liveImageView.loadImageAsynchronously(url: input.live.artworkURL)
        liveTitleLabel.text = input.live.title
        switch input.live.style {
        case .oneman(_):
            self.bandNameLabel.text = input.live.hostGroup.name
        case .battle(let groups):
            self.bandNameLabel.text = groups.map { $0.name }.joined(separator: ", ")
        case .festival(let groups):
            self.bandNameLabel.text = groups.map { $0.name }.joined(separator: ", ")
        }
        let date: String =
            (input.live.startAt != nil) ? dateFormatter.string(from: input.live.startAt!) : "時間未定"
        dateBadgeView.updateText(text: date)
        mapBadgeView.updateText(text: input.live.liveHouse ?? "会場未定")
    }

    func inject(input: Input) {
        self.input = input

        setup()
        liveImageView.loadImageAsynchronously(url: input.live.artworkURL)
        liveTitleLabel.text = input.live.title
        switch input.live.style {
        case .oneman(_):
            self.bandNameLabel.text = input.live.hostGroup.name
        case .battle(let groups):
            self.bandNameLabel.text = groups.map { $0.name }.joined(separator: ", ")
        case .festival(let groups):
            self.bandNameLabel.text = groups.map { $0.name }.joined(separator: ", ")
        }
        let date: String =
            (input.live.startAt != nil) ? dateFormatter.string(from: input.live.startAt!) : "時間未定"
        dateBadgeView.updateText(text: date)
        mapBadgeView.updateText(text: input.live.liveHouse ?? "会場未定")
    }

    func setup() {
        backgroundColor = .clear
        let contentView = UIView(frame: self.frame)
        addSubview(contentView)

        contentView.backgroundColor = .clear
        contentView.layer.opacity = 0.8
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        liveImageView = UIImageView()
        liveImageView.translatesAutoresizingMaskIntoConstraints = false
        liveImageView.contentMode = .scaleAspectFill
        liveImageView.clipsToBounds = true
        liveImageView.layer.opacity = 0.6
        addSubview(liveImageView)

        horizontalScrollView = UIScrollView()
        horizontalScrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalScrollView)
        horizontalScrollView.isPagingEnabled = true
        horizontalScrollView.isScrollEnabled = true
        horizontalScrollView.showsHorizontalScrollIndicator = false
        horizontalScrollView.showsVerticalScrollIndicator = false
        horizontalScrollView.contentSize = CGSize(
            width: UIScreen.main.bounds.width * 2, height: self.frame.height)
        horizontalScrollView.delegate = self

        liveInformationView = UIView(
            frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: self.frame.height))
        liveInformationView.backgroundColor = .clear
        horizontalScrollView.addSubview(liveInformationView)

        bandInformationView = UIView(
            frame: CGRect(
                x: UIScreen.main.bounds.width, y: 0, width: UIScreen.main.bounds.width,
                height: self.bounds.height))
        bandInformationView.backgroundColor = .clear
        horizontalScrollView.addSubview(bandInformationView)

        liveTitleLabel = UILabel()
        liveTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        liveTitleLabel.font = Brand.font(for: .xlargeStrong)
        liveTitleLabel.textColor = Brand.color(for: .text(.primary))
        liveTitleLabel.lineBreakMode = .byWordWrapping
        liveTitleLabel.numberOfLines = 0
        liveTitleLabel.adjustsFontSizeToFitWidth = false
        liveTitleLabel.sizeToFit()
        liveInformationView.addSubview(liveTitleLabel)

        bandNameLabel = UILabel()
        bandNameLabel.translatesAutoresizingMaskIntoConstraints = false
        bandNameLabel.font = Brand.font(for: .medium)
        bandNameLabel.textColor = Brand.color(for: .text(.primary))
        bandNameLabel.lineBreakMode = .byWordWrapping
        bandNameLabel.numberOfLines = 0
        bandNameLabel.adjustsFontSizeToFitWidth = false
        bandNameLabel.sizeToFit()
        liveInformationView.addSubview(bandNameLabel)
        let date: String =
            (input.live.startAt != nil) ? dateFormatter.string(from: input.live.startAt!) : "時間未定"

        dateBadgeView = BadgeView(input: (text: date, image: UIImage(named: "calendar")))
        liveInformationView.addSubview(dateBadgeView)

        mapBadgeView = BadgeView(input: (text: input.live.liveHouse ?? "会場未定", image: UIImage(named: "map")))
        liveInformationView.addSubview(mapBadgeView)

        arrowButton = UIButton()
        arrowButton.translatesAutoresizingMaskIntoConstraints = false
        arrowButton.contentMode = .scaleAspectFit
        arrowButton.contentHorizontalAlignment = .fill
        arrowButton.contentVerticalAlignment = .fill
        arrowButton.setImage(UIImage(named: "arrow"), for: .normal)
        arrowButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)
        liveInformationView.addSubview(arrowButton)

        bandsTableView = UITableView()
        bandsTableView.translatesAutoresizingMaskIntoConstraints = false
        bandInformationView.addSubview(bandsTableView)
        bandsTableView.showsVerticalScrollIndicator = true
        bandsTableView.separatorStyle = .none
        bandsTableView.backgroundColor = .clear
        bandsTableView.delegate = self
        bandsTableView.dataSource = self
        bandsTableView.register(
            UINib(nibName: "BandBannerCell", bundle: nil), forCellReuseIdentifier: "BandBannerCell")

        let constraints = [
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftAnchor.constraint(equalTo: contentView.leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),

            liveImageView.topAnchor.constraint(equalTo: topAnchor),
            liveImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            liveImageView.leftAnchor.constraint(equalTo: leftAnchor),
            liveImageView.rightAnchor.constraint(equalTo: rightAnchor),

            horizontalScrollView.topAnchor.constraint(equalTo: topAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalScrollView.leftAnchor.constraint(equalTo: leftAnchor),
            horizontalScrollView.rightAnchor.constraint(equalTo: rightAnchor),

            liveTitleLabel.topAnchor.constraint(
                equalTo: liveInformationView.topAnchor, constant: 16),
            liveTitleLabel.leftAnchor.constraint(
                equalTo: liveInformationView.leftAnchor, constant: 16),
            liveTitleLabel.rightAnchor.constraint(
                equalTo: liveInformationView.rightAnchor, constant: -16),

            bandNameLabel.topAnchor.constraint(equalTo: liveTitleLabel.bottomAnchor, constant: 8),
            bandNameLabel.leftAnchor.constraint(
                equalTo: liveInformationView.leftAnchor, constant: 16),
            bandNameLabel.rightAnchor.constraint(
                equalTo: liveInformationView.rightAnchor, constant: -16),

            dateBadgeView.bottomAnchor.constraint(
                equalTo: liveInformationView.bottomAnchor, constant: -16),
            dateBadgeView.leftAnchor.constraint(
                equalTo: liveInformationView.leftAnchor, constant: 16),
            dateBadgeView.widthAnchor.constraint(equalToConstant: 160),
            dateBadgeView.heightAnchor.constraint(equalToConstant: 30),

            mapBadgeView.bottomAnchor.constraint(equalTo: dateBadgeView.topAnchor, constant: -8),
            mapBadgeView.leftAnchor.constraint(
                equalTo: liveInformationView.leftAnchor, constant: 16),
            mapBadgeView.widthAnchor.constraint(equalToConstant: 300),
            mapBadgeView.heightAnchor.constraint(equalToConstant: 30),

            arrowButton.rightAnchor.constraint(
                equalTo: liveInformationView.rightAnchor, constant: -16),
            arrowButton.bottomAnchor.constraint(
                equalTo: liveInformationView.bottomAnchor, constant: -16),
            arrowButton.widthAnchor.constraint(equalToConstant: 54),
            arrowButton.heightAnchor.constraint(equalToConstant: 28),

            bandsTableView.leftAnchor.constraint(
                equalTo: bandInformationView.leftAnchor, constant: 16),
            bandsTableView.rightAnchor.constraint(
                equalTo: bandInformationView.rightAnchor, constant: -16),
            bandsTableView.bottomAnchor.constraint(
                equalTo: bandInformationView.bottomAnchor, constant: -16),
            bandsTableView.topAnchor.constraint(
                equalTo: bandInformationView.topAnchor, constant: 16),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc private func nextPage() {
        UIView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x += UIScreen.main.bounds.width
        }
    }
}

extension LiveDetailHeaderView: UIScrollViewDelegate {
}

extension LiveDetailHeaderView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return input.groups.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let band = input.groups[indexPath.section]
        let vc = BandDetailViewController(dependencyProvider: input.dependencyProvider, input: band)
        self.pushToBandViewController?(vc)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = input.groups[indexPath.section]
        let cell = tableView.reuse(BandBannerCell.self, input: group, for: indexPath)
        cell.like { [weak self] type in
            switch type {
            case .reaction:
                self?.like?(indexPath.section)
            case .num:
                self?.numOfLike?(indexPath.section)
            }
            
        }
        cell.listen { [weak self] in
            self?.listen?(indexPath.section)
        }

        return cell
    }
}
