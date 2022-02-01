//
//  LiveCollectionView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/01.
//

import UIKit
import ImagePipeline
import Endpoint

public final class LiveCollectionView: UICollectionView {
    public var lives: [LiveFeed] = []
    public var imagePipeline: ImagePipeline
//    public enum Output {
//        case liveTapped(LiveFeed)
//        case likeTapped(LiveFeed)
//        case buyTicketTapped(LiveFeed)
//        case numOfLikeTapped(LiveFeed)
//        case reportTapped(LiveFeed)
//        case numOfReportTapped(LiveFeed)
//    }
    
    public init(lives: [LiveFeed], imagePipeline: ImagePipeline) {
        self.lives = lives
        self.imagePipeline = imagePipeline
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
        
        super.init(frame: .zero, collectionViewLayout: layout)
        setup()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func inject(lives: [LiveFeed]) {
        self.lives = lives
        reloadData()
    }
    
    func setup() {
        backgroundColor = .clear
        
        registerCellClass(LiveCollectionCell.self)
        delegate = self
        dataSource = self
        isPagingEnabled = false
        showsHorizontalScrollIndicator = false
    }
    private var listener: (LiveCellContent.Output, LiveFeed) -> Void = { _, _ in }
    public func listen(_ listener: @escaping (LiveCellContent.Output, LiveFeed) -> Void) {
        self.listener = listener
    }
}

extension LiveCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.lives.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var live = self.lives[indexPath.item]
        let cell = collectionView.dequeueReusableCell(LiveCollectionCell.self, input: (live: live, imagePipeline: imagePipeline, type: .normal), for: indexPath)
        cell.listen { [unowned self] output in
            self.listener(output, live)
            if output == .likeButtonTapped {
                live.isLiked.toggle()
            }
//            switch output {
//            case .selfTapped:
//                listener(.liveTapped(live))
//            case .likeButtonTapped:
//                listener(.likeTapped(live))
//                live.isLiked.toggle()
//            case .reportButtonTapped:
//                listener(.reportTapped(live))
//            case .numOfLikeTapped:
//                listener(.numOfLikeTapped(live))
//            case .numOfReportTapped:
//                listener(.numOfReportTapped(live))
//            case .buyTicketButtonTapped:
//                listener(.buyTicketTapped(live))
//            }
        }
        return cell
    }
}

extension LiveCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width - 40, height: 300)
    }
}
