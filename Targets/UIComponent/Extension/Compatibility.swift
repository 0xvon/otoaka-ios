//
//  Compatibility.swift
//  UIComponent
//
//  Created by kateinoigakukun on 2020/12/29.
//

import Foundation
import UIKit

var cache: [String: UIImage] = NSMutableDictionary() as! [String: UIImage]

extension UIImageView {
    func loadImageAsynchronously(url: URL?, defaultUIImage: UIImage? = nil) {

        guard let url = url else {
            self.image = defaultUIImage
            return
        }
        let path = url.absoluteString
        if let data = cache[path] {
            self.image = data
            return
        }

        DispatchQueue.global().async {
            do {
                let imageData: Data? = try Data(contentsOf: url)
                DispatchQueue.main.async { [weak self] in
                    if let data = imageData {
                        cache[path] = UIImage(data: data)
                        self?.image = UIImage(data: data)
                    } else {
                        self?.image = defaultUIImage
                    }
                }
            } catch let error {
                print(error)
                DispatchQueue.main.async {
                    cache[path] = defaultUIImage
                    self.image = defaultUIImage
                }
            }
        }
    }
}
