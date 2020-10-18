//
//  Instantiable.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import UIKit

protocol Instantiable {
    associatedtype Input
    
    init(dependencyProvider: DependencyProvider, input: Input)
}
