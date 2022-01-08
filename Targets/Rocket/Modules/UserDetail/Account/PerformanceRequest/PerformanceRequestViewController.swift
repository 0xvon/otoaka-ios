//
//  PerformanceRequestViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Endpoint
import UIKit
import Combine

final class PerformanceRequestViewController: UIViewController, Instantiable {
    typealias Input = Void
    let dependencyProvider: LoggedInDependencyProvider
    let viewModel: PerformanceRequestViewModel
    var cancellables: Set<AnyCancellable> = []

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.viewModel = PerformanceRequestViewModel(dependencyProvider: dependencyProvider)
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var requestTableView: UITableView = {
        let requestTableView = UITableView(frame: .zero, style: .grouped)
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
        return requestTableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
        viewModel.getRequests()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func bind() {
        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .reloadTableView:
                setTableViewBackgroundView(tableView: self.requestTableView)
                requestTableView.reloadData()
            case .didReplyRequest:
                setTableViewBackgroundView(tableView: self.requestTableView)
                requestTableView.reloadData()
            case .reportError(let error):
                print(error)
//                self.showAlert()
            }
        }.store(in: &cancellables)
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        self.title = "出演リクエスト一覧"

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
        return viewModel.state.requests.count
    }
    
    func setTableViewBackgroundView(tableView: UITableView) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .request, actionButtonTitle: "バンドを探す")
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            emptyCollectionView.listen { [unowned self] in
                self.didSearchButtonTapped()
            }
            return emptyCollectionView
        }()
        tableView.backgroundView = viewModel.state.requests.isEmpty ? emptyCollectionView : nil
        if let backgroundView = tableView.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ])
        }
    }
    
    func didSearchButtonTapped() {
        let vc = SearchResultViewController(dependencyProvider: dependencyProvider)
        vc.inject(.group(""))
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let request = viewModel.state.requests[indexPath.section]
        let cell = tableView.dequeueReusableCell(
            PerformanceRequestCell.self, input: (request: request, imagePipeline: dependencyProvider.imagePipeline),
            for: indexPath
        )
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
        if (viewModel.state.requests.count - indexPath.section) == 2 && viewModel.state.requests.count % per == 0 {
            self.viewModel.getRequests()
        }
    }

    private func viewBandPage(cellIndex: Int) {
        let band = viewModel.state.requests[cellIndex].live.hostGroup
        let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: band)
        present(vc, animated: true, completion: nil)
    }

    private func showAlertView(cellIndex: Int) {
        let request = viewModel.state.requests[cellIndex]
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
            handler: { action in })
        alertController.addAction(acceptAction)
        alertController.addAction(denyAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
        self.present(alertController, animated: true, completion: nil)
    }
}
