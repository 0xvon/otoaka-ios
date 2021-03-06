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

func getSNSShareContent(feed: UserFeedSummary) -> UIActivityViewController? {
    let shareText: String = "\(feed.text)\n\n \(hashTags.joined(separator: " "))"
    let url = OgpHtmlClient().getOgpUrl(imageUrl: feed.ogpUrl!, title: feed.title)
    guard let shareUrl = url else { return nil }
    
    let activityItems: [Any] = [shareText, shareUrl]
    let activityViewController = UIActivityViewController(
        activityItems: activityItems, applicationActivities: [])

    activityViewController.popoverPresentationController?.permittedArrowDirections = .up
    
    return activityViewController
}

func getSNSShareContent(group: Group) -> UIActivityViewController? {
    let shareText: String = "\(group.name)\n\n\(hashTags.joined(separator: " "))"
    let url = OgpHtmlClient().getOgpUrl(imageUrl: group.artworkURL!.absoluteString, title: group.name)
    guard let shareUrl = url else { return nil }
    
    let activityItems: [Any] = [shareText, shareUrl]
    let activityViewController = UIActivityViewController(
        activityItems: activityItems, applicationActivities: [])

    activityViewController.popoverPresentationController?.permittedArrowDirections = .up
    
    return activityViewController
}

func getSNSShareContent(live: Live) -> UIActivityViewController? {
    let shareText: String = "\(live.title)\n\n\(hashTags.joined(separator: " "))"
    let url = OgpHtmlClient().getOgpUrl(imageUrl: live.artworkURL!.absoluteString, title: live.title)
    guard let shareUrl = url else { return nil }
    
    let activityItems: [Any] = [shareText, shareUrl]
    let activityViewController = UIActivityViewController(
        activityItems: activityItems, applicationActivities: [])

    activityViewController.popoverPresentationController?.permittedArrowDirections = .up
    
    return activityViewController
}
