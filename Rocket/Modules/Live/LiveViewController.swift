//
//  LiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import Endpoint
import UIKit

final class LiveViewController: UIViewController, Instantiable {

    typealias Input = User
    var input: Input!

    lazy var viewModel = LiveViewModel(
        outputHander: { output in
            switch output {
            case .get(let lives):
                self.lives = lives
                self.liveTableView.reloadData()
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: error.localizedDescription)
                }
            }
        }
    )

    var lives: [Live] = []
    var dependencyProvider: LoggedInDependencyProvider!
    @IBOutlet weak var liveTableView: UITableView!
    @IBOutlet weak var liveSearchBar: UISearchBar!

    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        viewModel.get()
    }

    func setup() {
        self.view.backgroundColor = style.color.background.get()
        self.view.tintColor = style.color.main.get()

        liveTableView.delegate = self
        liveTableView.dataSource = self
        liveTableView.register(
            UINib(nibName: "LiveCell", bundle: nil), forCellReuseIdentifier: "LiveCell")
        liveTableView.backgroundColor = style.color.background.get()

        liveSearchBar.barTintColor = style.color.background.get()
        liveSearchBar.searchTextField.placeholder = "ライブを探す"
        liveSearchBar.searchTextField.textColor = style.color.main.get()
    }

    @objc func tappedButton(sender: UIButton!) {
        let vc = BandViewController(dependencyProvider: dependencyProvider, input: ())
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension LiveViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.lives.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let live: Live = self.lives[indexPath.section]
        let cell: LiveCell = tableView.reuse(LiveCell.self, input: live, for: indexPath)
        cell.listen { [weak self] in
            self?.listenButtonTapped(cellIndex: indexPath.section)
        }
        cell.buyTicket { [weak self] in
            self?.buyTicketButtonTapped(cellIndex: indexPath.section)
        }
        return cell
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
                input: (title: "LIVE", font: style.font.xlarge.get(), color: style.color.main.get())
            )
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
        let live = self.lives[indexPath.section]
        let vc = LiveDetailViewController(dependencyProvider: self.dependencyProvider, input: live)
        self.navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func listenButtonTapped(cellIndex: Int) {
        print("listen \(cellIndex) music")
    }

    private func buyTicketButtonTapped(cellIndex: Int) {
        print("buy \(cellIndex) ticket")
    }
}
