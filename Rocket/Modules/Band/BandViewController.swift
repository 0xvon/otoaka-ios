//
//  BandViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import Foundation
import UIKit

final class BandViewController: UIViewController, Instantiable {
    
    typealias Input = Void
    var dependencyProvider: DependencyProvider!
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct BandViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerWrapper<BandViewController>(
            dependencyProvider: .make(),
            input: ()
        )
    }
}

#endif

