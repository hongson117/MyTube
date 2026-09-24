//
//  MyTubeWebManager.swift
//  MyTube
//

import Foundation
import WebKit

class MyTubeWebManager: ObservableObject {
    static let shared = MyTubeWebManager()
    
    // Shared process pool ensures cookie & session cache is shared across instances
    let processPool = WKProcessPool()
    
    // Shared persistent data store keeps Google sign-in cookies across restarts & scenes
    let dataStore = WKWebsiteDataStore.default()
    
    // Genuine Safari Mobile User-Agent ensures Google Sign-In is NEVER blocked
    let safariUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
    
    @Published var isLoggedIn: Bool = false
    
    init() {
        checkLoginStatus()
    }
    
    /// Default starting URL: If not logged in, starts with Trending to prevent empty home feed
    var initialHomeURL: String {
        return isLoggedIn ? "https://m.youtube.com/" : "https://m.youtube.com/feed/trending"
    }
    
    func createPhoneConfiguration() -> WKWebViewConfiguration {
        return createBaseConfiguration(extraScripts: [])
    }
    
    func createCarPlayConfiguration() -> WKWebViewConfiguration {
        return createBaseConfiguration(extraScripts: ["CarPlayLayout"])
    }
    
    private func createBaseConfiguration(extraScripts: [String]) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.processPool = self.processPool
        config.websiteDataStore = self.dataStore
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        
        let sponsorBlockOn = UserDefaults.standard.object(forKey: "SponsorBlockOn") == nil ? true : UserDefaults.standard.bool(forKey: "SponsorBlockOn")
        let adBlockerOn = UserDefaults.standard.object(forKey: "AdBlockerOn") == nil ? true : UserDefaults.standard.bool(forKey: "AdBlockerOn")
        let ageRestrictBypassOn = UserDefaults.standard.bool(forKey: "AgeRestrictBypassOn")
        
        var activeScripts: [String] = []
        if sponsorBlockOn { activeScripts.append("SponsorBlock") }
        if ageRestrictBypassOn { activeScripts.append("AgeRestrictBypass") }
        if adBlockerOn { activeScripts.append("AdBlocker") }
        activeScripts.append("CustomLayout")
        activeScripts.append(contentsOf: extraScripts)
        
        for scriptName in activeScripts {
            if let scriptPath = Bundle.main.path(forResource: scriptName, ofType: "js"),
               let scriptSource = try? String(contentsOfFile: scriptPath) {
                let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                config.userContentController.addUserScript(userScript)
            }
        }
        
        // Custom Zoom (Default 100% for crisp display)
        let zoomVal = UserDefaults.standard.integer(forKey: "Zoom") == 0 ? 100 : UserDefaults.standard.integer(forKey: "Zoom")
        let zoomScale = Double(zoomVal) / 100.0
        let zoomScript = """
        let meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'initial-scale=\(zoomScale), maximum-scale=\(zoomScale), user-scalable=yes';
        document.head.appendChild(meta);
        let css = document.createElement('style');
        css.type = 'text/css';
        css.innerHTML = '.open-app-button { display: none !important; }';
        document.head.appendChild(css);
        """
        config.userContentController.addUserScript(
            WKUserScript(source: zoomScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )
        
        return config
    }
    
    /// Check if Google / YouTube authentication cookies exist
    func checkLoginStatus(completion: ((Bool) -> Void)? = nil) {
        dataStore.httpCookieStore.getAllCookies { cookies in
            let hasAuth = cookies.contains { cookie in
                (cookie.domain.contains("youtube.com") || cookie.domain.contains("google.com")) &&
                (cookie.name == "LOGIN_INFO" || cookie.name == "SAPISID" || cookie.name == "SSID" || cookie.name == "SID")
            }
            DispatchQueue.main.async {
                self.isLoggedIn = hasAuth
                completion?(hasAuth)
            }
        }
    }
    
    /// Clear login data to switch accounts
    func logout(completion: @escaping () -> Void) {
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            let googleRecords = records.filter {
                $0.displayName.contains("google") || $0.displayName.contains("youtube")
            }
            self.dataStore.removeData(ofTypes: dataTypes, for: googleRecords) {
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                    completion()
                }
            }
        }
    }
}
