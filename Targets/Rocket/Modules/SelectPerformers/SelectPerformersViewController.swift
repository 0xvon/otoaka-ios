//
//  SearchBandViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/01.
//

import UIKit
import Endpoint

final class SelectPerformersViewController: UIViewController, Instantiable {
    typealias Input = [Group]
    var dependencyProvider: LoggedInDependencyProvider!
    var selectedGroups: [Group] = []
    var searchResults: [Group] = []
    
    private var groupTableView: UITableView!
    private var searchBar: UISearchBar!
    private var okButton: PrimaryButton!
    
    lazy var viewModel = SelectPerformersViewModel(
        apiClient: dependencyProvider.apiClient,
        s3Client: dependencyProvider.s3Client,
        outputHander: { output in
            switch output {
            case .search(let groups):
                DispatchQueue.main.async {
                    print(groups)
                    self.searchResults = groups
                    self.groupTableView.reloadData()
                }
            case .paginate(let groups):
                DispatchQueue.main.async {
                    self.searchResults += groups
                    self.groupTableView.reloadData()
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.selectedGroups = input

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.barTintColor = Brand.color(for: .background(.primary))
        searchBar.searchTextField.placeholder = "バンド名から探す"
        searchBar.searchTextField.textColor = Brand.color(for: .text(.primary))
        searchBar.returnKeyType = .go
        searchBar.delegate = self
        self.view.addSubview(searchBar)
        
        groupTableView = UITableView()
        groupTableView.translatesAutoresizingMaskIntoConstraints = false
        groupTableView.delegate = self
        groupTableView.dataSource = self
        groupTableView.tableFooterView = UIView(frame: .zero)
        groupTableView.separatorStyle = .none
        groupTableView.backgroundColor = Brand.color(for: .background(.primary))
        groupTableView.allowsMultipleSelection = true
        groupTableView.refreshControl = RefreshControl()
        groupTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroup(_:)), for: .valueChanged)
        groupTableView.register(
            UINib(nibName: "BandCell", bundle: nil), forCellReuseIdentifier: "BandCell")
        self.view.addSubview(groupTableView)
        
        let okButtonView = UIView()
        okButtonView.translatesAutoresizingMaskIntoConstraints = false
        okButtonView.backgroundColor = Brand.color(for: .background(.primary))
        self.view.addSubview(okButtonView)
        
        okButton = PrimaryButton(text: "ok")
        okButton.listen {
            self.okButtonTapped()
        }
        okButtonView.addSubview(okButton)
        okButtonView.layer.cornerRadius = 50
        
        let constraints: [NSLayoutConstraint] = [
            searchBar.topAnchor.constraint(equalTo: self.view.topAnchor),
            searchBar.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            searchBar.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            
            groupTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            groupTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            groupTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            
            okButtonView.topAnchor.constraint(equalTo: groupTableView.bottomAnchor),
            okButtonView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            okButtonView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            okButtonView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -24),
            okButtonView.heightAnchor.constraint(equalToConstant: 50),
            
            okButton.centerYAnchor.constraint(equalTo: okButtonView.centerYAnchor),
            okButton.heightAnchor.constraint(equalTo: okButtonView.heightAnchor),
            okButton.widthAnchor.constraint(equalToConstant: 300),
            okButton.centerXAnchor.constraint(equalTo: okButtonView.centerXAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    private var listener: ([Group]) -> Void = { groups in }
    func listen(_ listener: @escaping ([Group]) -> Void) {
        self.listener = listener
    }
    
    private func okButtonTapped() {
        self.dismiss(animated: true, completion: nil)
        self.listener(self.selectedGroups)
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
        return self.searchResults.count
        
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
        return 250
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let band = self.searchResults[indexPath.section]
        let cell = tableView.dequeueReusableCell(BandCell.self, input: band, for: indexPath)
        cell.selectionStyle = .none
        if self.selectedGroups.contains(where: { $0.id == band.id }) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            cell.accessoryType = .checkmark
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            cell.accessoryType = .none
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let band = self.searchResults[indexPath.section]
        self.selectedGroups.append(band)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let band = self.searchResults[indexPath.section]
        self.selectedGroups = self.selectedGroups.filter { $0.id != band.id }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (self.searchResults.count - indexPath.section) == 2 && self.searchResults.count % per == 0 {
            self.viewModel.paginateGroup()
        }
    }
}

extension SelectPerformersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let text = searchBar.text {
            print(text)
            self.viewModel.searchGroup(query: text)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
