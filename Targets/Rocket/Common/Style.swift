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
    "#ロック好きならロケバン",
    "#音楽記録",
    "#日曜日だし邦ロック好きな人と繋がりたい",
]

enum ShareType {
    case feed(UserFeedSummary)
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
}

extension UIViewController {
    func showAlert(title: String = "（’・_・｀）", message: String = "ネットワークエラーが発生しました。時間をおいて再度お試しください。") {
        let alertController = UIAlertController(
            title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let cancelAction = UIAlertAction(
            title: "OK", style: UIAlertAction.Style.cancel,
            handler: { action in })
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func downloadImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.showResultOfSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func shareWithTwitter(type: ShareType) {
        switch type {
        case .feed(let feed):
            let shareText: String = "\(feed.text)"
            guard let url = OgpHtmlClient().getOgpUrl(imageUrl: feed.ogpUrl!, title: feed.title) else { return }
            let scheme = URL(string: "twitter://post?message=\(shareText)\n\n\(hashTags.joined(separator: " "))\n\n\(url)\n".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            UIApplication.shared.open(scheme!, options: [:], completionHandler: nil)
        case .group(let group):
            let shareText: String = "\(group.name)"
            guard let url = OgpHtmlClient().getOgpUrl(imageUrl: group.artworkURL!.absoluteString, title: group.name) else { return }
            let scheme = URL(string: "twitter://post?message=\(shareText)\n\n\(hashTags.joined(separator: " "))\n\n\(url)\n".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            UIApplication.shared.open(scheme!, options: [:], completionHandler: nil)
        case .live(let live):
            let shareText: String = "\(live.title)"
            guard let url = OgpHtmlClient().getOgpUrl(imageUrl: live.artworkURL!.absoluteString, title: live.title) else { return }
            let scheme = URL(string: "twitter://post?message=\(shareText)\n\n\(hashTags.joined(separator: " "))\n\n\(url)\n".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            UIApplication.shared.open(scheme!, options: [:], completionHandler: nil)
        }
    }
    
    func shareFeedWithInstagram(feed: UserFeedSummary) {
        switch feed.feedType {
        case .youtube(let url):
            let youTubeClient = YouTubeClient(url: url.absoluteString)
            let thumbnail = youTubeClient.getThumbnailUrl()
            let cardView = UINib(nibName: "FeedCardView", bundle: nil)
                .instantiate(withOwner: nil, options: nil).first as! FeedCardView
            cardView.inject(input: (feed: feed, artwork: thumbnail))
            guard let image = cardView.getSnapShot() else { return }
            let url = URL(string: "instagram-stories://share")
            guard let pngImageData = image.pngData() else { return }
            let items: NSArray = [["com.instagram.sharedSticker.stickerImage": pngImageData,
                                   "com.instagram.sharedSticker.backgroundTopColor": "#49A1F8",
                                   "com.instagram.sharedSticker.backgroundBottomColor": "#EA6E57"]]
            UIPasteboard.general.setItems(items as! [[String : Any]], options: [:])
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
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
}
