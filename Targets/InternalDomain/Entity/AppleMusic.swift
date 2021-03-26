//
//  AppleMusic.swift
//  InternalDomain
//
//  Created by Masato TSUTSUMI on 2021/03/24.
//

import DomainEntity
import Foundation

public protocol AppleMusicPaginationQuery {
    var limit: Int { get set }
    var offset: Int { get set }
}

public struct AppleMusicPage<Item>: Codable where Item: Codable {
    public var meta: Meta
    public var results: Results<Item>
}

public struct Meta: Codable {
    public var results: MetaResults
    public struct MetaResults: Codable {
        public var order: [String]
        public var rawOrder: [String]
    }
}

public struct Results<Item: Codable>: Codable {
    public var songs: AppleMusicData<Item>
}

public struct AppleMusicData<Item>: Codable where Item: Codable {
    public var href: String?
    public var next: String?
    public var data: [Item]
}

public struct AppleMusicSong: Codable {
    public var id: String
    public var type: String
    public var href: String
    public var attributes: SongAttributes
    
    public struct SongAttributes: Codable {
        public var previews: [SongPreview]
        public var artwork: SongArtwork
        public var artistName: String
        public var url: String
        public var discNumber: Int
        public var genreNames: [String]
        public var durationInMillis: Int
        public var releaseDate: String
        public var name: String
        public var isrc: String
        public var hasLyrics: Bool
        public var albumName: String?
        public var playParams: SongPlayParams
        public var trackNumber: Int
        public var composerName: String?
    }
    
    public struct SongArtwork: Codable {
        public var width: Int
        public var height: Int
        public var url: String?
        public var bgColor: String?
        public var textColor1: String?
        public var textColor2: String?
        public var textColor3: String?
        public var textColor4: String?
    }
    
    public struct SongPlayParams: Codable {
        public var id: String
        public var kind: String
    }
    
    public struct SongPreview: Codable {
        public var url: String
    }
}
