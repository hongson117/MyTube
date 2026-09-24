//
//  MyTubeApp.swift
//  MyTube
//

import SwiftUI
import AVFoundation

@main
struct MyTubeApp: App {
    init() {
        registerDefaults()
        configureAudioSession()
        
        if UserDefaults.standard.bool(forKey: "LockScreenDimmingOn") {
            CarPlaySingleton.shared.saveInitialBrightness()
            registerForScreenOffNotification {
                CarPlaySingleton.shared.showScreenOffWarning()
                CarPlaySingleton.shared.setLowBrightness()
            }
            registerForUnlockNotification {
                CarPlaySingleton.shared.restoreBrightness()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "AdBlockerOn": true,
            "SponsorBlockOn": true,
            "AgeRestrictBypassOn": true,
            "Zoom": 80,
            "ScreenPersistenceOn": true,
            "LockScreenDimmingOn": true
        ])
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession configuration error: \(error)")
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        let raw = url.absoluteString
        var videoID: String?
        
        if raw.starts(with: "mytube://") || raw.starts(with: "cartube://") {
            let stripped = raw
                .replacingOccurrences(of: "^(mytube|cartube)://", with: "", options: .regularExpression)
            if stripped.count == 11 {
                videoID = stripped
            } else if let id = extractYouTubeVideoID(stripped) {
                videoID = id
            }
        } else if let id = extractYouTubeVideoID(raw) {
            videoID = id
        }
        
        if let id = videoID {
            let ytURL = YT_EMBED + id
            CarPlaySingleton.shared.loadUrl(ytURL)
        } else {
            UIApplication.shared.alert(
                title: "Lỗi Đường Dẫn",
                body: "Không tìm thấy mã video YouTube từ liên kết: \(url.absoluteString)",
                window: .main
            )
        }
    }
}
