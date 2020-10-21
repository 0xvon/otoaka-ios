//
//  LiveViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import UIKit

final class LiveViewController: UIViewController, Instantiable {
    
    typealias Input = Void
    var dependencyProvider: DependencyProvider!
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct LiveViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerWrapper<LiveViewController>(
            dependencyProvider: .make(),
            input: ()
        )
    }
}

#endif
