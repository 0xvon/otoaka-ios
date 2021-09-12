//
//  LiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit
import DomainEntity
import UIComponent
import Combine

final class SearchLiveViewController: UIViewController {
    let dependencyProvider: LoggedInDependencyProvider
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()
    
    lazy var searchResultController: SearchResultViewController = {
        SearchResultViewController(dependencyProvider: self.dependencyProvider)
    }()
    lazy var searchController: UISearchController = {
        let controller = BrandSearchController(searchResultsController: self.searchResultController)
        controller.searchResultsUpdater = self
        controller.delegate = self
        controller.searchBar.delegate = self
        controller.searchBar.showsScopeBar = false
        controller.searchBar.placeholder = "公演名・アーティスト名から検索"
        return controller
    }()
    private lazy var filterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 24
        
        stackView.addArrangedSubview(dateTitle)
        NSLayoutConstraint.activate([
            dateTitle.heightAnchor.constraint(equalToConstant: 16),
            dateTitle.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(dateCategoryButton)
        NSLayoutConstraint.activate([
            dateCategoryButton.heightAnchor.constraint(equalToConstant: 28),
            dateCategoryButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        stackView.addArrangedSubview(artistTitle)
        NSLayoutConstraint.activate([
            dateTitle.heightAnchor.constraint(equalToConstant: 16),
            dateTitle.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        stackView.addArrangedSubview(artistCategoryButton)
        NSLayoutConstraint.activate([
            dateCategoryButton.heightAnchor.constraint(equalToConstant: 28),
            dateCategoryButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        let spacer_2 = UIView()
        spacer_2.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer_2)
        NSLayoutConstraint.activate([
            spacer_2.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        stackView.addArrangedSubview(searchButton)
        NSLayoutConstraint.activate([
            searchButton.heightAnchor.constraint(equalToConstant: 50),
            searchButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
                
        return stackView
    }()
    private lazy var dateTitle: UILabel = {
        let label = UILabel()
        label.text = "開催日"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .largeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var dateCategoryButton: CategoryButton = {
        let button = CategoryButton()
        button.addTarget(self, action: #selector(dateCategoryTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("開催日を選択 ~ 開催日を選択", for: .normal)
        button._setImage(
            image: UIImage(systemName: "calendar")!.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal)
        )
        return button
    }()
    
    private lazy var artistTitle: UILabel = {
        let label = UILabel()
        label.text = "アーティスト"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .largeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var artistCategoryButton: CategoryButton = {
        let button = CategoryButton()
        button.addTarget(self, action: #selector(artistCategoryTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("アーティストを選択", for: .normal)
        button._setImage(
            image: UIImage(systemName: "guitars.fill")!.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal)
        )
        return button
    }()
    private lazy var searchButton: PrimaryButton = {
        let button = PrimaryButton(text: "決定")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 25
        button.isEnabled = true
        button.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        return button
    }()
    
    let viewModel: SearchLiveViewModel
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = SearchLiveViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedLayoutIncludesOpaqueBars = true
        title = "ライブを探す"
        view.backgroundColor = Brand.color(for: .background(.primary))
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        view.addSubview(filterStackView)
        NSLayoutConstraint.activate([
            filterStackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            filterStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            filterStackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 44),
        ])
        
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.showsScopeBar = true
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .updateSearchResult(let input):
                self.searchResultController.inject(input)
            case .updateFilterCondition:
                if let group = viewModel.state.group {
                    artistCategoryButton.setTitle(group.group.name, for: .normal)
                } else {
                    artistCategoryButton.setTitle("アーティストを選択", for: .normal)
                }
                
                if let fromDate = viewModel.state.fromDate, let toDate = viewModel.state.toDate {
                    dateCategoryButton.setTitle("\(dateFormatter.string(from: fromDate)) ~ \(dateFormatter.string(from: toDate))", for: .normal)
                } else {
                    dateCategoryButton.setTitle("開催日を選択 ~ 開催日を選択", for: .normal)
                }
            }
        }.store(in: &cancellables)
    }
    
    @objc private func dateCategoryTapped() {
        let vc = SelectDateViewController(dependencyProvider: dependencyProvider)
        vc.listen { [unowned self] (fromDate, toDate) in
            viewModel.updateDate(fromDate: fromDate, toDate: toDate)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func artistCategoryTapped() {
        let vc = SelectGroupViewController(dependencyProvider: dependencyProvider)
        vc.listen { [unowned self] group in
            viewModel.updateGroup(group: group)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func searchButtonTapped() {
        let vc = FilterLiveViewController(dependencyProvider: dependencyProvider, groupId: viewModel.state.group?.group.id, fromDate: viewModel.state.fromDate, toDate: viewModel.state.toDate)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension SearchLiveViewController: UISearchBarDelegate {
}

extension SearchLiveViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text {
            viewModel.updateSearchResults(queryText: text)
        }
    }
}


extension SearchLiveViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
    }
}
