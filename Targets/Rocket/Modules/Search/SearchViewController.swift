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
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchResultsUpdater = self
        controller.delegate = self
        controller.searchBar.delegate = self
        return controller
    }()
    private lazy var categoryStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 24
        
        stackView.addArrangedSubview(categoryTitle)
        NSLayoutConstraint.activate([
            categoryTitle.heightAnchor.constraint(equalToConstant: 16),
            categoryTitle.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(liveCategoryButton)
        NSLayoutConstraint.activate([
            liveCategoryButton.heightAnchor.constraint(equalToConstant: 28),
            liveCategoryButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(groupCategoryButton)
        NSLayoutConstraint.activate([
            groupCategoryButton.heightAnchor.constraint(equalToConstant: 28),
            groupCategoryButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(userCategoryButton)
        NSLayoutConstraint.activate([
            userCategoryButton.heightAnchor.constraint(equalToConstant: 28),
            userCategoryButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        return stackView
    }()
    private lazy var categoryTitle: UILabel = {
        let label = UILabel()
        label.text = "カテゴリ"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .largeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var liveCategoryButton: CategoryButton = {
        let button = CategoryButton()
        button.addTarget(self, action: #selector(liveCategoryTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("ライブを探す", for: .normal)
        button.setTitle("ライブを探す", for: .highlighted)
        button._setImage(
            image: UIImage(named: "selectedTicketIcon")!
        )
        return button
    }()
    private lazy var groupCategoryButton: CategoryButton = {
        let button = CategoryButton()
        button.addTarget(self, action: #selector(groupCategoryTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("アーティストを探す", for: .normal)
        button._setImage(
            image: UIImage(systemName: "guitars.fill")!.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal)
        )
        return button
    }()
    private lazy var userCategoryButton: CategoryButton = {
        let button = CategoryButton()
        button.addTarget(self, action: #selector(userCategoryTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("ユーザーを探す", for: .normal)
        button._setImage(
            image: UIImage(systemName: "person.fill")!
                .withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal)
        )
        return button
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

        title = "探す"
        view.backgroundColor = Brand.color(for: .background(.primary))
        navigationItem.searchController = searchController
        searchController.searchBar.scopeButtonTitles = viewModel.scopeButtonTitles
        
        view.addSubview(categoryStackView)
        NSLayoutConstraint.activate([
            categoryStackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            categoryStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            categoryStackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 16),
        ])

        bind()
    }

    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateSearchResult(let input):
                self.searchResultController.inject(input)
            }
        }.store(in: &cancellables)
    }
    
    @objc private func liveCategoryTapped() {
        let vc = SearchLiveViewController(dependencyProvider: dependencyProvider)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func groupCategoryTapped() {
        let vc = SearchGroupViewController(dependencyProvider: dependencyProvider)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func userCategoryTapped() {
        let vc = SearchUserViewController(dependencyProvider: dependencyProvider)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    deinit {
        print("SearchVC.deinit")
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        viewModel.updateSearchResults(
            queryText: searchController.searchBar.text,
            scopeIndex: searchController.searchBar.selectedScopeButtonIndex)
    }
}

extension SearchViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        viewModel.updateSearchResults(
            queryText: searchController.searchBar.text,
            scopeIndex: searchController.searchBar.selectedScopeButtonIndex)
    }
    func willDismissSearchController(_ searchController: UISearchController) {
        viewModel.updateSearchResults(
            queryText: searchController.searchBar.text,
            scopeIndex: searchController.searchBar.selectedScopeButtonIndex)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearchResults(
            queryText: searchController.searchBar.text,
            scopeIndex: searchController.searchBar.selectedScopeButtonIndex)
    }
}

