//
//  Style.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit

struct style {
    enum color {
        case main
        case second
        case background
        case subBackground
        case sub
        
        func get() -> UIColor {
            switch self {
            case .main:
                return UIColor.white
            case .second:
                return UIColor.systemGreen
            case .background:
                return UIColor.black
            case .subBackground:
                return UIColor.darkGray
            case .sub:
                return UIColor.systemGray
            }
        }
    }
    
//    一応書いとくけどIB内で設定するから使わない(迷ったら見てね的な)
    enum margin: Int {
        case box = 12
        case area = 16
        case letter = 8
    }
    
    enum font {
        case xlarge
        case large
        case regular
        case small
        
        func get() -> UIFont {
            switch self {
            case .xlarge:
                return UIFont.systemFont(ofSize: CGFloat(26), weight: UIFont.Weight(500))
            case .large:
                return UIFont.systemFont(ofSize: CGFloat(20), weight: UIFont.Weight(300))
            case .regular:
                return UIFont.systemFont(ofSize: CGFloat(14), weight: UIFont.Weight(100))
            case .small:
                return UIFont.systemFont(ofSize: CGFloat(10), weight: UIFont.Weight(100))
            }
        }
    }
    
}

extension UIView {
    func makeShadow() {
//        let shadowView = UIView(frame: frame)
//        shadowView.backgroundColor = self.backgroundColor
//        self.addSubview(shadowView)
//        self.sendSubviewToBack(shadowView)
//        shadowView.layer.cornerRadius = self.layer.cornerRadius
        self.layer.shadowOffset = CGSize(width: 10.0, height: 4.0)
        self.layer.shadowColor = style.color.main.get().cgColor
        self.layer.shadowOpacity = 0.6
        self.layer.shadowRadius = self.layer.cornerRadius
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

var cache: [String: UIImage] = NSMutableDictionary() as! [String : UIImage]

extension UIImageView {
    func loadImageAsynchronously(path: String?, defaultUIImage: UIImage? = nil) -> Void {
        
        guard let path = path else { self.image = defaultUIImage; return }
        
        if let data = cache[path] {
            self.image = data
            return;
        }
        
        DispatchQueue.global().async {
            do {
                let url: URL? = URL(string: path)
                let imageData: Data? = try Data(contentsOf: url!)
                DispatchQueue.main.async { [weak self] in
                    if let data = imageData {
                        cache[path] = UIImage(data: data)
                        self?.image = UIImage(data: data)
                    } else {
                        self?.image = defaultUIImage
                    }
                }
            }
            catch {
                DispatchQueue.main.async {
                    cache[path] = defaultUIImage
                    self.image = defaultUIImage
                }
            }
        }
    }
}
