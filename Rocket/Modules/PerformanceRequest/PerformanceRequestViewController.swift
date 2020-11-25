//
//  PerformanceRequestViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import UIKit
import Endpoint

final class PerformanceRequestViewController: UIViewController, Instantiable {
    typealias Input = Void
    var dependencyProvider: LoggedInDependencyProvider!
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var requestTableView: UITableView!
    private var requests: [PerformanceRequest] = []
    
    lazy var viewModel = PerformanceRequestViewModel(
        apiClient: dependencyProvider.apiClient,
        s3Bucket: dependencyProvider.s3Bucket,
        user: dependencyProvider.user,
        outputHander: { output in
            switch output {
            case .getRequests(let requests):
                DispatchQueue.main.async {
                    self.requests = requests
                    self.requestTableView.reloadData()
                }
            case .error(let error):
                print(error)
            }
        }
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        viewModel.getRequests()
    }
    
    func setup() {
        self.view.backgroundColor = style.color.background.get()
        self.title = "リクエスト一覧"
        
        requestTableView = UITableView()
        requestTableView.translatesAutoresizingMaskIntoConstraints = false
        requestTableView.separatorStyle = .none
        requestTableView.showsVerticalScrollIndicator = false
        requestTableView.delegate = self
        requestTableView.dataSource = self
        
        self.view.addSubview(requestTableView)
        
        let constraints: [NSLayoutConstraint] = [
        ]
        NSLayoutConstraint.activate(constraints)
    }
}

extension PerformanceRequestViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.requests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let request = self.requests[indexPath.section]
        let cell = tableView.reuse(PerformanceRequestCell.self, input: request, for: indexPath)
        cell.jumbToBandPage { [weak self] in
            self?.viewBandPage(cellIndex: indexPath.section)
        }
        return cell
    }
    
    private func viewBandPage(cellIndex: Int) {
        let band = self.requests[cellIndex].live.hostGroup
        let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: band)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
