//
//  LoadingCollectionView.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/01/07.
//

import UIKit

public final class LoadingCollectionView: UIActivityIndicatorView {
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        backgroundColor = .clear
        color = Brand.color(for: .text(.primary))
    }
}

#if PREVIEW
import SwiftUI

struct LoadingCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreviewWrapper(view: LoadingCollectionView())
                .previewLayout(.fixed(width: 320, height: 500))
        }
        .background(Color.black)
    }
}
#endif
