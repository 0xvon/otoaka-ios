//
//  SummarySectionHeader.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/29.
//

import UIKit

public final class SummarySectionHeader: UIStackView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.font(for: .xlargeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()

    public let seeMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("もっと見る", for: .normal)
        button.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        button.titleLabel?.font = Brand.font(for: .small)
        return button
    }()

    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    public init(title: String? = nil) {
        super.init(frame: .zero)
        self.title = title
        setup()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func touchUpInside() {
        self.listener()
    }

    private var listener: () -> Void = {}
    public func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }

    func setup() {
        layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        isLayoutMarginsRelativeArrangement = true
        addArrangedSubview(titleLabel)
        addArrangedSubview(UIView()) // Spacer
        addArrangedSubview(seeMoreButton)
        seeMoreButton.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
    }
}

#if PREVIEW
import SwiftUI

struct SummarySectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ViewWrapper(view: SummarySectionHeader(title: "LIVE"))
                .previewLayout(.fixed(width: 320, height: 48))
        }
        .background(Color.black)
    }
}
#endif
