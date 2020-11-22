//
//  Instantiable.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import UIKit

protocol Instantiable {
    associatedtype Input
    associatedtype Provider
    
    init(dependencyProvider: Provider, input: Input)
}

protocol ViewInstantiable {
    associatedtype Input
    
    static var xibName: String { get }
    var input: Input! { get set }
    
    func inject(input: Input)
}

extension ViewInstantiable {
    init(input: Input) {
        let xib = UINib(nibName: Self.xibName, bundle: nil)
        let view = xib.instantiate(withOwner: Self.self).first
        
        self = view as! Self
        
        self.input = input
        self.inject(input: input)
    }
}
