//
//  Style.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit

let per = 20
let textFieldHeight: CGFloat = 60

struct Components {
    let prefectures = [
        "東京都",
        "青森県",
        "大阪府",
    ]

    let parts = [
        "Vo.",
        "Gt.",
        "Ba.",
        "Dr",
        "Key.",
        "Gt. & Vo.",
        "Ba. & Vo.",
        "Key. & Vo.",
        "Gt. & Cho.",
        "Ba. & Cho.",
        "Dr. & Cho.",
        "Key. & Cho.",
    ]

    let years = [
        "1999",
        "2000",
        "2001",
        "2002",
        "2003",
        "2004",
        "2005",
        "2006",
        "2007",
        "2008",
        "2009",
        "2010",
        "2011",
        "2012",
        "2013",
        "2014",
        "2015",
        "2016",
        "2017",
        "2018",
        "2019",
        "2020",
        "2021",
        "2022",
        "2023",
        "2024",
        "2025",
        "2026",
    ]

    let liveStyles: [String] = [
        "ワンマン",
        "対バン",
        "フェス",
    ]

    let livehouses: [String] = [
        "ビルボードライブ東京",
        "TSUTAYA O-EAST",
        "TSUTAYA O-Crest",
        "SHIBUYA CYCLONE",
        "Zepp DiverCity(TOKYO)",
        "新宿BLAZE",
        "品川プリンスホテル　ステラボール",
        "東高円寺U.F.O.CLUB",
        "立川BABEL",
        "LIQUIDROOM",
        "新宿PIT INN",
        "原宿ASTRO HALL",
        "大塚MEETS",
        "新宿FACE",
        "KOENJI HIGH",
        "青山月見ル君想フ",
        "新宿ロフト",
        "ニコファーレ",
        "WWW / WWW X",
        "八王子RIPS",
        "KIWA",
        "新宿MARZ",
        "西荻窪FLAT",
        "東高円寺二万電圧",
        "ジャズレストラン 六本木サテンドール",
        "吉祥寺WARP",
        "shinjuku ANTIKNOCK",
        "duo MUSIC EXCHANGE",
        "UNIT",
        "南青山MANDALA",
        "SHIBUYA-La.mama",
        "BUSHBASH",
        "Blue Note Tokyo",
        "Zepp Tokyo",
        "八王子MatchVox",
    ]
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
