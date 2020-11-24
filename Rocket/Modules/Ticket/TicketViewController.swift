//
//  TicketViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import Foundation
import UIKit
import Endpoint

final class TicketViewController: UIViewController, Instantiable {
    
    typealias Input = Void
    let lives: [Live] = []
    
    var dependencyProvider: DependencyProvider!
    
    @IBOutlet weak var ticketsTableView: UITableView!
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        
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
        self.view.backgroundColor = style.color.background.get()
        
        ticketsTableView.delegate = self
        ticketsTableView.dataSource = self
        ticketsTableView.register(UINib(nibName: "LiveCell", bundle: nil), forCellReuseIdentifier: "LiveCell")
        ticketsTableView.backgroundColor = .clear
    }
}

extension TicketViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.lives.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let live = self.lives[indexPath.section]
        let cell = tableView.reuse(LiveCell.self, input:live, for: indexPath)
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
            let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 60))
            let titleBaseView = UIView(frame: CGRect(x: 16, y: 16, width: 300, height: 40))
            let titleView = TitleLabelView(input: (title: "TICKETS", font: style.font.xlarge.get(), color: style.color.main.get()))
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

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct TicketViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerWrapper<TicketViewController>(
            dependencyProvider: .make(),
            input: ()
        )
    }
}

#endif
