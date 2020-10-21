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
    @IBOutlet weak var sampleButtonView: Button!
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewdidload")
        setup()
    }
    
    func setup() {
        self.view.backgroundColor = style.color.background.get()
        self.view.tintColor = style.color.main.get()
        let buttonView = Button(input: .buyTicket)
        buttonView.button.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
        self.sampleButtonView.addSubview(buttonView)
    }
    
    @objc func tappedButton(sender: UIButton!) {
        let vc = BandViewController(dependencyProvider: dependencyProvider, input: ())
        self.navigationController?.pushViewController(vc, animated: true)
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
