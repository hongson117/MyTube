//
//  CarPlaySingleton.swift
//  MyTube
//

import UIKit
import AVFoundation

class CarPlaySingleton: ObservableObject {
    static let shared = CarPlaySingleton()
    
    private var controller: CarPlayViewController?
    private var cachedVideo: String?
    private var initialBrightness: Float?
    private var initialAutoBrightness: Bool?
    
    @Published var isCPWindowActive: Bool = false
    @Published var isConnectedToCar: Bool = false
    
    /// Load a YouTube URL string into the CarPlay player
    func loadUrl(_ urlString: String) {
        if let cpVC = controller, isCPWindowActive {
            cpVC.loadUrl(urlString)
        } else {
            // Cache video to auto-play when CarPlay screen attaches
            self.cachedVideo = urlString
            UIApplication.shared.alert(
                title: "Đã Lưu Video",
                body: "Video đã được xếp hàng. Khi cắm vào CarPlay, video sẽ tự động phát toàn màn hình trên xe!",
                window: .main
            )
        }
    }
    
    /// Search for a YouTube video in the player
    func searchVideo(_ search: String) {
        let searchString = YT_SEARCH + search
        guard let safeSearch = searchString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        loadUrl(safeSearch)
    }
    
    func setCPWindowActive(_ active: Bool) {
        DispatchQueue.main.async {
            self.isCPWindowActive = active
            self.isConnectedToCar = active && (self.controller != nil)
        }
    }
    
    func saveInitialBrightness() {
        initialBrightness = getSettingsBrightness()
        initialAutoBrightness = isAutoBrightnessEnabled()
    }
    
    func setLowBrightness() {
        if UserDefaults.standard.bool(forKey: "LockScreenDimmingOn"), isCPWindowActive {
            if isAutoBrightnessEnabled() {
                setAutoBrightness(false)
            }
            setScreenBrightness(0.0001)
        }
    }
    
    func restoreBrightness() {
        if UserDefaults.standard.bool(forKey: "LockScreenDimmingOn"), isCPWindowActive {
            if initialAutoBrightness ?? false && !isAutoBrightnessEnabled() {
                setAutoBrightness(true)
            }
            setScreenBrightness(initialBrightness ?? 0.5)
        }
    }
    
    func disablePersistence() {
        if UserDefaults.standard.bool(forKey: "ScreenPersistenceOn") {
            self.controller?.disablePersistence()
        }
    }
    
    func enablePersistence() {
        if UserDefaults.standard.bool(forKey: "ScreenPersistenceOn") {
            self.controller?.enablePersistence()
        }
    }
    
    func showScreenOffWarning() {
        self.controller?.showWarningLabel()
    }
    
    /// Send keyboard input to the web view
    func sendInput(_ input: String) {
        controller?.sendInput(input)
    }
    
    /// Send a backspace to the web view
    func backspaceInput() {
        controller?.backspaceInput()
    }
    
    /// Go back to the homepage on the web view
    func goHome() {
        controller?.goHome()
    }
    
    func goBack() {
        controller?.goBack()
    }
    
    /// Toggle the web view keyboard
    func toggleKeyboard() {
        controller?.toggleKeyboard()
    }
    
    func getCachedVideo() -> String? {
        return cachedVideo
    }
    
    func clearCachedVideo() {
        cachedVideo = nil
    }
    
    func setCPVC(controller: CarPlayViewController) {
        self.controller = controller
        DispatchQueue.main.async {
            self.isConnectedToCar = self.isCPWindowActive
        }
    }
    
    func getCPVC() -> CarPlayViewController? {
        return self.controller
    }
    
    func removeCPVC() {
        self.controller = nil
        DispatchQueue.main.async {
            self.isConnectedToCar = false
        }
    }
}
