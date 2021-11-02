//
//  StatsSummaryView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/02.
//

import UIKit

public final class StatsSummaryView: UIStackView {
    public typealias Input = (
        title: String,
        count: Int,
        unit: String
    )
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .medium)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    let countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .xlargeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    let unitLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .small)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        axis = .vertical
        alignment = .center
        addArrangedSubview(titleLabel)
        addArrangedSubview(countLabel)
        addArrangedSubview(unitLabel)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
    
    public func update(input: Input) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        titleLabel.text = input.title
        countLabel.text = formatter.string(from: NSNumber(value: input.count))
        unitLabel.text = input.unit
    }
}
