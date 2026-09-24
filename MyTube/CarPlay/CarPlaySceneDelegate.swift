//
//  CarPlaySceneDelegate.swift
//  MyTube
//

import UIKit

class CarPlaySceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var viewController: CarPlayViewController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let win = UIWindow(windowScene: windowScene)
        self.window = win
        let vc = CarPlayViewController()
        self.viewController = vc
        win.rootViewController = vc
        win.makeKeyAndVisible()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        CarPlaySingleton.shared.setCPWindowActive(true)
        CarPlaySingleton.shared.enablePersistence()
        if isScreenLocked() {
            if getScreenBrightness() == 0 {
                CarPlaySingleton.shared.showScreenOffWarning()
            }
            CarPlaySingleton.shared.setLowBrightness()
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        if isScreenLocked() {
            CarPlaySingleton.shared.restoreBrightness()
        }
        CarPlaySingleton.shared.disablePersistence()
        CarPlaySingleton.shared.setCPWindowActive(false)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        CarPlaySingleton.shared.setCPWindowActive(false)
        CarPlaySingleton.shared.removeCPVC()
        self.viewController = nil
        self.window = nil
    }
}
