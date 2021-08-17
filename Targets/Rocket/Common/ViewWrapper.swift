//
//  ViewWrapper.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/17.
//

import Foundation

import UIKit

public protocol ViewWrapper {
    var view: UIView! { get }
}

extension UIViewController: ViewWrapper {}
extension UIView: ViewWrapper {
    public var view: UIView! { return self }
}
