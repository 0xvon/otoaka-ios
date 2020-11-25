//
//  LiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import Endpoint
import UIKit

class LiveViewModel {
    enum Output {
        case get([Live])
        case error(Error)
    }

    let outputHandler: (Output) -> Void
    init(outputHander: @escaping (Output) -> Void) {
        self.outputHandler = outputHander
    }

    func get() {

    }
}
