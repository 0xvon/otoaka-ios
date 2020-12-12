//
//  Pagenation.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/12.
//

import Endpoint

struct Pagenation<E: EndpointProtocol> {
    var requestUri: E.URI
    var event: Event
    
    enum Event {
        case isInitial
        case isLoading
        case isFinished
    }
}
