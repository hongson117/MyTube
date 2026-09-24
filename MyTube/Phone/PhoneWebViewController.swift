//
//  PhoneWebViewController.swift
//  MyTube
//

import SwiftUI
import WebKit

struct PhoneWebViewRepresentable: UIViewRepresentable {
    @Binding var currentURL: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    
    var onNavigation: ((String) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = MyTubeWebManager.shared.createPhoneConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = MyTubeWebManager.shared.safariUserAgent
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        context.coordinator.webView = webView
        context.coordinator.lastLoadedURL = currentURL
        
        if let url = URL(string: currentURL) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only load if currentURL was updated from SwiftUI and differs from what was last loaded
        if let target = URL(string: currentURL), currentURL != context.coordinator.lastLoadedURL {
            context.coordinator.lastLoadedURL = currentURL
            uiView.load(URLRequest(url: target))
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: PhoneWebViewRepresentable
        weak var webView: WKWebView?
        var lastLoadedURL: String?
        
        init(_ parent: PhoneWebViewRepresentable) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                if let urlStr = webView.url?.absoluteString {
                    self.lastLoadedURL = urlStr
                    if self.parent.currentURL != urlStr {
                        self.parent.currentURL = urlStr
                    }
                    self.parent.onNavigation?(urlStr)
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
