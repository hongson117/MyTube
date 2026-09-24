//
//  CarPlayViewController.swift
//  MyTube
//

import WebKit
import SwiftUI
import UIKit

class CarPlayViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    private var webView: WKWebView!
    private var keyboardContainerView: UIView?
    private var noSleepView: WKWebView?
    private var screenOffLabel: UIView?
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // Register self as the active CarPlay view controller
        CarPlaySingleton.shared.setCPVC(controller: self)
        
        setupWebView()
        setupGestures()
        setupNoSleep()
        setupKeyboard()
        setupScreenOffLabel()
        setupSplashScreen()
        
        // Check if there is a pending cached video, otherwise load initial home/trending URL
        if let urlString = CarPlaySingleton.shared.getCachedVideo() {
            CarPlaySingleton.shared.clearCachedVideo()
            loadUrl(urlString)
        } else {
            loadUrl(MyTubeWebManager.shared.initialHomeURL)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if keyboardContainerView?.isHidden ?? true {
            webView.frame = view.bounds
        }
    }
    
    // MARK: - Setup Components
    private func setupWebView() {
        let webConfiguration = MyTubeWebManager.shared.createCarPlayConfiguration()
        webConfiguration.userContentController.add(self, name: "keyboard")
        
        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView.customUserAgent = MyTubeWebManager.shared.safariUserAgent
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
    }
    
    private func setupGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(recognizer:)))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(recognizer:)))
        swipeRight.direction = .right
        webView.addGestureRecognizer(swipeLeft)
        webView.addGestureRecognizer(swipeRight)
    }
    
    private func setupNoSleep() {
        let noSleepConfig = WKWebViewConfiguration()
        noSleepConfig.processPool = MyTubeWebManager.shared.processPool
        noSleepConfig.websiteDataStore = MyTubeWebManager.shared.dataStore
        if let scriptPath = Bundle.main.path(forResource: "NoSleepEnable", ofType: "js"),
           let scriptSource = try? String(contentsOfFile: scriptPath) {
            let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            noSleepConfig.userContentController.addUserScript(userScript)
        }
        noSleepConfig.allowsInlineMediaPlayback = true
        noSleepConfig.mediaTypesRequiringUserActionForPlayback = []
        
        let nsv = WKWebView(frame: .zero, configuration: noSleepConfig)
        nsv.load(URLRequest(url: URL(string: "about:blank")!))
        nsv.isHidden = true
        view.addSubview(nsv)
        self.noSleepView = nsv
    }
    
    private func setupKeyboard() {
        let keyboardController = UIHostingController(rootView: KeyboardView(width: view.bounds.width))
        addChild(keyboardController)
        let kbHeight = max(180.0, view.bounds.height * 0.55)
        keyboardController.view.frame = CGRect(
            x: 0,
            y: view.bounds.height - kbHeight,
            width: view.bounds.width,
            height: kbHeight
        )
        keyboardController.view.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        view.addSubview(keyboardController.view)
        keyboardController.didMove(toParent: self)
        
        self.keyboardContainerView = keyboardController.view
        self.keyboardContainerView?.isHidden = true
    }
    
    private func setupScreenOffLabel() {
        let offView = UIView(frame: view.bounds)
        offView.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        offView.isUserInteractionEnabled = false
        offView.alpha = 0
        offView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(offView)
        
        let label = UILabel(frame: offView.bounds)
        label.text = "Chạm vào màn hình điện thoại để tiếp tục My Tube"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        offView.addSubview(label)
        
        self.screenOffLabel = offView
    }
    
    private func setupSplashScreen() {
        let splashController = UIHostingController(rootView: SplashScreen())
        addChild(splashController)
        splashController.view.frame = view.bounds
        splashController.view.isUserInteractionEnabled = false
        splashController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(splashController.view)
        splashController.didMove(toParent: self)
        
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { _ in
            UIView.animate(withDuration: 0.6, animations: {
                splashController.view.alpha = 0
            }, completion: { _ in
                splashController.view.removeFromSuperview()
                splashController.removeFromParent()
            })
        }
    }
    
    // MARK: - Navigation & Actions
    @objc private func handleSwipe(recognizer: UISwipeGestureRecognizer) {
        if recognizer.direction == .left {
            if webView.canGoForward { webView.goForward() }
        } else if recognizer.direction == .right {
            if webView.canGoBack { webView.goBack() }
        }
    }
    
    func goHome() {
        loadUrl(MyTubeWebManager.shared.initialHomeURL)
    }
    
    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func loadUrl(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.setValue("https://m.youtube.com", forHTTPHeaderField: "Referer")
        webView.load(request)
    }
    
    // MARK: - Text & Keyboard Inputs
    func sendInput(_ input: String) {
        let escaped = input
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        let js = """
        (function() {
            const el = document.activeElement;
            if (el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
                const start = el.selectionStart || el.value.length;
                const end = el.selectionEnd || el.value.length;
                el.value = el.value.substring(0, start) + '\(escaped)' + el.value.substring(end);
                el.selectionStart = el.selectionEnd = start + \(escaped.count);
                el.dispatchEvent(new Event('input', { bubbles: true }));
            }
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    func backspaceInput() {
        let js = """
        (function() {
            const el = document.activeElement;
            if (el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
                const start = el.selectionStart || el.value.length;
                const end = el.selectionEnd || el.value.length;
                if (start === end && start > 0) {
                    el.value = el.value.substring(0, start - 1) + el.value.substring(end);
                    el.selectionStart = el.selectionEnd = start - 1;
                } else if (start !== end) {
                    el.value = el.value.substring(0, start) + el.value.substring(end);
                    el.selectionStart = el.selectionEnd = start;
                }
                el.dispatchEvent(new Event('input', { bubbles: true }));
            }
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    func toggleKeyboard() {
        guard let kb = keyboardContainerView else { return }
        let shouldShow = kb.isHidden
        if shouldShow {
            kb.isHidden = false
            let kbHeight = kb.bounds.height
            webView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - kbHeight)
        } else {
            kb.isHidden = true
            webView.frame = view.bounds
        }
    }
    
    // MARK: - Script Message Handler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "keyboard" {
            guard let kb = keyboardContainerView else { return }
            if message.body as? String == "hide" {
                kb.isHidden = true
                webView.frame = view.bounds
            } else if message.body as? String == "show" {
                kb.isHidden = false
                let kbHeight = kb.bounds.height
                webView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - kbHeight)
            }
        }
    }
    
    // MARK: - Persistence & Sleep Helpers
    func disablePersistence() {
        timer?.invalidate()
        timer = nil
        noSleepView?.evaluateJavaScript("if (window.noSleep) { noSleep.disable(); }")
    }
    
    func enablePersistence() {
        noSleepView?.evaluateJavaScript("if (window.noSleep) { noSleep.enable(); }")
    }
    
    func showWarningLabel() {
        guard let label = screenOffLabel else { return }
        label.alpha = 1.0
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            UIView.animate(withDuration: 1.0) {
                label.alpha = 0
            }
        }
    }
    
    // MARK: - WKNavigationDelegate & WKUIDelegate
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            if let targetUrl = navigationAction.request.url?.absoluteString {
                loadUrl(targetUrl)
            }
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MyTubeWebManager.shared.checkLoginStatus()
    }
}
