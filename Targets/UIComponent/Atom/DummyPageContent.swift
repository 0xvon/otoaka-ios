//
//  DummyPageContent.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/21.
//

import Foundation
import UIKit

public final class DummyPageContent: UIViewController {
    
    private lazy var _scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        return scrollView
    }()
    private lazy var scrollStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.axis = .vertical
        
        return stackView
    }()
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view = _scrollView
        view.backgroundColor = .clear
        view.addSubview(scrollStackView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: scrollStackView.topAnchor),
            view.bottomAnchor.constraint(equalTo: scrollStackView.bottomAnchor),
            view.leftAnchor.constraint(equalTo: scrollStackView.leftAnchor),
            view.rightAnchor.constraint(equalTo: scrollStackView.rightAnchor),
        ])
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Brand.color(for: .text(.primary))
        label.font = Brand.font(for: .xxlargeStrong)
        label.text = "dummy page content"
        scrollStackView.addArrangedSubview(label)
    }
}

extension DummyPageContent: PageContent {
    public var scrollView: UIScrollView {
        _ = view
        return self._scrollView
    }
}
