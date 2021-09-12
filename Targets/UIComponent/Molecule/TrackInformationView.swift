//
//  TrackInformationView.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/29.
//

import UIKit
import Foundation
import InternalDomain
import ImagePipeline
import DomainEntity

public final class TrackInformationView: UIView {
    typealias Input = (
        track: InternalDomain.YouTubeVideo?,
        imagePipeline: ImagePipeline
    )
    // FIXME
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY年"
        return dateFormatter
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
            UIImage(systemName: "play.fill")!
                .withTintColor(.white, renderingMode: .alwaysOriginal),
            for: .normal)
        playButton.imageView?.contentMode = .scaleAspectFit
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

    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func update(input: Input) {
        if let groupItem = input.track {
            if let snippet = groupItem.snippet, let thumbnails = snippet.thumbnails, let high = thumbnails.high, let url = URL(string: high.url ?? "") {
                input.imagePipeline.loadImage(url, into: artworkImageView)
            }
            if let snippet = groupItem.snippet, let publishedAt = snippet.publishedAt {
                releasedDataLabel.text = self.dateFormatter.string(from: publishedAt)
            }
            
            trackNameLabel.text = groupItem.snippet?.title
            playButton.isHidden = false
        } else {
            artworkImageView.image = nil
            releasedDataLabel.text = ""
            trackNameLabel.text = ""
            playButton.isHidden = true
        }
    }
    private func setup() {
        backgroundColor = .clear
        addSubview(artworkImageView)
        NSLayoutConstraint.activate([
            artworkImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 36),
            artworkImageView.topAnchor.constraint(equalTo: topAnchor, constant: 48),
            artworkImageView.widthAnchor.constraint(equalToConstant: 120),
            artworkImageView.heightAnchor.constraint(equalToConstant: 120),
        ])

        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        addSubview(playButton)
        NSLayoutConstraint.activate([
            playButton.leftAnchor.constraint(equalTo: artworkImageView.rightAnchor, constant: 24),
            playButton.topAnchor.constraint(equalTo: artworkImageView.topAnchor, constant: 8),
            playButton.widthAnchor.constraint(equalToConstant: 150),
            playButton.heightAnchor.constraint(equalToConstant: 36),
        ])
        
        addSubview(trackNameLabel)
        NSLayoutConstraint.activate([
            trackNameLabel.leftAnchor.constraint(equalTo: playButton.leftAnchor),
            trackNameLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 8),
            trackNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
        ])
        
        addSubview(releasedDataLabel)
        NSLayoutConstraint.activate([
            releasedDataLabel.leftAnchor.constraint(equalTo: playButton.leftAnchor),
            releasedDataLabel.topAnchor.constraint(equalTo: trackNameLabel.bottomAnchor, constant: 4),
        ])
        
        seeMoreTracksButton.addTarget(self, action: #selector(seeMoreButtonTapped), for: .touchUpInside)
        addSubview(seeMoreTracksButton)
        NSLayoutConstraint.activate([
            seeMoreTracksButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            seeMoreTracksButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -32),
        ])
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -32),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        twitterButton.addTarget(self, action: #selector(twitterButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(twitterButton)
        NSLayoutConstraint.activate([twitterButton.widthAnchor.constraint(equalToConstant: 24)])
        
        youtubeButton.addTarget(self, action: #selector(youtubeButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(youtubeButton)
        
        appleMusicButton.addTarget(self, action: #selector(appleMusicButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(appleMusicButton)
        
        spotifyButton.addTarget(self, action: #selector(spotifyButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(spotifyButton)
    }
    
    // MARK: - Output
    private var listener: (Output) -> Void = { listenType in }
    public func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
    
    public enum Output {
        case playButtonTapped
        case twitterButtonTapped
        case youtubeButtonTapped
        case appleMusicButtonTapped
        case spotifyButtonTapped
        case seeMoreChartsTapped
    }

    @objc private func playButtonTapped() {
        listener(.playButtonTapped)
    }
    @objc private func twitterButtonTapped() {
        listener(.twitterButtonTapped)
    }
    
    @objc private func youtubeButtonTapped() {
        listener(.youtubeButtonTapped)
    }
    
    @objc private func appleMusicButtonTapped() {
        listener(.appleMusicButtonTapped)
    }

    @objc private func spotifyButtonTapped() {
        listener(.spotifyButtonTapped)
    }

    @objc private func seeMoreButtonTapped() {
        self.listener(.seeMoreChartsTapped)
    }
}

#if PREVIEW
import SwiftUI
import StubKit
import Foundation

struct TrackInformationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreviewWrapper(
                view: {
                    let input: TrackInformationView.Input = try! Stub.make()
                    let contentView = TrackInformationView()
                    contentView.update(input: input)
                    return contentView
                }()
            )
                .previewLayout(.fixed(width: 320, height: 200))
        }
        .background(Color.black)
    }
}
#endif
