//
//  PerformersInformationView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/30.
//

import Foundation
import UIKit
import DomainEntity

class PerformersInformationView: UIView {
    public typealias Input = [Group]
    var groups: [Group] = []
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private lazy var performersTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCellClass(GroupBannerCell.self)
        return tableView
    }()
    
    func update(input: Input) {
        self.groups = input
        self.performersTableView.reloadData()
    }
    
    private func setup() {
        backgroundColor = .clear
        
        addSubview(performersTableView)
        NSLayoutConstraint.activate([
            performersTableView.leftAnchor.constraint(
                equalTo: leftAnchor, constant: 16),
            performersTableView.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -16),
            performersTableView.bottomAnchor.constraint(
                equalTo: bottomAnchor, constant: -16),
            performersTableView.topAnchor.constraint(
                equalTo: topAnchor, constant: 16),
        ])
    }
    
    private var listener: (Output) -> Void = { listenType in }
        public func listen(_ listener: @escaping (Output) -> Void) {
            self.listener = listener
        }

        public enum Output {
            case didSelectPerformer(Group)
        }
}

extension PerformersInformationView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = groups[indexPath.section]
        self.listener(.didSelectPerformer(group))
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = groups[indexPath.section]
        let cell = tableView.dequeueReusableCell(GroupBannerCell.self, input: group, for: indexPath)
        return cell
    }
}
