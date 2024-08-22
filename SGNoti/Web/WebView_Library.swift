//
//  WebView_Library.swift
//  SGNoti
//
//  Created by InHeritas on 8/13/24.
//

import SwiftUI
import WebKit
import SafariServices

struct WebView_Library: UIViewRepresentable {
    let url: URL
    @Binding var contentHeight: CGFloat
    @Binding var isPageLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
    
    func replaceContent(_ webView: WKWebView) {
        let jsCode = """
        try {
            const contentElement = document.querySelector("#divContent > div > div:nth-child(1) > div.boardContent");
            if (contentElement) {
                document.body.innerHTML = contentElement.outerHTML;
                document.querySelector("body > div").style.border = 0;
                document.querySelector("body > div").style.padding = 0;
                document.querySelectorAll('body > div img, body > div table').forEach(function(element) {
                    element.style.width = 'auto';
                });
                true;
            } else {
                console.error('JavaScript error: contentElement not found');
                false;
            }
        } catch (e) {
            console.error('JavaScript error: ' + e);
            false;
        }
        """
        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("JavaScript error: \(error.localizedDescription)")
            } else {
                if let success = result as? Bool, success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let height = webView.scrollView.contentSize.height
                        self.contentHeight = height
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.isPageLoading = false
                        }
                    }
                } else {
                    print("JavaScript: Content replacement failed or other error occurred")
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView_Library
        var isWebViewLoaded = false
        
        init(_ parent: WebView_Library) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isWebViewLoaded = true
            parent.replaceContent(webView)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                decisionHandler(.cancel)
                openInSafariViewController(url)
            } else {
                decisionHandler(.allow)
            }
        }
        
        private func openInSafariViewController(_ url: URL) {
            guard let windowScene = UIApplication.shared
                .connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .first as? UIWindowScene else {
                return
            }
            
            guard let rootViewController = windowScene.windows
                .filter({ $0.isKeyWindow }).first?.rootViewController else {
                return
            }
            
            let safariViewController = SFSafariViewController(url: url)
            rootViewController.present(safariViewController, animated: true, completion: nil)
        }
    }
}
