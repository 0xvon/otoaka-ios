//
//  ReusableCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import UIKit

protocol ReusableCell {
    associatedtype Input
    static var reusableIdentifier: String { get }

    func inject(input: Input)
}

extension UITableView {

    func dequeueReusableCell<Cell: ReusableCell>(
        _ type: Cell.Type = Cell.self, for indexPath: IndexPath
    ) -> Cell {
        self.dequeueReusableCell(withIdentifier: type.reusableIdentifier, for: indexPath) as! Cell
    }

    func reuse<Cell: ReusableCell>(
        _ type: Cell.Type = Cell.self, input: Cell.Input, for indexPath: IndexPath
    ) -> Cell {
        let cell = dequeueReusableCell(Cell.self, for: indexPath)
        cell.inject(input: input)
        return cell
    }
}

extension UICollectionView {

    func dequeueReusableCell<Cell: ReusableCell>(
        _ type: Cell.Type = Cell.self, for indexPath: IndexPath
    ) -> Cell {
        self.dequeueReusableCell(withReuseIdentifier: type.reusableIdentifier, for: indexPath)
            as! Cell
    }

    func reuse<Cell: ReusableCell>(
        _ type: Cell.Type = Cell.self, input: Cell.Input, for indexPath: IndexPath
    ) -> Cell {
        let cell = dequeueReusableCell(Cell.self, for: indexPath)
        cell.inject(input: input)
        return cell
    }
}
