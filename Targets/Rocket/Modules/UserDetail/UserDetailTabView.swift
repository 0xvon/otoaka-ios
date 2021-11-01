//
//  UserDetailTabView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/21.
//

import Foundation
import UIKit
import UIComponent
import Endpoint

public final class UserDetailTabView: UIView {
    
    weak var pageViewController: PageViewController?
    var scrollView: UIScrollView?
    var tabButtons: [UIButton] = []
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        return stackView
    }()
    private lazy var profileButton: TabItemButton = {
        let button = TabItemButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "person")!.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "person")!.withTintColor(.white, renderingMode: .alwaysOriginal), for: .selected)
        return button
    }()
    private lazy var statsButton: TabItemButton = {
        let button = TabItemButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chart.bar")!.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "chart.bar")!.withTintColor(.white, renderingMode: .alwaysOriginal), for: .selected)
        return button
    }()
    private lazy var myPostButton: TabItemButton = {
        let button = TabItemButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "doc.text")!.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "doc.text")!.withTintColor(.white, renderingMode: .alwaysOriginal), for: .selected)
        return button
    }()
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        backgroundColor = Brand.color(for: .background(.primary))
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        stackView.addArrangedSubview(profileButton)
        stackView.addArrangedSubview(statsButton)
        stackView.addArrangedSubview(myPostButton)
        
        tabButtons = [
            profileButton,
            statsButton,
            myPostButton,
        ]
        tabButtons.forEach {
            $0.addTarget(self, action: #selector(didSelect(at:)), for: .touchUpInside)
        }
        buttonStyle(at: 0)
    }
    
    func update(userDetail: UserDetail) {
    }
}

extension UserDetailTabView: PageTabView {
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: pageTabHeight)
    }
    public var pageTabHeight: CGFloat {
        return 48
    }

    public func setPageViewController(_ pageViewController: PageViewController) {
        self.pageViewController = pageViewController
        self.scrollView = pageViewController.containerScrollView
        self.scrollView?.delegate = self
    }

    @objc func didSelect(at button: UIButton) {
        guard let index = tabButtons.firstIndex(of: button) else { return }
        pageViewController?.selectViewController(at: index, tabButton: tabButtons)
    }
    
    func buttonStyle(at tab: Int) {
        for (index, button) in tabButtons.enumerated() {
            button.isSelected = tab == index
        }
    }
}

extension UserDetailTabView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            if scrollView.contentOffset.x < self.bounds.width / 2 {
                buttonStyle(at: 0)
            } else if scrollView.contentOffset.x  < self.bounds.width * 3 / 2 {
                buttonStyle(at: 1)
            } else {
                buttonStyle(at: 2)
            }
        }
    }
}
