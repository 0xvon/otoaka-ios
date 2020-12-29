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
        group: DomainEntity.Group,
        groupItem: ChannelDetail.ChannelItem?
    )

    var input: Input!

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
        return scrollView
    }()
    private let bandInformationView: BandInformationView = {
        let view = BandInformationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var trackInformationView: TrackInformationView = {
        let view = TrackInformationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var biographyView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    private lazy var bandImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.opacity = 0.6
        imageView.clipsToBounds = true
        return imageView
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

    public init(input: Input) {
        self.input = input
        super.init(frame: .zero)
        self.setup()
        self.update(input: input)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    public func update(input: Input) {
        self.input = input

        bandInformationView.update(input: input)
        if let groupItem = input.groupItem {
            trackInformationView.update(input: groupItem)
        }
        bandImageView.loadImageAsynchronously(url: input.group.artworkURL)
        biographyTextView.text = input.group.biography
    }

    @available(*, deprecated)
    public func inject(input: Input) {
    }

    func setup() {
        backgroundColor = .clear

        addSubview(bandImageView)
        NSLayoutConstraint.activate([
            bandImageView.topAnchor.constraint(equalTo: topAnchor),
            bandImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bandImageView.leftAnchor.constraint(equalTo: leftAnchor),
            bandImageView.rightAnchor.constraint(equalTo: rightAnchor),
        ])

        addSubview(horizontalScrollView)
        NSLayoutConstraint.activate([
            horizontalScrollView.topAnchor.constraint(equalTo: topAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalScrollView.leftAnchor.constraint(equalTo: leftAnchor),
            horizontalScrollView.rightAnchor.constraint(equalTo: rightAnchor),
        ])

        // Setup `biographyView` contents
        do {
            biographyView.addSubview(biographyTextView)
            
            NSLayoutConstraint.activate([
                biographyTextView.topAnchor.constraint(equalTo: biographyView.topAnchor, constant: 16),
                biographyTextView.bottomAnchor.constraint(equalTo: biographyView.bottomAnchor, constant: -16),
                biographyTextView.rightAnchor.constraint(equalTo: biographyView.rightAnchor, constant: -16),
                biographyTextView.leftAnchor.constraint(equalTo: biographyView.leftAnchor, constant: 16),
            ])
        }

        do {
            let arrangedSubviews = [bandInformationView, trackInformationView, biographyView,]
            let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            horizontalScrollView.addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                stackView.leftAnchor.constraint(equalTo: horizontalScrollView.leftAnchor),
                stackView.topAnchor.constraint(equalTo: horizontalScrollView.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: horizontalScrollView.bottomAnchor),
                stackView.rightAnchor.constraint(equalTo: horizontalScrollView.rightAnchor),
                stackView.widthAnchor.constraint(equalTo: horizontalScrollView.widthAnchor, multiplier: CGFloat(arrangedSubviews.count))
            ])
        }
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

#if PREVIEW
import SwiftUI
import StubKit
import Foundation

struct BandDetailHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(
                view: {
                    let wrapper = UIView()
                    wrapper.backgroundColor = .black
                    let contentView = try! BandDetailHeaderView(input: (group: Stub.make {
                        $0.set(\.name, value: "Band Name")
                        $0.set(\.biography, value: "Band Biography")
                        $0.set(\.hometown, value: "Band Hometown")
                        $0.set(\.since, value: Date())
                    }, groupItem: nil))
                    contentView.translatesAutoresizingMaskIntoConstraints = false
                    wrapper.addSubview(contentView)
                    let constraints = [
                        wrapper.topAnchor.constraint(equalTo: contentView.topAnchor),
                        wrapper.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor),
                        wrapper.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                        wrapper.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                        contentView.heightAnchor.constraint(equalToConstant: 250),
                    ]
                    NSLayoutConstraint.activate(constraints)
                    return wrapper
                }()
            )
                .previewLayout(.fixed(width: 320, height: 200))
        }
        .background(Color.black)
    }
}
#endif
