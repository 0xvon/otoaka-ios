//
//  OgpHtmlClient.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/04.
//

import Foundation
import UIKit
import CodableURL

public class OgpHtmlClient {
    let baseUrl: String = "https://serverless-dev.rocketfor.band/custom_ogp_html"
    
    func getOgpUrl(imageUrl: String, title: String) -> URL? {
        guard let urlString = "\(baseUrl)?ogp_url=\(imageUrl)&title=\(title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: urlString)
    }
    
    init() {
    }
}
