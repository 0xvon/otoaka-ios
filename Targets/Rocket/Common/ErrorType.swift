//
//  ErrorType.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/23.
//

import Foundation

enum ViewModelError: Error {
    case notFoundError(String)
}

enum S3Error: Error {
    case invalidUrl(String)
    case uploadFailed(String)
}
