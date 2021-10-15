//
//  ReusableCell+deprecated.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/10/15.
//

import UIKit

public protocol ReusableCell {
    associatedtype Input
    static var reusableIdentifier: String { get }

    func inject(input: Input)
}

extension UITableView {
    func registerCellClass<Cell: ReusableCell & AnyObject>(_ type: Cell.Type) {
        self.register(Cell.self, forCellReuseIdentifier: Cell.reusableIdentifier)
    }
    func dequeueReusableCell<Cell: ReusableCell>(
        _ type: Cell.Type = Cell.self, for indexPath: IndexPath
    ) -> Cell {
        self.dequeueReusableCell(withIdentifier: type.reusableIdentifier, for: indexPath) as! Cell
    }

    func dequeueReusableCell<Cell: ReusableCell>(
        _ type: Cell.Type = Cell.self, input: Cell.Input, for indexPath: IndexPath
    ) -> Cell {
        let cell = dequeueReusableCell(Cell.self, for: indexPath)
        cell.inject(input: input)
        return cell
    }
}

extension UICollectionView {
    func registerCellClass<Cell: ReusableCell & AnyObject>(_ type: Cell.Type) {
        self.register(Cell.self, forCellWithReuseIdentifier: Cell.reusableIdentifier)
    }
    func dequeueReusableCell<Cell: ReusableCell>(
        _ type: Cell.Type = Cell.self, for indexPath: IndexPath
    ) -> Cell {
        self.dequeueReusableCell(withReuseIdentifier: type.reusableIdentifier, for: indexPath) as! Cell
    }

    func dequeueReusableCell<Cell: ReusableCell>(
        _ type: Cell.Type = Cell.self, input: Cell.Input, for indexPath: IndexPath
    ) -> Cell {
        let cell = dequeueReusableCell(Cell.self, for: indexPath)
        cell.inject(input: input)
        return cell
    }
}
