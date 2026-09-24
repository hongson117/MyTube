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
        
        if let url = URL(string: currentURL) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // If currentURL changed externally and differs from webview URL, load it
        if let target = URL(string: currentURL), uiView.url?.absoluteString != currentURL, !context.coordinator.isInternalNavigation {
            uiView.load(URLRequest(url: target))
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: PhoneWebViewRepresentable
        weak var webView: WKWebView?
        var isInternalNavigation: Bool = false
        
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
                    self.isInternalNavigation = true
                    self.parent.currentURL = urlStr
                    self.parent.onNavigation?(urlStr)
                    self.isInternalNavigation = false
                }
                MyTubeWebManager.shared.checkLoginStatus()
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
