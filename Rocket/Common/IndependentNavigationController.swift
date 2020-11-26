//
//  IndependentNavigationController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/26.
//

import UIKit

class IndependentNavigationController: UINavigationController {
    override func viewWillDisappear(_ animated: Bool) {
        if isBeingDismissed {
            self.listener()
        }
    }
    
    private var listener: () -> Void = {}
    func dismiss(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}
