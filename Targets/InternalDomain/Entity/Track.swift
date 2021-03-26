//
//  Track.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/24.
//

import Foundation

public struct Track {
    public var name: String
    public var artistName: String
    public var artwork: String
    public var trackType: TrackType
    
    public init(
        name: String, artistName: String, artwork: String, trackType: TrackType
    ) {
        self.name = name
        self.artistName = artistName
        self.artwork = artwork
        self.trackType = trackType
    }
}

public enum TrackType {
    case youtube(String)
    case appleMusic(String)
}
