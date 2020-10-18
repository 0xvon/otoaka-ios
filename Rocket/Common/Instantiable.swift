//
//  Instantiable.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/18.
//

import UIKit

protocol XibInstantiable {
    associatedtype Input
    
    static var xibName: String { get }
    var input: Input! { get set }
    
    init(input: Input)
    
    func inject(input: Input)
}

extension XibInstantiable {
    init(input: Input) {
        let xib = UINib(nibName: Self.xibName, bundle: nil)
        let vc = xib.instantiate(withOwner: Self.self).first
        
        self = vc as! Self
        self.input = input
        self.inject(input: input)
    }
}
