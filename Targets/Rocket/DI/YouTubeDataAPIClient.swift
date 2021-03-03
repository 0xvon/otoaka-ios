//
//  YouTubeDataAPIClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import Endpoint
import Foundation
import InternalDomain

public struct ListChannel: EndpointProtocol {
    public typealias Request = Empty
    public typealias Response = ChannelDetail
    public struct URI: CodableURL {
        @StaticPath("youtube", "v3", "search") public var prefix: Void
        @Query public var channelId: String?
        @Query public var q: String?
        @Query public var part: String
        @Query public var maxResults: Int?
        @Query public var order: String?
        @Query public var type: String?
        public init() {}
    }
    public static let method: HTTPMethod = .get
}
