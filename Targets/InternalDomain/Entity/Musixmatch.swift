//
//  Musixmatch.swift
//  InternalDomain
//
//  Created by Masato TSUTSUMI on 2021/04/07.
//

import Foundation

public struct SearchLyrics: Codable {
    public var message: Message
    
    public struct Message: Codable {
        public var header: Header
        public var body: Body?
        
        public struct Header: Codable {
            public var status_code: Int
            public var execute_time: Float
        }
        
        public struct Body: Codable {
            public var lyrics: Lyrics
            
            public struct Lyrics: Codable {
                public var lyrics_id: Int
                public var explicit: Int
                public var lyrics_body: String
                public var script_tracking_url: String?
                public var pixel_tracking_url: String?
                public var lyrics_copyright: String?
                public var update_time: String?
            }
        }
    }
}
