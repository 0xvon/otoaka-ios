//
//  UserStoryCarouselView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/01.
//

import UIKit
import ImagePipeline
import Endpoint

public final class UserStoryCollectionView: UICollectionView {
    public var users: [User] =  []
    public var imagePipeline: ImagePipeline
    
    public init(users: [User], imagePipeline: ImagePipeline) {
        self.users = users
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
    
    public func inject(users: [User]) {
        self.users = users
        reloadData()
        setCollectionViewBackgroundView(isDisplay: users.isEmpty)
    }
    
    func setup() {
        backgroundColor = .clear
        
        registerCellClass(UserCaroucel.self)
        delegate = self
        dataSource = self
        isPagingEnabled = false
        showsHorizontalScrollIndicator = false
    }
    
    private var listener: (User) -> Void = { _ in }
    public func listen(_ listener: @escaping (User) -> Void) {
        self.listener = listener
    }
}

extension UserStoryCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.users.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(UserCaroucel.self, input: (user: self.users[indexPath.item], imagePipeline: imagePipeline), for: indexPath)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.listener(users[indexPath.item])
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func setCollectionViewBackgroundView(isDisplay: Bool = false) {
        let emptyCollectionView: EmptyCollectionView = {
            let emptyCollectionView = EmptyCollectionView(emptyType: .friend, actionButtonTitle: nil)
            emptyCollectionView.translatesAutoresizingMaskIntoConstraints = false
            return emptyCollectionView
        }()
        self.backgroundView = isDisplay ? emptyCollectionView : nil
        if let backgroundView = self.backgroundView {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: topAnchor),
                backgroundView.widthAnchor.constraint(equalTo: widthAnchor),
            ])
        }
    }
}

extension UserStoryCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 50, height: 50)
    }
}
