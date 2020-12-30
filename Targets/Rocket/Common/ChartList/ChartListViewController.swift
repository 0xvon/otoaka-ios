//
//  ChartListViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import InternalDomain
import DomainEntity

final class ChartListViewController: UIViewController, Instantiable {
    typealias Input = Group

    var dependencyProvider: LoggedInDependencyProvider!
    var input: Input!
    var charts: [ChannelDetail.ChannelItem] = []
    private var chartTableView: UITableView!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var viewModel = ChartListViewModel(
        apiClient: dependencyProvider.apiClient,
        group: input,
        auth: dependencyProvider.auth,
        outputHander: { output in
            switch output {
            case .getCharts(let charts):
                DispatchQueue.main.async {
                    self.charts = charts
                    self.chartTableView.reloadData()
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
        
    func setup() {
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        chartTableView = UITableView()
        chartTableView.translatesAutoresizingMaskIntoConstraints = false
        chartTableView.showsVerticalScrollIndicator = false
        chartTableView.tableFooterView = UIView(frame: .zero)
        chartTableView.separatorStyle = .none
        chartTableView.backgroundColor = Brand.color(for: .background(.primary))
        chartTableView.delegate = self
        chartTableView.dataSource = self
        chartTableView.register(
            UINib(nibName: "TrackCell", bundle: nil), forCellReuseIdentifier: "TrackCell")
        self.view.addSubview(chartTableView)
        
        chartTableView.refreshControl = BrandRefreshControl()
        chartTableView.refreshControl?.addTarget(
            self, action: #selector(refreshGroups(sender:)), for: .valueChanged)
        self.getCharts()
        
        let constraints: [NSLayoutConstraint] = [
            chartTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
            chartTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            chartTableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 32),
            chartTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -16),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func getCharts() {
        viewModel.getCharts()
    }
    
    @objc private func refreshGroups(sender: UIRefreshControl) {
        self.getCharts()
        sender.endRefreshing()
    }
}

extension ChartListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.charts.count
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
        return 400
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chart = self.charts[indexPath.section]
        let cell = tableView.dequeueReusableCell(TrackCell.self, input: chart, for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let chart = self.charts[indexPath.section]
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
