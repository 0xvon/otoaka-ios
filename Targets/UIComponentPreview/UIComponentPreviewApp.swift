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
            ViewWrapper(
                view: try! BandDetailHeaderView(input: (group: Stub.make(), groupItem: nil))
            )
            .frame(height: 150)
        }
    }
}

extension UUID: Stubbable {
    public static func stub() -> UUID {
        UUID()
    }
}
