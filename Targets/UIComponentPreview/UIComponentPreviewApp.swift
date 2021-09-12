//
//  UIComponentPreviewApp.swift
//  UIComponentPreview
//
//  Created by kateinoigakukun on 2020/12/29.
//

import SwiftUI
import StubKit

@main
struct UIComponentPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            PreviewWrapper(
                view: {
                    let wrapper = UIView()
                    wrapper.backgroundColor = .black
                    let contentView = try! BandDetailHeaderView(input: (group: Stub.make {
                        $0.set(\.name, value: "Band Name")
                        $0.set(\.biography, value: "Band Biography")
                        $0.set(\.hometown, value: "Band Hometown")
                        $0.set(\.since, value: Date())
                    }, groupItem: nil))
                    contentView.translatesAutoresizingMaskIntoConstraints = false
                    wrapper.addSubview(contentView)
                    let constraints = [
                        wrapper.topAnchor.constraint(equalTo: contentView.topAnchor),
                        wrapper.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor),
                        wrapper.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                        wrapper.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                        contentView.heightAnchor.constraint(equalToConstant: 250),
                    ]
                    NSLayoutConstraint.activate(constraints)
                    return wrapper
                }()
            )
        }
    }
}

extension UUID: Stubbable {
    public static func stub() -> UUID {
        UUID()
    }
}
