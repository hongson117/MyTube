//
//  PhoneSceneDelegate.swift
//  MyTube
//

import UIKit
import SwiftUI

class PhoneSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let win = UIWindow(windowScene: windowScene)
        self.window = win
        let contentView = ContentView()
        win.rootViewController = UIHostingController(rootView: contentView)
        win.makeKeyAndVisible()
    }
}
