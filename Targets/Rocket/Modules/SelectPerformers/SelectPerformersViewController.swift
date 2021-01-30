//
//  SearchBandViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/01.
//

import Combine
import Endpoint
import SafariServices
import UIComponent
import UIKit

final class SelectPerformersViewController: UIViewController, Instantiable {
    typealias Input = [Group]

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.barTintColor = Brand.color(for: .background(.primary))
        searchBar.searchTextField.placeholder = "バンド名から探す"
        searchBar.searchTextField.textColor = Brand.color(for: .text(.primary))
        searchBar.returnKeyType = .go
        searchBar.delegate = self
        return searchBar
    }()
    private lazy var groupTableView: UITableView = {
        let groupTableView = UITableView(frame: .zero, style: .grouped)
        groupTableView.translatesAutoresizingMaskIntoConstraints = false
        groupTableView.delegate = self
        groupTableView.dataSource = self
        groupTableView.tableFooterView = UIView(frame: .zero)
        groupTableView.separatorStyle = .none
        groupTableView.backgroundColor = Brand.color(for: .background(.primary))
        
        groupTableView.refreshControl = BrandRefreshControl()
        groupTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroup(_:)), for: .valueChanged)
        groupTableView.registerCellClass(GroupCell.self)
        return groupTableView
    }()
    
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: SelectPerformersViewModel
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = SelectPerformersViewModel(dependencyProvider: dependencyProvider, selected: input)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .didSearch(_):
                setTableViewBackgroundView(tableView: groupTableView)
                groupTableView.reloadData()
            case .didPaginate(_):
                setTableViewBackgroundView(tableView: groupTableView)
                groupTableView.reloadData()
            case .didSelectPerformer(let group):
                listener(group)
            case .reportError(let error):
                self.showAlert(title: "エラー", message: error.localizedDescription)
            }
        }
        .store(in: &cancellables)
    }
    
    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "対バン相手を選択"
        self.navigationItem.largeTitleDisplayMode = .never
       
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            searchBar.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            searchBar.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: textFieldHeight),
        ])
        
        view.addSubview(groupTableView)
        NSLayoutConstraint.activate([
            groupTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            groupTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            groupTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            groupTableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            groupTableView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height - textFieldHeight),
        ])
    }
    
    private var listener: (Group) -> Void = { groups in }
    func listen(_ listener: @escaping (Group) -> Void) {
        self.listener = listener
    }
    
    @objc func refreshGroup(_ sender: UIRefreshControl) {
        self.viewModel.refreshSearchGroup()
        sender.endRefreshing()
    }
}

extension SelectPerformersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.state.searchResult.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 282
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = viewModel.state.searchResult[indexPath.section]
        let cell = tableView.dequeueReusableCell(GroupCell.self, input: (group: group, imagePipeline: dependencyProvider.imagePipeline), for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = viewModel.state.searchResult[indexPath.section]
        self.viewModel.didSelectPerformer(group: group)
        tableView.deselectRow(at: indexPath, animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (self.viewModel.state.searchResult.count - indexPath.section) == 2 && self.viewModel.state.searchResult.count % per == 0 {
            self.viewModel.paginateGroup()
        }
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .search, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        tableView.backgroundView = viewModel.state.searchResult.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
}

extension SelectPerformersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let text = searchBar.text {
            self.viewModel.searchGroup(query: text)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
