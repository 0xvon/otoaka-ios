//
//  LiveCardCollectionView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/10/18.
//

import UIKit
import ImagePipeline
import DomainEntity

public final class LiveCardCollectionView: UICollectionView {
    public var lives: [Live] =  []
    public var imagePipeline: ImagePipeline
    
    public init(lives: [Live], imagePipeline: ImagePipeline) {
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
    
    public func inject(lives: [Live]) {
        self.lives = lives
        reloadData()
    }
    
    func setup() {
        backgroundColor = .clear
        
        registerCellClass(LiveCardCell.self)
        delegate = self
        dataSource = self
        isPagingEnabled = false
        showsHorizontalScrollIndicator = false
    }
    
    private var listener: (Live) -> Void = { _ in }
    public func listen(_ listener: @escaping (Live) -> Void) {
        self.listener = listener
    }
}

extension LiveCardCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.lives.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(LiveCardCell.self, input: (live: self.lives[indexPath.item], imagePipeline: imagePipeline), for: indexPath)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.listener(lives[indexPath.item])
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension LiveCardCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 90, height: 160)
    }
}
