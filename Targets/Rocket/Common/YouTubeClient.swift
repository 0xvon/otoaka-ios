//
//  YouTubeClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/05.
//

import UIKit
import Endpoint

class YouTubeClient {
    let url: String
    
    init(url: String) {
        self.url = url
    }
    
    func getId() -> String? {
        do {
            if url.contains("youtube.com") {
                let youTubeUri = try YouTubeURI.decode(url: URL(string: url)!)
                return youTubeUri.v
            } else if url.contains("youtu.be") {
                let youTubeUri = try YouTubeShorterURI.decode(url: URL(string: url)!)
                return youTubeUri.v
            } else {
                return nil
            }
        } catch let error {
            print(error)
            return nil
        }
        
    }
    
    func getThumbnailUrl() -> URL? {
        guard let id = self.getId() else { return nil }
        
        let thumbnail = "https://i.ytimg.com/vi/\(id)/hqdefault.jpg"
        return URL(string: thumbnail)
    }
    
    struct YouTubeURI: CodableURL {
        @StaticPath("watch") public var prefix: Void
        @Query public var v: String
        public init() {}
    }

    struct YouTubeShorterURI: CodableURL {
        @DynamicPath public var v: String
        public init() {}
    }
}


