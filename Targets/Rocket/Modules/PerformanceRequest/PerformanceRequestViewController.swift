//
//  PerformanceRequestViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Endpoint
import UIKit

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
    
    private var listener: () -> Void = {}
    func listen(_ listener: @escaping () -> Void) {
        self.listener = listener
    }

    lazy var viewModel = PerformanceRequestViewModel(
        apiClient: dependencyProvider.apiClient,
        s3Client: dependencyProvider.s3Client,
        user: dependencyProvider.user,
        outputHander: { output in
            switch output {
            case .getRequests(let requests):
                DispatchQueue.main.async {
                    self.requests += requests
                    self.setTableViewBackgroundView(tableView: self.requestTableView)
                    self.requestTableView.reloadData()
                }
            case .refreshRequests(let requests):
                DispatchQueue.main.async {
                    self.requests = requests
                    self.setTableViewBackgroundView(tableView: self.requestTableView)
                    self.requestTableView.reloadData()
                }
            case .replyRequest(let index):
                DispatchQueue.main.async {
                    self.requests.remove(at: index)
                    self.setTableViewBackgroundView(tableView: self.requestTableView)
                    self.requestTableView.reloadData()
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
        viewModel.getRequests()
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))

        requestTableView = UITableView(frame: .zero, style: .grouped)
        requestTableView.translatesAutoresizingMaskIntoConstraints = false
        requestTableView.separatorStyle = .none
        requestTableView.showsVerticalScrollIndicator = false
        requestTableView.delegate = self
        requestTableView.dataSource = self
        requestTableView.backgroundColor = .clear
        requestTableView.refreshControl = BrandRefreshControl()
        requestTableView.refreshControl?.addTarget(
            self, action: #selector(refreshPerformanceRequests(_:)), for: .valueChanged)
        requestTableView.register(
            UINib(nibName: "PerformanceRequestCell", bundle: nil),
            forCellReuseIdentifier: "PerformanceRequestCell")

        self.view.addSubview(requestTableView)

        let constraints: [NSLayoutConstraint] = [
            requestTableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            requestTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            requestTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16),
            requestTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func replyPerformanceRequest(request: PerformanceRequest, accept: Bool, cellIndex: Int) {
        viewModel.replyRequest(requestId: request.id, accept: accept, cellIndex: cellIndex)
    }
    
    @objc func refreshPerformanceRequests(_ sender: UIRefreshControl) {
        viewModel.refreshRequests()
        sender.endRefreshing()
    }
}

extension PerformanceRequestViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.requests.count
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .request, actionButtonTitle: "バンドを探す")
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            emptyCollectionView.listen {
                self.didSearchButtonTapped()
            }
            return emptyCollectionView
        }()
        tableView.backgroundView = requests.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
    
    func didSearchButtonTapped() {
        self.listener()
        self.dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let request = self.requests[indexPath.section]
        let cell = tableView.dequeueReusableCell(PerformanceRequestCell.self, input: request, for: indexPath)
        cell.jumbToBandPage { [weak self] in
            self?.viewBandPage(cellIndex: indexPath.section)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 332
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 60 : 16
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let view = UIView(
                frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 60))
            let titleBaseView = UIView(frame: CGRect(x: 16, y: 16, width: 300, height: 40))
            let titleView = TitleLabelView(
                input: (
                    title: "REQUESTS", font: Brand.font(for: .xlargeStrong), color: Brand.color(for: .text(.primary))
                ))
            titleBaseView.addSubview(titleView)
            view.addSubview(titleBaseView)
            return view
        default:
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.showAlertView(cellIndex: indexPath.section)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (self.requests.count - indexPath.section) == 2 && self.requests.count % per == 0 {
            self.viewModel.getRequests()
        }
    }

    private func viewBandPage(cellIndex: Int) {
        let band = self.requests[cellIndex].live.hostGroup
        let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: band)
        present(vc, animated: true, completion: nil)
    }

    private func showAlertView(cellIndex: Int) {
        let request = self.requests[cellIndex]
        let alertController = UIAlertController(
            title: "参加を承認しますか？", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let acceptAction = UIAlertAction(
            title: "承認", style: UIAlertAction.Style.default,
            handler: { action in
                self.replyPerformanceRequest(request: request, accept: true, cellIndex: cellIndex)
            })
        let denyAction = UIAlertAction(
            title: "却下", style: UIAlertAction.Style.destructive,
            handler: { action in
                self.replyPerformanceRequest(request: request, accept: false, cellIndex: cellIndex)
            })
        let cancelAction = UIAlertAction(
            title: "キャンセル", style: UIAlertAction.Style.cancel,
            handler: { action in
                print("close")
            })
        alertController.addAction(acceptAction)
        alertController.addAction(denyAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
}
