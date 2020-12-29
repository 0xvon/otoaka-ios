//
//  BandDetailHeaderView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import DomainEntity
import InternalDomain
import UIKit

public final class BandDetailHeaderView: UIView {
    public typealias Input = (
        group: Group,
        groupItem: ChannelDetail.ChannelItem?
    )

    var input: Input!
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY年"
        return dateFormatter
    }()
    
    private var listener: (ListenType) -> Void = { listenType in }
    public func listen(_ listener: @escaping (ListenType) -> Void) {
        self.listener = listener
    }
    
    public enum ListenType {
        case play(URL)
        case seeMoreCharts
        case youtube(URL)
        case twitter(URL)
    }

    private lazy var horizontalScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentSize = CGSize(
            width: UIScreen.main.bounds.width * 3, height: self.frame.height)
        return scrollView
    }()
    private lazy var bandInformationView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: self.frame.height))
        view.backgroundColor = .clear
        return view
    }()
    private lazy var trackInformationView: UIView = {
        let view = UIView(frame: CGRect(x: UIScreen.main.bounds.width, y: 0, width: UIScreen.main.bounds.width, height: self.bounds.height))
        view.backgroundColor = .clear
        return view
    }()
    private lazy var biographyView: UIView = {
        let view = UIView(
            frame: CGRect(
                x: UIScreen.main.bounds.width * 2, y: 0, width: UIScreen.main.bounds.width,
                height: self.bounds.height))
        view.backgroundColor = .clear
        return view
    }()
    private lazy var bandNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .xlarge)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = false
        return label
    }()
    private var mapBadgeView: BadgeView!
    private var dateBadgeView: BadgeView!
    private var productionBadgeView: BadgeView!
    private var labelBadgeView: BadgeView!
    private lazy var bandImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.loadImageAsynchronously(url: input.group.artworkURL)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.opacity = 0.6
        imageView.clipsToBounds = true
        return imageView
    }()
    private lazy var arrowButton: UIButton = {
        let arrowButton = UIButton()
        arrowButton.translatesAutoresizingMaskIntoConstraints = false
        arrowButton.contentMode = .scaleAspectFit
        arrowButton.contentHorizontalAlignment = .fill
        arrowButton.contentVerticalAlignment = .fill
        arrowButton.setImage(UIImage(named: "arrow"), for: .normal)
        return arrowButton
    }()
    private lazy var artworkImageView: UIImageView = {
        let artworkImageView = UIImageView()
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.image = nil
        artworkImageView.layer.cornerRadius = 10
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.clipsToBounds = true
        return artworkImageView
    }()
    private lazy var playButton: PrimaryButton = {
        let playButton = PrimaryButton(text: "再生")
        playButton.setImage(
            UIImage(systemName: "play")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal)
        playButton.imageView?.contentMode = .scaleAspectFit
        playButton.isHidden = true
        playButton.layer.cornerRadius = 18
        playButton.translatesAutoresizingMaskIntoConstraints = false
        return playButton
    }()
    private lazy var trackNameLabel: UILabel = {
        let trackNameLabel = UILabel()
        trackNameLabel.translatesAutoresizingMaskIntoConstraints = false
        trackNameLabel.text = ""
        trackNameLabel.font = Brand.font(for: .mediumStrong)
        trackNameLabel.textColor = Brand.color(for: .text(.primary))
        return trackNameLabel
    }()
    private lazy var releasedDataLabel: UILabel = {
        let releasedDataLabel = UILabel()
        releasedDataLabel.translatesAutoresizingMaskIntoConstraints = false
        releasedDataLabel.text = ""
        releasedDataLabel.font = Brand.font(for: .small)
        releasedDataLabel.textColor = Brand.color(for: .text(.primary))
        return releasedDataLabel
    }()
    private lazy var seeMoreTracksButton: UIButton = {
        let seeMoreTracksButton = UIButton()
        seeMoreTracksButton.isHidden = true
        seeMoreTracksButton.translatesAutoresizingMaskIntoConstraints = false
        seeMoreTracksButton.setTitle("もっと見る", for: .normal)
        seeMoreTracksButton.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        seeMoreTracksButton.titleLabel?.font = Brand.font(for: .small)
        return seeMoreTracksButton
    }()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        return stackView
    }()
    private lazy var twitterButton: UIButton = {
        let twitterButton = UIButton()
        twitterButton.translatesAutoresizingMaskIntoConstraints = false
        twitterButton.contentHorizontalAlignment = .fill
        twitterButton.contentVerticalAlignment = .fill
        twitterButton.setImage(UIImage(named: "twitter"), for: .normal)
        twitterButton.imageView?.contentMode = .scaleAspectFit
        return twitterButton
    }()
    private lazy var youtubeButton: UIButton = {
        let youtubeButton = UIButton()
        youtubeButton.translatesAutoresizingMaskIntoConstraints = false
        youtubeButton.contentHorizontalAlignment = .fill
        youtubeButton.contentVerticalAlignment = .fill
        youtubeButton.setImage(UIImage(named: "youtube"), for: .normal)
        youtubeButton.imageView?.contentMode = .scaleAspectFit
        return youtubeButton
    }()
    private lazy var appleMusicButton: UIButton = {
        let appleMusicButton = UIButton()
        appleMusicButton.isHidden = true
        appleMusicButton.translatesAutoresizingMaskIntoConstraints = false
        appleMusicButton.contentHorizontalAlignment = .fill
        appleMusicButton.contentVerticalAlignment = .fill
        appleMusicButton.setImage(UIImage(named: "itunes"), for: .normal)
        appleMusicButton.imageView?.contentMode = .scaleAspectFit
        return appleMusicButton
    }()
    private lazy var spotifyButton: UIButton = {
        let spotifyButton = UIButton()
        spotifyButton.isHidden = true
        spotifyButton.translatesAutoresizingMaskIntoConstraints = false
        spotifyButton.contentHorizontalAlignment = .fill
        spotifyButton.contentVerticalAlignment = .fill
        spotifyButton.setImage(UIImage(named: "spotify"), for: .normal)
        spotifyButton.imageView?.contentMode = .scaleAspectFit
        return spotifyButton
    }()
    private lazy var biographyTextView: UITextView = {
        let biographyTextView = UITextView()
        biographyTextView.translatesAutoresizingMaskIntoConstraints = false
        biographyTextView.isScrollEnabled = true
        biographyTextView.textColor = Brand.color(for: .text(.primary))
        biographyTextView.backgroundColor = .clear
        biographyTextView.isEditable = false
        biographyTextView.font = Brand.font(for: .medium)
        return biographyTextView
    }()
    
    private lazy var contentView: UIView = {
        let contentView = UIView(frame: self.frame)
        addSubview(contentView)

        contentView.backgroundColor = .clear
        contentView.layer.opacity = 0.8
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()

    public init(input: Input) {
        self.input = input
        super.init(frame: .zero)
        self.inject(input: input)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func update(input: Input) {
        self.input = input

        bandImageView.loadImageAsynchronously(url: input.group.artworkURL)
        bandNameLabel.text = input.group.name
        let startYear: String =
            (input.group.since != nil) ? dateFormatter.string(from: input.group.since!) : "不明"
        dateBadgeView.title = startYear
        mapBadgeView.title = input.group.hometown ?? "不明"
        biographyTextView.text = input.group.biography
        if let groupItem = input.groupItem {
            artworkImageView.loadImageAsynchronously(url: URL(string: groupItem.snippet.thumbnails.high.url))
            playButton.isHidden = false
            releasedDataLabel.text = self.dateFormatter.string(from: groupItem.snippet.publishedAt)
            trackNameLabel.text = groupItem.snippet.title
        }
    }

    public func inject(input: Input) {
        self.input = input
        self.setup()
    }

    func setup() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentView)
        addSubview(bandImageView)
        addSubview(horizontalScrollView)
        horizontalScrollView.addSubview(bandInformationView)
        horizontalScrollView.addSubview(trackInformationView)
        horizontalScrollView.addSubview(biographyView)

        bandNameLabel.text = input.group.name
        bandNameLabel.sizeToFit()
        bandInformationView.addSubview(bandNameLabel)

        let startYear: String =
            (input.group.since != nil) ? dateFormatter.string(from: input.group.since!) : "不明"
        dateBadgeView = BadgeView(text: startYear, image: UIImage(named: "calendar"))
        bandInformationView.addSubview(dateBadgeView)

        mapBadgeView = BadgeView(text: input.group.hometown ?? "不明", image: UIImage(named: "map"))
        bandInformationView.addSubview(mapBadgeView)
        
        labelBadgeView = BadgeView(text: "Intact Records", image: UIImage(named: "record"))
        labelBadgeView.isHidden = true
        bandInformationView.addSubview(labelBadgeView)

        productionBadgeView = BadgeView(text: "Japan Music Systems", image: UIImage(named: "production"))
        productionBadgeView.isHidden = true
        bandInformationView.addSubview(productionBadgeView)

        arrowButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)
        bandInformationView.addSubview(arrowButton)

        trackInformationView.addSubview(artworkImageView)
        
        playButton.listen {
            self.play()
        }
        trackInformationView.addSubview(playButton)

        trackInformationView.addSubview(trackNameLabel)

        trackInformationView.addSubview(releasedDataLabel)

        seeMoreTracksButton.addTarget(
            self, action: #selector(seeMoreButtonTapped(_:)), for: .touchUpInside)
        trackInformationView.addSubview(seeMoreTracksButton)

        trackInformationView.addSubview(stackView)

        twitterButton.addTarget(
            self, action: #selector(twitterButtonTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(twitterButton)

        youtubeButton.addTarget(
            self, action: #selector(youtubeButtonTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(youtubeButton)

        appleMusicButton.addTarget(
            self, action: #selector(appleMusicButtonTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(appleMusicButton)

        spotifyButton.addTarget(
            self, action: #selector(spotifyButtonTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(spotifyButton)

        biographyView.addSubview(biographyTextView)
        biographyTextView.text = input.group.biography

        let constraints = [
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftAnchor.constraint(equalTo: contentView.leftAnchor),
            rightAnchor.constraint(equalTo: contentView.rightAnchor),

            bandImageView.topAnchor.constraint(equalTo: topAnchor),
            bandImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bandImageView.leftAnchor.constraint(equalTo: leftAnchor),
            bandImageView.rightAnchor.constraint(equalTo: rightAnchor),

            horizontalScrollView.topAnchor.constraint(equalTo: topAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalScrollView.leftAnchor.constraint(equalTo: leftAnchor),
            horizontalScrollView.rightAnchor.constraint(equalTo: rightAnchor),

            bandNameLabel.topAnchor.constraint(
                equalTo: bandInformationView.topAnchor, constant: 16),
            bandNameLabel.leftAnchor.constraint(
                equalTo: bandInformationView.leftAnchor, constant: 16),
            bandNameLabel.rightAnchor.constraint(
                equalTo: bandInformationView.rightAnchor, constant: -16),

            dateBadgeView.bottomAnchor.constraint(
                equalTo: bandInformationView.bottomAnchor, constant: -16),
            dateBadgeView.leftAnchor.constraint(
                equalTo: bandInformationView.leftAnchor, constant: 16),
            dateBadgeView.widthAnchor.constraint(equalToConstant: 160),
            dateBadgeView.heightAnchor.constraint(equalToConstant: 30),

            mapBadgeView.bottomAnchor.constraint(equalTo: dateBadgeView.topAnchor, constant: -8),
            mapBadgeView.leftAnchor.constraint(
                equalTo: bandInformationView.leftAnchor, constant: 16),
            mapBadgeView.widthAnchor.constraint(equalToConstant: 160),
            mapBadgeView.heightAnchor.constraint(equalToConstant: 30),

            labelBadgeView.bottomAnchor.constraint(equalTo: mapBadgeView.topAnchor, constant: -8),
            labelBadgeView.leftAnchor.constraint(
                equalTo: bandInformationView.leftAnchor, constant: 16),
            labelBadgeView.widthAnchor.constraint(equalToConstant: 160),
            labelBadgeView.heightAnchor.constraint(equalToConstant: 30),

            productionBadgeView.bottomAnchor.constraint(
                equalTo: labelBadgeView.topAnchor, constant: -8),
            productionBadgeView.leftAnchor.constraint(
                equalTo: bandInformationView.leftAnchor, constant: 16),
            productionBadgeView.widthAnchor.constraint(equalToConstant: 160),
            productionBadgeView.heightAnchor.constraint(equalToConstant: 30),

            arrowButton.rightAnchor.constraint(
                equalTo: bandInformationView.rightAnchor, constant: -16),
            arrowButton.bottomAnchor.constraint(
                equalTo: bandInformationView.bottomAnchor, constant: -16),
            arrowButton.widthAnchor.constraint(equalToConstant: 54),
            arrowButton.heightAnchor.constraint(equalToConstant: 28),

            artworkImageView.leftAnchor.constraint(
                equalTo: trackInformationView.leftAnchor, constant: 36),
            artworkImageView.topAnchor.constraint(
                equalTo: trackInformationView.topAnchor, constant: 48),
            artworkImageView.widthAnchor.constraint(equalToConstant: 120),
            artworkImageView.heightAnchor.constraint(equalToConstant: 120),

            playButton.leftAnchor.constraint(equalTo: artworkImageView.rightAnchor, constant: 24),
            playButton.topAnchor.constraint(equalTo: artworkImageView.topAnchor, constant: 8),
            playButton.widthAnchor.constraint(equalToConstant: 150),
            playButton.heightAnchor.constraint(equalToConstant: 36),

            trackNameLabel.leftAnchor.constraint(equalTo: playButton.leftAnchor),
            trackNameLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 8),
            trackNameLabel.rightAnchor.constraint(equalTo: trackInformationView.rightAnchor, constant: -16),

            releasedDataLabel.leftAnchor.constraint(equalTo: playButton.leftAnchor),
            releasedDataLabel.topAnchor.constraint(
                equalTo: trackNameLabel.bottomAnchor, constant: 4),

            seeMoreTracksButton.topAnchor.constraint(
                equalTo: trackInformationView.topAnchor, constant: 16),
            seeMoreTracksButton.rightAnchor.constraint(
                equalTo: trackInformationView.rightAnchor, constant: -32),

            stackView.rightAnchor.constraint(
                equalTo: trackInformationView.rightAnchor, constant: -32),
            stackView.bottomAnchor.constraint(
                equalTo: trackInformationView.bottomAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 24),

            twitterButton.widthAnchor.constraint(equalToConstant: 24),

            biographyTextView.topAnchor.constraint(equalTo: biographyView.topAnchor, constant: 16),
            biographyTextView.bottomAnchor.constraint(
                equalTo: biographyView.bottomAnchor, constant: -16),
            biographyTextView.rightAnchor.constraint(
                equalTo: biographyView.rightAnchor, constant: -16),
            biographyTextView.leftAnchor.constraint(
                equalTo: biographyView.leftAnchor, constant: 16),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func play() {
        if let groupItem = input.groupItem {
            self.listener(.play(URL(string: "https://youtube.com/watch?v=\(groupItem.id.videoId)")!))
        }
    }

    @objc private func nextPage() {
        UIView.animate(withDuration: 0.3) {
            self.horizontalScrollView.contentOffset.x += UIScreen.main.bounds.width
        }
    }

    @objc private func seeMoreButtonTapped(_ sender: UIButton) {
        self.listener(.seeMoreCharts)
    }

    @objc private func twitterButtonTapped(_ sender: UIButton) {
        if let twitterId = input.group.twitterId {
            if let url = URL(string: "https://twitter.com/\(twitterId)") {
                self.listener(.twitter(url))
            }
        }
    }
    
    @objc private func youtubeButtonTapped(_ sender: UIButton) {
        if let youtubeChannelId = input.group.youtubeChannelId {
            if let url = URL(string: "https://www.youtube.com/channel/\(youtubeChannelId)") {
                self.listener(.youtube(url))
            }
        }
    }

    @objc private func appleMusicButtonTapped(_ sender: UIButton) {
        print("itunes")
    }

    @objc private func spotifyButtonTapped(_ sender: UIButton) {
        print("spotify")
    }
}
