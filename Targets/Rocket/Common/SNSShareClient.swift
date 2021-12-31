//
//  SNSShareClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/06.
//

import Foundation
import Endpoint
import UIKit

func getSNSShareContent(type: ShareType) -> UIActivityViewController {
    let ogp = "https://rocket-auth-storage.s3-ap-northeast-1.amazonaws.com/assets/public/ogp.png"
    let activityItems: [Any] = {
        switch type {
        case .user(let user): return []
        case .tip(_): return []
        case .post(let post):
            let shareText: String = "\(post.text)\n\n \(hashTags.joined(separator: " "))"
            guard let live = post.live else { return [shareText] }
            let url = OgpHtmlClient().getOgpUrl(imageUrl: live.artworkURL?.absoluteString ?? ogp, title: live.title)
            return [shareText, url as Any?].compactMap { $0 }
        case .group(let group):
            let shareText: String = "\(group.name)\n\n\(hashTags.joined(separator: " "))"
            let url = OgpHtmlClient().getOgpUrl(imageUrl: group.artworkURL!.absoluteString, title: group.name)
//            let image = group.artworkURL.map { UIImage(url: $0.absoluteString) }  ?? UIImage(named: "appIcon")
            
            return [shareText, url as Any?].compactMap { $0 }
        case .live(let live):
            let shareText: String = "\(live.title)\n\n\(hashTags.joined(separator: " "))"
            let url = OgpHtmlClient().getOgpUrl(imageUrl: live.artworkURL?.absoluteString ?? ogp, title: live.title)
//            let image = live.artworkURL.map { UIImage(url: $0.absoluteString) }  ?? UIImage(named: "appIcon")
            return [shareText, url as Any?].compactMap { $0 }
        }
    }()
    
    let activityViewController = UIActivityViewController(
        activityItems: activityItems, applicationActivities: [])

    activityViewController.popoverPresentationController?.permittedArrowDirections = .up
    
    return activityViewController
}
