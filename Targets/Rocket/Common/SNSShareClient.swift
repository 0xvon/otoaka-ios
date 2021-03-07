//
//  SNSShareClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/06.
//

import Foundation
import Endpoint
import UIKit

let hashTags = [
    "#ロック好きならロケバン",
    "#音楽記録",
    "#日曜日だし邦ロック好きな人と繋がりたい",
]

enum ShareType {
    case feed(UserFeedSummary)
    case group(Group)
    case live(Live)
}

func getSNSShareContent(type: ShareType) -> UIActivityViewController {
    let activityItems: [Any] = {
        switch type {
        case .feed(let feed):
            let shareText: String = "\(feed.text)\n\n \(hashTags.joined(separator: " "))"
            let url = OgpHtmlClient().getOgpUrl(imageUrl: feed.ogpUrl!, title: feed.title)
//            let image = feed.ogpUrl.map { UIImage(url: $0) } ?? UIImage(named: "appIcon")
            return [shareText, url as Any?].compactMap { $0 }
        case .group(let group):
            let shareText: String = "\(group.name)\n\n\(hashTags.joined(separator: " "))"
            let url = OgpHtmlClient().getOgpUrl(imageUrl: group.artworkURL!.absoluteString, title: group.name)
//            let image = group.artworkURL.map { UIImage(url: $0.absoluteString) }  ?? UIImage(named: "appIcon")
            
            return [shareText, url as Any?].compactMap { $0 }
        case .live(let live):
            let shareText: String = "\(live.title)\n\n\(hashTags.joined(separator: " "))"
            let url = OgpHtmlClient().getOgpUrl(imageUrl: live.artworkURL!.absoluteString, title: live.title)
//            let image = live.artworkURL.map { UIImage(url: $0.absoluteString) }  ?? UIImage(named: "appIcon")
            return [shareText, url as Any?].compactMap { $0 }
        }
    }()
    
    let activityViewController = UIActivityViewController(
        activityItems: activityItems, applicationActivities: [])

    activityViewController.popoverPresentationController?.permittedArrowDirections = .up
    
    return activityViewController
}
