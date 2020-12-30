//
//  RefreshControl.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/31.
//

import UIKit

public final class RefreshControl: UIRefreshControl {
    public override init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        tintColor = Brand.color(for: .background(.secondary))
    }
}
