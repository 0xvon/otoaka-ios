//
//  LiveDetailHeaderView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/30.
//

import DomainEntity
import InternalDomain
import UIKit
import ImagePipeline

public final class LiveDetailHeaderView: UIView {
    public typealias Input = (
        live: Live,
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
    private lazy var liveInformationView: LiveInformationView = {
        let view = LiveInformationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var liveThumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.opacity = 0.6
        imageView.clipsToBounds = true
        return imageView
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
        liveInformationView.update(input: input)
        if let artworkURL = input.live.artworkURL {
            input.imagePipeline.loadImage(artworkURL, into: liveThumbnailView)
        }
    }
    
    func bind() {}
    
    private func setup() {
        backgroundColor = .clear
        
        addSubview(liveThumbnailView)
        NSLayoutConstraint.activate([
            liveThumbnailView.topAnchor.constraint(equalTo: topAnchor),
            liveThumbnailView.bottomAnchor.constraint(equalTo: bottomAnchor),
            liveThumbnailView.leftAnchor.constraint(equalTo: leftAnchor),
            liveThumbnailView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
        
        addSubview(horizontalScrollView)
        NSLayoutConstraint.activate([
            horizontalScrollView.topAnchor.constraint(equalTo: topAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalScrollView.leftAnchor.constraint(equalTo: leftAnchor),
            horizontalScrollView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
        
        do {
            let arrangedSubviews = [liveInformationView]
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
            
            bind()
        }
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
        
    }

}
