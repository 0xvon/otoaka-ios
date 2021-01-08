//
//  Style.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit
import InternalDomain

let per = 20
let textFieldHeight: CGFloat = 60
let dummySocialInputs: SocialInputs = try! JSONDecoder().decode(SocialInputs.self, from: Data(contentsOf: Bundle.main.url(forResource: "SocialInputs", withExtension: "json")!))

extension UIColor {
    var image: UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(self.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIImage {
    public convenience init(url: String) {
        let url = URL(string: url)
        do {
            let data = try Data(contentsOf: url!)
            self.init(data: data)!
            return
        } catch let err { print("Error : \(err.localizedDescription)") }
        self.init()
    }
}

extension UIImage {
    func fill(color: UIColor) -> UIImage? {
        let rect = CGRect(origin: .zero, size: self.size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        self.draw(in: rect)
        
        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return coloredImage
    }
}

var cache: [String: UIImage] = NSMutableDictionary() as! [String: UIImage]

extension UIImageView {
    @available(*, deprecated)
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

extension UIViewController {
    func showAlert(title: String, message: String?) {
        let alertController = UIAlertController(
            title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let cancelAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.cancel,
            handler: { action in })
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
