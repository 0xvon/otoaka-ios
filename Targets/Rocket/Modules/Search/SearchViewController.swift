//
//  SearchViewController.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/31.
//

import UIKit
import UIComponent
import Combine
import Instructions

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
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacer)
        NSLayoutConstraint.activate([
            spacer.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        stackView.addArrangedSubview(addTitle)
        NSLayoutConstraint.activate([
            addTitle.heightAnchor.constraint(equalToConstant: 16),
            addTitle.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        stackView.addArrangedSubview(liveAddButton)
        NSLayoutConstraint.activate([
            liveAddButton.heightAnchor.constraint(equalToConstant: 28),
            liveAddButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        stackView.addArrangedSubview(groupAddButton)
        NSLayoutConstraint.activate([
            groupAddButton.heightAnchor.constraint(equalToConstant: 28),
            groupAddButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
        
        return stackView
    }()
    private lazy var categoryTitle: UILabel = {
        let label = UILabel()
        label.text = "カテゴリで探す"
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
    private lazy var addTitle: UILabel = {
        let label = UILabel()
        label.text = "追加する"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Brand.font(for: .largeStrong)
        label.textColor = Brand.color(for: .text(.primary))
        return label
    }()
    private lazy var liveAddButton: CategoryButton = {
        let button = CategoryButton()
        button.addTarget(self, action: #selector(liveAddTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("ライブを追加", for: .normal)
        button._setImage(
            image: UIImage(named: "selectedTicketIcon")!
        )
        return button
    }()
    private lazy var groupAddButton: CategoryButton = {
        let button = CategoryButton()
        button.addTarget(self, action: #selector(groupAddTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("アーティストを追加", for: .normal)
        button._setImage(
            image: UIImage(systemName: "guitars.fill")!.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal)
        )
        return button
    }()
    
    private let coachMarksController = CoachMarksController()
    private lazy var coachSteps: [CoachStep] = [
        CoachStep(view: groupCategoryButton, hint: "このページではライブ、アーティスト、ファンを探すことができるよ！\n試しに好きなアーティストを探してみよう！", next: "ok"),
    ]

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
        
        coachMarksController.dataSource = self
        coachMarksController.delegate = self

        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if PRODUCTION
        let userDefaults = UserDefaults.standard
        let key = "SearchVCPresented_v3.2.0.r"
        if !userDefaults.bool(forKey: key) {
            coachMarksController.start(in: .currentWindow(of: self))
            userDefaults.setValue(true, forKey: key)
            userDefaults.synchronize()
        }
        #else
        coachMarksController.start(in: .currentWindow(of: self))
        #endif
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
    
    @objc private func groupAddTapped() {
        let vc = CreateBandViewController(dependencyProvider: dependencyProvider, input: ())
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func liveAddTapped() {
        print("hello")
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
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        viewModel.updateSearchResults(
            queryText: searchController.searchBar.text,
            scopeIndex: searchController.searchBar.selectedScopeButtonIndex)
    }
}

extension SearchViewController: UISearchControllerDelegate {
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
    }
}

extension SearchViewController: CoachMarksControllerDelegate, CoachMarksControllerDataSource {
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return coachSteps.count
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        return coachMarksController.helper.makeCoachMark(for: coachSteps[index].view)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: (UIView & CoachMarkBodyView), arrowView: (UIView & CoachMarkArrowView)?) {
        let coachStep = self.coachSteps[index]
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        coachViews.bodyView.hintLabel.text = coachStep.hint
        coachViews.bodyView.nextLabel.text = coachStep.next
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}
