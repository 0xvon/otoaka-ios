//
//  ViewHierarchy.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/27.
//

import UIKit

class ViewHierarchy {
    let floatingOverlayWindow: FloatingOverlayWindow
    var floatingViewController: FloatingViewController {
        floatingOverlayWindow.floatingViewController
    }

    init(windowScene: UIWindowScene) {
        floatingOverlayWindow = FloatingOverlayWindow(windowScene: windowScene)
    }
    
    func activateFloatingOverlay(isActive: Bool) {
        floatingOverlayWindow.isHidden = !isActive
    }
}
