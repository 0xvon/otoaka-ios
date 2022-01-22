//
//  BandDetailHeaderView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import Endpoint
import InternalDomain
import UIKit
import ImagePipeline

public final class BandDetailHeaderView: UIView {
    public typealias Input = (
        group: Endpoint.Group,
        groupItem: InternalDomain.YouTubeVideo?,
        isEntried: Bool,
        imagePipeline: ImagePipeline
    )

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

    public init() {
        super.init(frame: .zero)
        self.setup()
    }

    public init(input: Input) {
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
        bandInformationView.update(input: input)
        trackInformationView.update(input: (track: input.groupItem, imagePipeline: input.imagePipeline))
        if let artworkURL = input.group.artworkURL {
            input.imagePipeline.loadImage(artworkURL, into: bandImageView)
        }
        biographyTextView.text = input.group.biography
    }

    func bind() {
        bandInformationView.listen { [unowned self] output in
            switch output {
            case .arrowButtonTapped: self.nextPage()
            case .officialMarkTapped: listener(.officialMarkTapped)
            }
        }
        trackInformationView.listen { [unowned self] output in
            self.listener(.track(output))
        }
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

        bind()
    }

    private func nextPage() {
        UIView.animate(withDuration: 0.3) {
            // FIXME: Support landscape mode?
            self.horizontalScrollView.contentOffset.x += UIScreen.main.bounds.width
        }
    }

    // MARK: - Output
    private var listener: (Output) -> Void = { listenType in }
    public func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }
    
    public enum Output {
        case track(TrackInformationView.Output)
        case officialMarkTapped
    }
}

#if PREVIEW
import SwiftUI
import StubKit
import Foundation

struct BandDetailHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreviewWrapper(
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
