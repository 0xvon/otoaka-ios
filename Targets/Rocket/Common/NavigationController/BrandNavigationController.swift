//
//  BrandNavigationController.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/29.
//

import UIKit
import UIComponent

class BrandNavigationController: UINavigationController {
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        setupStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupStyle()
    }

    private func setupStyle() {
        navigationBar.prefersLargeTitles = true
        navigationBar.largeTitleTextAttributes = [
            .foregroundColor: Brand.color(for: .text(.primary))
        ]
        navigationBar.barTintColor = Brand.color(for: .background(.navigationBar))
        navigationBar.tintColor = Brand.color(for: .text(.primary))
        navigationBar.titleTextAttributes = [
            .foregroundColor: Brand.color(for: .text(.primary))
        ]
    }
}

