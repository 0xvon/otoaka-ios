//
//  BandInformationView.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/29.
//

import Foundation
import UIKit
import InternalDomain

class BandInformationView: UIView {
    public typealias Input = BandDetailHeaderView.Input
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
        dateFormatter.dateFormat = "YYYY年"
        return dateFormatter
    }()

    private lazy var bandNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.font = Brand.font(for: .xlargeStrong)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = false
        return label
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
    /*
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
//        let startYear: String = input.group.since.map { "\(dateFormatter.string(from: $0))結成" } ?? "結成年不明"
//        dateBadgeView.title = startYear
        bandNameLabel.text = input.group.name
//        mapBadgeView.title = input.group.hometown.map { "\($0)出身" } ?? "出身不明"
    }

    private func setup() {
        backgroundColor = .clear

        addSubview(bandNameLabel)
        NSLayoutConstraint.activate([
            bandNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            bandNameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            rightAnchor.constraint(equalTo: bandNameLabel.rightAnchor, constant: 16),
        ])

//        addSubview(dateBadgeView)
//        NSLayoutConstraint.activate([
//            dateBadgeView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
//            dateBadgeView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
//            dateBadgeView.widthAnchor.constraint(equalToConstant: 160),
//            dateBadgeView.heightAnchor.constraint(equalToConstant: 30),
//        ])
//
//        addSubview(mapBadgeView)
//        NSLayoutConstraint.activate([
//            mapBadgeView.bottomAnchor.constraint(equalTo: dateBadgeView.topAnchor, constant: -8),
//            mapBadgeView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
//            mapBadgeView.widthAnchor.constraint(equalToConstant: 160),
//            mapBadgeView.heightAnchor.constraint(equalToConstant: 30),
//        ])

        /*
        addSubview(labelBadgeView)
        NSLayoutConstraint.activate([
            labelBadgeView.bottomAnchor.constraint(equalTo: mapBadgeView.topAnchor, constant: -8),
            labelBadgeView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            labelBadgeView.widthAnchor.constraint(equalToConstant: 160),
            labelBadgeView.heightAnchor.constraint(equalToConstant: 30),
        ])

        addSubview(productionBadgeView)
        NSLayoutConstraint.activate([
            productionBadgeView.bottomAnchor.constraint(equalTo: labelBadgeView.topAnchor, constant: -8),
            productionBadgeView.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            productionBadgeView.widthAnchor.constraint(equalToConstant: 160),
            productionBadgeView.heightAnchor.constraint(equalToConstant: 30),
        ])
 */

        arrowButton.addTarget(
            self, action: #selector(touchUpInsideArrowButton), for: .touchUpInside)
        addSubview(arrowButton)
        NSLayoutConstraint.activate([
            arrowButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            arrowButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            arrowButton.widthAnchor.constraint(equalToConstant: 54),
            arrowButton.heightAnchor.constraint(equalToConstant: 28),
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

    struct BandInformationView_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                ViewWrapper(
                    view: {
                        let input: BandInformationView.Input = try! (
                            group: Stub.make {
                                $0.set(\.name, value: "Band Name")
                                $0.set(\.biography, value: "Band Biography")
                                $0.set(\.hometown, value: "Band Hometown")
                                $0.set(\.since, value: Date())
                            }, groupItem: nil
                        )
                        let contentView = BandInformationView()
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
