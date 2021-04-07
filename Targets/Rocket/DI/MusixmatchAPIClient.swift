//
//  MusixmatchAPIClient.swift
//  InternalDomain
//
//  Created by Masato TSUTSUMI on 2021/04/07.
//

import Endpoint
import Foundation
import InternalDomain

public struct MatcherLyrics: EndpointProtocol {
    public typealias Request = Empty
    public typealias Response = SearchLyrics
    public struct URI: CodableURL {
        @StaticPath("ws", "1.1", "matcher.lyrics.get") public var prefix: Void
        @Query public var format: String?
        @Query public var callback: String?
        @Query public var q_track: String?
        @Query public var q_artist: String?
        public init() {}
    }
    public static let method: HTTPMethod = .get
}
