//
//  LiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit

final class LiveViewController: UIViewController, Instantiable {
    
    typealias Input = Void
    
    lazy var viewModel = LiveViewModel(
        outputHander: { output in
            switch output {
            case .get(let lives):
                self.lives = lives
                self.liveTableView.reloadData()
            case .error(let error):
                print(error)
            }
        }
    )
    
    var lives: [Live] = []
    var dependencyProvider: DependencyProvider!
    @IBOutlet weak var liveTableView: UITableView!
    @IBOutlet weak var liveSearchBar: UISearchBar!
    
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
        viewModel.get()
    }
    
    func setup() {
        self.view.backgroundColor = style.color.background.get()
        self.view.tintColor = style.color.main.get()
        
        liveTableView.delegate = self
        liveTableView.dataSource = self
        liveTableView.register(UINib(nibName: "LiveCell", bundle: nil), forCellReuseIdentifier: "LiveCell")
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
        print("\(indexPath.section) cell defined")
        let listenButtonView: Button = cell.listenButtonView.subviews.first as! Button
//        listenButtonView.button.tag = indexPath.section
        listenButtonView.button.addTarget(self, action: #selector(self.listenButtonTapped(_:)), for: .touchUpInside)
        
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
            let titleView = TitleLabelView(input: "LIVE")
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
    
    @objc private func listenButtonTapped(_ sender: UIButton) {
        print("hello \(sender.tag)")
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct LiveViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerWrapper<LiveViewController>(
            dependencyProvider: .make(),
            input: ()
        )
    }
}

#endif
