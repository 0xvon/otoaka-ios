//
//  Style.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit
import InternalDomain
import Endpoint

let per = 20
let textFieldHeight: CGFloat = 60
let dummySocialInputs: SocialInputs = try! JSONDecoder().decode(SocialInputs.self, from: Data(contentsOf: Bundle.main.url(forResource: "SocialInputs", withExtension: "json")!))

let hashTags = [
    "#音楽好きならOTOAKA",
    "#音楽記録",
    "#日曜日だし邦ロック好きな人と繋がりたい",
]

enum ShareType {
    case post(Post)
    case group(Group)
    case live(Live)
}

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
    
    func rotatedBy(degree: CGFloat, isCropped: Bool = true) -> UIImage {
        let radian = -degree * CGFloat.pi / 180
        var rotatedRect = CGRect(origin: .zero, size: self.size)
        if !isCropped {
            rotatedRect = rotatedRect.applying(CGAffineTransform(rotationAngle: radian))
        }
        UIGraphicsBeginImageContext(rotatedRect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: rotatedRect.size.width / 2, y: rotatedRect.size.height / 2)
        context.scaleBy(x: 1.0, y: -1.0)

        context.rotate(by: radian)
        context.draw(self.cgImage!, in: CGRect(x: -(self.size.width / 2), y: -(self.size.height / 2), width: self.size.width, height: self.size.height))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return rotatedImage
    }
    
    func resize(width: Double) -> UIImage {
        let aspectScale = self.size.height / self.size.width
        let resizedSize = CGSize(width: width, height: width * Double(aspectScale))
        return self.resize(targetSize: resizedSize)
    }
    
    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size:targetSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

extension UIViewController {
    func showAlert(title: String = "（’・_・｀）", message: String = "ネットワークエラーが発生しました。時間をおいて再度お試しください。") {
        let alertController = UIAlertController(
            title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let cancelAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.cancel,
            handler: { action in })
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func downloadImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.showResultOfSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func shareWithTwitter(type: ShareType) {
        let ogp = "https://rocket-auth-storage.s3-ap-northeast-1.amazonaws.com/assets/public/ogp.png"
        switch type {
        case .post(let post):
            let shareText: String = post.text
            let ogpUrl = OgpHtmlClient().getOgpUrl(imageUrl: post.live?.artworkURL?.absoluteString ?? ogp, title: post.live?.title ?? "OTOAKA")
            guard let scheme = URL(string: "twitter://post?message=" + "\(shareText)\n\n\(hashTags.joined(separator: " "))\n\n\(ogpUrl)\n".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!) else { return }
            UIApplication.shared.open(scheme, options: [:], completionHandler: nil)
        case .group(let group):
            let shareText: String = "\(group.name)"
            let ogpUrl = OgpHtmlClient().getOgpUrl(imageUrl: group.artworkURL!.absoluteString, title: group.name)
            guard let scheme = URL(string: "twitter://post?message=" + "\(shareText)\n\n\(hashTags.joined(separator: " "))\n\n\(ogpUrl)\n".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!) else { return }
            UIApplication.shared.open(scheme, options: [:], completionHandler: nil)
        case .live(let live):
            let shareText: String = "\(live.title)"
            let ogpUrl = OgpHtmlClient().getOgpUrl(imageUrl: live.artworkURL!.absoluteString, title: live.title)
            guard let scheme = URL(string: "twitter://post?message=" + "\(shareText)\n\n\(hashTags.joined(separator: " "))\n\n\(ogpUrl)\n".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!) else { return }
            UIApplication.shared.open(scheme, options: [:], completionHandler: nil)
        }
    }
    
    func sharePostWithInstagram(post: Post) {
        let cell = UINib(nibName: "FeedCardView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! FeedCardView
        cell.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cell.widthAnchor.constraint(equalToConstant: 300),
        ])
        cell.inject(input: (post: post, artwork: nil))
        shareViewWithInstagram(cell: cell)
    }
    
    func shareViewWithInstagram(cell: UIView) {
        guard let image = cell.getSnapShot() else { return }
        let url = URL(string: "instagram-stories://share")
        guard let pngImageData = image.pngData() else { return }
        let items: NSArray = [["com.instagram.sharedSticker.stickerImage": pngImageData,
                               "com.instagram.sharedSticker.backgroundTopColor": "#233A60",
                               "com.instagram.sharedSticker.backgroundBottomColor": "#233A60"]]
        UIPasteboard.general.setItems(items as! [[String : Any]], options: [:])
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
    
    @objc func showResultOfSaveImage(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {

        var title = "保存完了"
        var message = "カメラロールに保存しました"

        if error != nil {
            title = "エラー"
            message = "保存に失敗しました"
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)

        self.present(alert, animated: true, completion: nil)
    }
}

extension UIView {
    func getSnapShot() -> UIImage? {
        let rect = self.frame
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { print("hey"); return nil }
        self.layer.render(in: context)
        let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func addBorders(width: CGFloat, color: UIColor, positions: [BorderPosition]) {
        positions.forEach { addBorder(width: width, color: color, position: $0) }
    }
    
    func addBorder(width: CGFloat, color: UIColor, position: BorderPosition) {
            let border = CALayer()

            switch position {
            case .top:
                border.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: width)
                border.backgroundColor = color.cgColor
                self.layer.addSublayer(border)
            case .left:
                border.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.height)
                border.backgroundColor = color.cgColor
                self.layer.addSublayer(border)
            case .right:
                print(self.frame.width)

                border.frame = CGRect(x: self.frame.width - width, y: 0, width: width, height: self.frame.height)
                border.backgroundColor = color.cgColor
                self.layer.addSublayer(border)
            case .bottom:
                border.frame = CGRect(x: 0, y: self.frame.height - width, width: self.frame.width, height: width)
                border.backgroundColor = color.cgColor
                self.layer.addSublayer(border)
            }
        }
}

enum BorderPosition {
    case top
    case left
    case right
    case bottom
}
