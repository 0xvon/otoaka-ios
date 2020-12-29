import DomainEntity
import Foundation

public struct ChannelDetail: Codable {
    public var kind: String
    public var etag: String
    public var nextPageToken: String?
    public var prevPageToken: String?
    public var regionCode: String?
    public var pageInfo: PageInfo
    public var items: [ChannelItem]
    
    public struct PageInfo: Codable {
        public var totalResults: Int
        public var resultsPerPage: Int
    }
    
    public struct ChannelItem: Codable, Equatable {
        public var kind: String
        public var etag: String
        public var id: ItemId
        public var snippet: ItemSnippet
        
        public struct ItemId: Codable, Equatable {
            public var kind: String
            public var videoId: String
        }
        
        public struct ItemSnippet: Codable, Equatable {
            public var publishedAt: Date
            public var channelId: String?
            public var title: String?
            public var description: String?
            public var thumbnails: Tumbnails
            public var channelTitle: String
            public var liveBroadcastContent: String?
            public var publishTime: Date?
                
            public struct Tumbnails: Codable, Equatable {
                public var `default`: ThumbnailItem
                public var medium: ThumbnailItem
                public var high: ThumbnailItem
                
                public struct ThumbnailItem: Codable, Equatable {
                    public var url: String
                    public var width: Int
                    public var height: Int
                }
            }
        }
    }
}
