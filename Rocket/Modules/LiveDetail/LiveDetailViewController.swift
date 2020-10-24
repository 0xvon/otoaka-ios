//
//  LiveDetailViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/24.
//

import UIKit

final class LiveDetailViewController: UIViewController, Instantiable {
    
    typealias Input = Live
    
    var dependencyProvider: DependencyProvider!
    var input: Input
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.input = input
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct LiveDetailViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerWrapper<LiveDetailViewController>(
            dependencyProvider: .make(),
            input: Live(id: "123", title: "BANGOHAN TOUR 2020", type: .battles, host_id: "12345", open_at: "明日", start_at: "12時", end_at: "14時")
        )
    }
}

#endif

