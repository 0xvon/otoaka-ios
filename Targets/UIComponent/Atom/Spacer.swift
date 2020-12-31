//
//  Spacer.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/31.
//

import UIKit

public final class Spacer: UIView {
    public enum Sizing {
        case fixed(CGFloat)
        case flexible

        fileprivate var pointValue: CGFloat {
            switch self {
            case .fixed(let constant):
                return constant
            case .flexible:
                return 0.0
            }
        }

        fileprivate var compressionResistancePriority: UILayoutPriority {
            switch self {
            case .fixed(_):
                return .required
            case .flexible:
                return .init(rawValue: 1)
            }
        }

        fileprivate var huggingPriority: UILayoutPriority {
            switch self {
            case .fixed(_):
                return .required
            case .flexible:
                return .init(rawValue: 1)
            }
        }
    }

    let width: Sizing
    let height: Sizing

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: width.pointValue, height: height.pointValue)
    }

    public init(width: Sizing = .flexible, height: Sizing = .flexible) {
        self.width = width
        self.height = height
        super.init(frame: .zero)

        self.setContentHuggingPriority(width.huggingPriority, for: .horizontal)
        self.setContentCompressionResistancePriority(width.compressionResistancePriority, for: .horizontal)
        self.setContentHuggingPriority(height.huggingPriority, for: .vertical)
        self.setContentCompressionResistancePriority(height.compressionResistancePriority, for: .vertical)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
