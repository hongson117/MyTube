//
//  Utilities.swift
//  MyTube
//

import Foundation
import UIKit
import notify

/// Check if the given string is a valid YouTube URL
func isYouTubeURL(_ url: String) -> Bool {
    return extractYouTubeVideoID(url) != nil
}

/// Given a URL string, extract the 11-character YouTube video ID
func extractYouTubeVideoID(_ url: String) -> String? {
    let pattern = "(?:youtube(?:-nocookie)?\\.com\\/(?:[^\\/\\n\\s]+\\/\\S+\\/|(?:v|e(?:mbed)?)\\/|\\S*?[?&]v=)|youtu\\.be\\/)([a-zA-Z0-9_-]{11})"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
    guard let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) else { return nil }
    guard let range = Range(match.range(at: 1), in: url) else { return nil }
    return String(url[range])
}

/// Minimise the app and close it cleanly
func exitGracefully() {
    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
        exit(0)
    }
}

/// Register a specified function to be run when the screen turns off
func registerForScreenOffNotification(callback: @escaping () -> Void) {
    var notify_token: Int32 = 0
    notify_register_dispatch("com.apple.springboard.hasBlankedScreen", &notify_token, DispatchQueue.main) { token in
        var state: Int64 = 0
        notify_get_state(token, &state)
        let screenOff = state == 1
        if screenOff {
            callback()
        }
    }
}

/// Register a specified function to be run when the screen unlocks
func registerForUnlockNotification(callback: @escaping () -> Void) {
    var notify_token: Int32 = 0
    notify_register_dispatch("com.apple.springboard.lockstate", &notify_token, DispatchQueue.main) { token in
        var state: Int64 = 0
        notify_get_state(token, &state)
        let deviceUnlocked = state == 0
        if deviceUnlocked {
            callback()
        }
    }
}

/// Check if the screen is currently locked
func isScreenLocked() -> Bool {
    guard let sbs = dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_LAZY) else { return false }
    defer { dlclose(sbs) }

    guard let s1 = dlsym(sbs, "SBSSpringBoardServerPort") else { return false }
    let SBSSpringBoardServerPort = unsafeBitCast(s1, to: (@convention(c) () -> mach_port_t).self)

    guard let s2 = dlsym(sbs, "SBGetScreenLockStatus") else { return false }
    var lockStatus: ObjCBool = false
    var passcodeEnabled: ObjCBool = false
    let SBGetScreenLockStatus = unsafeBitCast(s2, to: (@convention(c) (mach_port_t, UnsafeMutablePointer<ObjCBool>, UnsafeMutablePointer<ObjCBool>) -> Void).self)
    SBGetScreenLockStatus(SBSSpringBoardServerPort(), &lockStatus, &passcodeEnabled)
    return lockStatus.boolValue
}

/// Get the current display brightness, is 0 if off
func getScreenBrightness() -> Float {
    guard let bbs = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY) else { return Float(UIScreen.main.brightness) }
    defer { dlclose(bbs) }
    
    guard let s = dlsym(bbs, "BKSDisplayBrightnessGetCurrent") else { return Float(UIScreen.main.brightness) }
    let BKSDisplayBrightnessGetCurrent = unsafeBitCast(s, to: (@convention(c) () -> Float).self)
    return BKSDisplayBrightnessGetCurrent()
}

/// Set the current display brightness
func setScreenBrightness(_ brightness: Float) {
    guard brightness >= 0, brightness <= 1 else { return }
    guard let bbs = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY) else {
        UIScreen.main.brightness = CGFloat(brightness)
        return
    }
    defer { dlclose(bbs) }
    
    guard let s = dlsym(bbs, "BKSDisplayBrightnessSet") else {
        UIScreen.main.brightness = CGFloat(brightness)
        return
    }
    let BKSDisplayBrightnessSet = unsafeBitCast(s, to: (@convention(c) (Float, NSInteger) -> Void).self)
    BKSDisplayBrightnessSet(brightness, 1)
}

/// Check if auto-brightness is enabled
func isAutoBrightnessEnabled() -> Bool {
    let autoBrightnessKey = "BKEnableALS" as CFString
    let backboardd = "com.apple.backboardd" as CFString
    var keyExists: DarwinBoolean = false
    let enabled = CFPreferencesGetAppBooleanValue(autoBrightnessKey, backboardd, &keyExists)
    if keyExists.boolValue {
        return enabled
    }
    return true
}

/// Retrieve brightness from settings
func getSettingsBrightness() -> Float {
    let brightnessKey1 = "SBBacklightLevel" as CFString
    let brightnessKey2 = "SBBacklightLevel2" as CFString
    let springboard = "com.apple.springboard" as CFString
    if let brightness1 = CFPreferencesCopyAppValue(brightnessKey1, springboard) as? Float {
        return brightness1
    } else if let brightness2 = CFPreferencesCopyAppValue(brightnessKey2, springboard) as? Float {
        return brightness2
    }
    return 0.5
}

/// Enable or disable auto-brightness
func setAutoBrightness(_ on: Bool) {
    guard let bbs = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY) else { return }
    defer { dlclose(bbs) }
    
    guard let s = dlsym(bbs, "BKSDisplayBrightnessSetAutoBrightnessEnabled") else { return }
    let BKSDisplayBrightnessSetAutoBrightnessEnabled = unsafeBitCast(s, to: (@convention(c) (ObjCBool) -> Void).self)
    BKSDisplayBrightnessSetAutoBrightnessEnabled(ObjCBool(on))
}

// MARK: - Alert Helpers
enum AlertTargetWindow {
    case main
    case carPlay
}

extension UIApplication {
    func alert(title: String = "My Tube", body: String, window: AlertTargetWindow = .main) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            if window == .carPlay, let cpVC = CarPlaySingleton.shared.getCPVC() {
                cpVC.present(alertController, animated: true, completion: nil)
            } else if let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController {
                rootVC.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func confirmAlert(title: String, body: String, okTitle: String = "OK", cancelTitle: String = "Cancel", onOK: @escaping () -> Void, noCancel: Bool = false, window: AlertTargetWindow = .main) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: okTitle, style: .default) { _ in
                onOK()
            })
            if !noCancel {
                alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))
            }
            
            if window == .carPlay, let cpVC = CarPlaySingleton.shared.getCPVC() {
                cpVC.present(alertController, animated: true, completion: nil)
            } else if let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController {
                rootVC.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
