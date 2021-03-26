//
//  AppleMusicAPIClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/24.
//

import Endpoint
import Foundation
import InternalDomain

public struct SearchSongs: EndpointProtocol {
    public typealias Request = Empty
    public typealias Response = AppleMusicPage<AppleMusicSong>
    public struct URI: CodableURL, AppleMusicPaginationQuery {
        @StaticPath("v1", "catalog", "jp", "search") public var prefix: Void
        @Query public var term: String?
        @Query public var types: String?
        @Query public var limit: Int
        @Query public var offset: Int
        public init() {}
    }
    public static let method: HTTPMethod = .get
}
