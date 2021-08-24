//
//  LiveInformationView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/30.
//

import Foundation
import UIKit
import DomainEntity

class LiveInformationView: UIView {
    public typealias Input = LiveDetailHeaderView.Input
    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()

    private lazy var liveTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.font = Brand.font(for: .xlargeStrong)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = false
        return label
    }()
    private lazy var hostGroupNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .medium)
        label.textColor = Brand.color(for: .text(.primary))
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = false
        label.sizeToFit()
        return label
    }()
    
    private let mapBadgeView: BadgeView = {
        let mapBadgeView = BadgeView(
            text: "不明",
            image: UIImage(systemName: "mappin.and.ellipse")!
                .withTintColor(.white, renderingMode: .alwaysOriginal)
        )
        mapBadgeView.translatesAutoresizingMaskIntoConstraints = false
        return mapBadgeView
    }()
    private let dateBadgeView: BadgeView = {
        let dateBadgeView = BadgeView(
            image: UIImage(systemName: "calendar")!
                .withTintColor(.white, renderingMode: .alwaysOriginal)
        )
        dateBadgeView.translatesAutoresizingMaskIntoConstraints = false
        return dateBadgeView
    }()
    private lazy var likeButton: ToggleButton = {
        let button = ToggleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 16
        button.setImage(
            UIImage(systemName: "heart")!.withTintColor(Brand.color(for: .text(.toggle)), renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "heart.fill")!.withTintColor(.black, renderingMode: .alwaysOriginal), for: .selected)
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    /*
    private let productionBadgeView: BadgeView = {
        let productionBadgeView = BadgeView(text: "Japan Music Systems", image: UIImage(named: "production"))
        productionBadgeView.translatesAutoresizingMaskIntoConstraints = false
        productionBadgeView.isHidden = true
        return productionBadgeView
    }()
    private let labelBadgeView: BadgeView = {
        let labelBadgeView = BadgeView(text: "Intact Records", image: UIImage(named: "record"))
        labelBadgeView.translatesAutoresizingMaskIntoConstraints = false
        labelBadgeView.isHidden = true
        return labelBadgeView
    }()
*/

    func update(input: Input) {
        dateBadgeView.title = input.live.live.openAt ?? "不明"
        liveTitleLabel.text = input.live.live.title
        hostGroupNameLabel.text = input.live.live.hostGroup.name
        mapBadgeView.title = input.live.live.liveHouse ?? "不明"
        likeButton.isHidden = false
        likeButton.isSelected = input.live.isLiked
    }

    private func setup() {
        backgroundColor = .clear

        addSubview(liveTitleLabel)
        NSLayoutConstraint.activate([
            liveTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            liveTitleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            rightAnchor.constraint(equalTo: liveTitleLabel.rightAnchor, constant: 54),
        ])
        
        addSubview(hostGroupNameLabel)
        NSLayoutConstraint.activate([
            hostGroupNameLabel.topAnchor.constraint(equalTo: liveTitleLabel.bottomAnchor, constant: 8),
            hostGroupNameLabel.leftAnchor.constraint(
                equalTo: liveTitleLabel.leftAnchor),
            hostGroupNameLabel.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -54),
        ])
        
        addSubview(likeButton)
        NSLayoutConstraint.activate([
            likeButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            likeButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            likeButton.widthAnchor.constraint(equalToConstant: 32),
            likeButton.heightAnchor.constraint(equalTo: likeButton.widthAnchor),
        ])

        addSubview(dateBadgeView)
        NSLayoutConstraint.activate([
            dateBadgeView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            dateBadgeView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            dateBadgeView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            dateBadgeView.heightAnchor.constraint(equalToConstant: 30),
        ])

        addSubview(mapBadgeView)
        NSLayoutConstraint.activate([
            mapBadgeView.bottomAnchor.constraint(equalTo: dateBadgeView.topAnchor, constant: -8),
            mapBadgeView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            mapBadgeView.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            mapBadgeView.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    // MARK: - Output
    private var listener: (Output) -> Void = { listenType in }
    public func listen(_ listener: @escaping (Output) -> Void) {
        self.listener = listener
    }

    public enum Output {
        case arrowButtonTapped
        case likeButtonTapped
    }
    @objc private func touchUpInsideArrowButton() {
        listener(.arrowButtonTapped)
    }
    
    @objc private func likeButtonTapped() {
        listener(.likeButtonTapped)
    }
}

#if PREVIEW
    import SwiftUI
    import StubKit
    import Foundation

    struct LiveInformationView_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                ViewWrapper(
                    view: {
                        let input: LiveInformationView.Input = try! Stub.make()
                        let contentView = LiveInformationView()
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

