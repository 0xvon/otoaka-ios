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
    
    @IBOutlet weak var liveThumbnailView: UIImageView!
    @IBOutlet weak var liveTitleLabel: UILabel!
    @IBOutlet weak var bandsLabel: UILabel!
    @IBOutlet weak var placeView: UIView!
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var listenButtonView: Button!
    @IBOutlet weak var buyTicketButtonView: Button!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    func inject(input: Live) {
        self.input = input
    }
    
    func setup() {
        self.backgroundColor = style.color.background.get()
        self.liveTitleLabel.text = "hello"
    }
}

struct Live {}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct LiveCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TableCellWrapper<LiveCell>(input: Live())
        }
        .previewLayout(.fixed(width: 414, height: 400))
    }
}
#endif
