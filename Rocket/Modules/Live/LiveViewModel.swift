//
//  LiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit
import Endpoint

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
        let lives = [
            Live(id: "123", title: "BANGOHAN TOUR 2020", type: .battles, host_id: "12345", open_at: "明日", start_at: "12時", end_at: "14時"),
            Live(id: "123", title: "BANGOHAN TOUR 2020", type: .battles, host_id: "12345", open_at: "明日", start_at: "12時", end_at: "14時"),
            Live(id: "123", title: "BANGOHAN TOUR 2020", type: .battles, host_id: "12345", open_at: "明日", start_at: "12時", end_at: "14時"),
            Live(id: "123", title: "BANGOHAN TOUR 2020", type: .battles, host_id: "12345", open_at: "明日", start_at: "12時", end_at: "14時"),
            Live(id: "123", title: "BANGOHAN TOUR 2020", type: .battles, host_id: "12345", open_at: "明日", start_at: "12時", end_at: "14時")
        ]
        
        outputHandler(.get(lives))
    }
}

struct Live {
    enum LiveType {
        case oneman
        case battles
        case festival
    }

    let id: String
    let title: String
    let type: LiveType
    let host_id: String
    let open_at: String
    let start_at: String
    let end_at: String
}
