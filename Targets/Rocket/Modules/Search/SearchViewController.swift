//
//  SearchViewController.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/31.
//

import UIKit
import UIComponent
import Combine

final class SearchViewController: UIViewController {

    let dependencyProvider: LoggedInDependencyProvider

    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
    lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: self.searchResultController)
        controller.searchBar.barTintColor = Brand.color(for: .background(.searchBar))
        controller.searchResultsUpdater = self
        controller.searchBar.barStyle = .black
        // Workaround: Force to use dark mode color scheme to change text field color
        controller.searchBar.overrideUserInterfaceStyle = .dark
        let segmentedControl = controller.searchBar.scopeSegmentedControl
        segmentedControl?.selectedSegmentTintColor = Brand.color(for: .background(.secondary))
        segmentedControl?.setTitleTextAttributes([.foregroundColor: Brand.color(for: .text(.primary))], for: .normal)
        return controller
    }()

    let viewModel: SearchViewModel
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = SearchViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "検索"
        navigationItem.searchController = searchController
        searchController.searchBar.scopeButtonTitles = viewModel.scopeButtonTitles

        bind()
    }

    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [weak self] output in
            switch output {
            case .updateSearchResult(let input):
                self?.searchResultController.inject(input)
            }
        }.store(in: &cancellables)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchResults(
            queryText: searchController.searchBar.text,
            scopeIndex: searchController.searchBar.selectedScopeButtonIndex)
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
