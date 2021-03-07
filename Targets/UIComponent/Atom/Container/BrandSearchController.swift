//
//  BrandSearchController.swift
//  UIComponent
//
//  Created by kateinoigakukun on 2021/01/05.
//

import UIKit

public class BrandSearchController: UISearchController {
    public override init(searchResultsController: UIViewController?) {
        super.init(searchResultsController: searchResultsController)
        setup()
    }
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        searchBar.barTintColor = Brand.color(for: .background(.searchBar))
        searchBar.barStyle = .black
        // Workaround: Force to use dark mode color scheme to change text field color
        searchBar.overrideUserInterfaceStyle = .dark
        let segmentedControl = searchBar.scopeSegmentedControl
        segmentedControl?.selectedSegmentTintColor = Brand.color(for: .background(.secondary))
        segmentedControl?.setTitleTextAttributes([.foregroundColor: Brand.color(for: .text(.primary))], for: .normal)
    }
}


// MARK: - Workaround
fileprivate extension UISearchBar {
    var scopeSegmentedControl: UISegmentedControl? {
        subviews.flatMap { $0.subviews }.flatMap { $0.subviews }.lazy.compactMap {
            $0 as? UISegmentedControl
        }.first
    }
}
