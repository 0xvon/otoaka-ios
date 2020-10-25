//
//  LiveCell.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/22.
//

import UIKit

class LiveCell: UITableViewCell, ReusableCell {
    static var reusableIdentifier: String { "LiveCell" }

    typealias Input = Live
    var input: Input!
    
    @IBOutlet weak var liveTitleLabel: UILabel!
    @IBOutlet weak var bandsLabel: UILabel!
    @IBOutlet weak var placeView: BadgeView!
    @IBOutlet weak var dateView: BadgeView!
    @IBOutlet weak var listenButtonView: Button!
    @IBOutlet weak var buyTicketButtonView: Button!
    @IBOutlet weak var thumbnailView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        buyTicketButtonView.inject(input: (text: "チケット購入", image: UIImage(named: "ticket")))
        listenButtonView.inject(input: (text: "曲を聴く", image: UIImage(named: "play")))
        dateView.inject(input: (text: "明日18時", image: UIImage(named: "calendar")))
        placeView.inject(input: (text: "代々木公園", image: UIImage(named: "map")))
    }
    
    func inject(input: Live) {
        self.input = input
        setup()
    }

    func setup() {
//        self.backgroundColor = style.color.background.get()
        self.backgroundColor = UIColor(patternImage: UIImage(named: "live")!)
        self.layer.borderWidth = 1
        self.layer.borderColor = style.color.main.get().cgColor
        self.layer.cornerRadius = 10        
        
        self.liveTitleLabel.text = "BANGOHAN TOUR 2020 ~今日の夜はなまたまごとライスと米~"
        self.liveTitleLabel.font = style.font.xlarge.get()
        self.liveTitleLabel.textColor = style.color.main.get()
        self.liveTitleLabel.backgroundColor = .clear
        self.liveTitleLabel.lineBreakMode = .byWordWrapping
        self.liveTitleLabel.numberOfLines = 0
        self.liveTitleLabel.adjustsFontSizeToFitWidth = false
        self.liveTitleLabel.sizeToFit()

        self.bandsLabel.text = "masatojames, kateinoigakukun"
        self.bandsLabel.font = style.font.regular.get()
        self.bandsLabel.textColor = style.color.main.get()
        self.bandsLabel.lineBreakMode = .byWordWrapping
        self.bandsLabel.numberOfLines = 0
        self.bandsLabel.adjustsFontSizeToFitWidth = false
        self.bandsLabel.sizeToFit()
        
        self.thumbnailView.image = UIImage(named: "live")
        self.thumbnailView.contentMode = .scaleAspectFill
        self.thumbnailView.layer.opacity = 0.6
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func listen(_ listener: @escaping () -> Void) {
        listenButtonView.listen(listener)
    }
    
    func buyTicket(_ listener: @escaping () -> Void) {
        buyTicketButtonView.listen(listener)
    }
}
