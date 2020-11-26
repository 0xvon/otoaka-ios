//
//  IndependentNavigationController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/26.
//

import UIKit

class ModalNavigationController: UINavigationController {
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if isBeingDismissed {
            self.listener()
        }
    }
    
    private var listener: () -> Void = {}
    func subscribeDismission(_ listener: @escaping () -> Void) {
        self.listener = listener
    }
}
