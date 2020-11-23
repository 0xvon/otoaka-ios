//
//  ErrorType.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/23.
//

import Foundation

enum APIError: Error {
    case invalidStatus(String)
}

enum ViewModelError: Error {
    case notFoundError(String)
}
