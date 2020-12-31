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
    public typealias Input = Live
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
        let startYear: String = {
            guard let openAt = input.openAt else { return "不明" }
            return dateFormatter.string(from: openAt)
        }()

        dateBadgeView.title = startYear
        liveTitleLabel.text = input.title
        hostGroupNameLabel.text = input.hostGroup.name
        mapBadgeView.title = input.liveHouse ?? "不明"
    }

    private func setup() {
        backgroundColor = .clear

        addSubview(liveTitleLabel)
        NSLayoutConstraint.activate([
            liveTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            liveTitleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            rightAnchor.constraint(equalTo: liveTitleLabel.rightAnchor, constant: 16),
        ])
        
        addSubview(hostGroupNameLabel)
        NSLayoutConstraint.activate([
            hostGroupNameLabel.topAnchor.constraint(equalTo: liveTitleLabel.bottomAnchor, constant: 8),
            hostGroupNameLabel.leftAnchor.constraint(
                equalTo: liveTitleLabel.leftAnchor),
            hostGroupNameLabel.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -16),
        ])

        addSubview(dateBadgeView)
        NSLayoutConstraint.activate([
            dateBadgeView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            dateBadgeView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            dateBadgeView.widthAnchor.constraint(equalToConstant: 160),
            dateBadgeView.heightAnchor.constraint(equalToConstant: 30),
        ])

        addSubview(mapBadgeView)
        NSLayoutConstraint.activate([
            mapBadgeView.bottomAnchor.constraint(equalTo: dateBadgeView.topAnchor, constant: -8),
            mapBadgeView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            mapBadgeView.widthAnchor.constraint(equalToConstant: 160),
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
    }
    @objc private func touchUpInsideArrowButton() {
        listener(.arrowButtonTapped)
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

