//
//  WebView.swift
//  Noti Sogang
//
//  Created by InHeritas on 8/8/24.
//

import SwiftUI
import WebKit
import SafariServices

struct WebView: UIViewRepresentable {
    let url: URL
    let content: String
    @Binding var contentHeight: CGFloat
    @Binding var isPageLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if !context.coordinator.isWebViewLoaded {
            let request = URLRequest(url: url)
            uiView.load(request)
        } else {
            replaceContent(uiView)
        }
    }
    
    func replaceContent(_ webView: WKWebView) {
        let noticeBody = content
        let jsCode = """
        try {
            document.body.innerHTML = `<p style=\"min-height: 1px;\"></p>\(noticeBody)`;
            var iframe = document.querySelector('iframe');
            if (iframe) {
                var iframeSrc = iframe.src;
                var link = document.createElement('a');
                link.href = iframeSrc;
                link.textContent = "🔗 본문 PDF 내용 보기";
                link.target = "_blank";
                link.style.textDecoration = "underline";
                var wrapperDiv = document.createElement('div');
                wrapperDiv.style.textAlign = "center";
                wrapperDiv.appendChild(link);
                iframe.parentNode.replaceChild(wrapperDiv, iframe);
            }
            true;
        } catch (e) {
            console.error('JavaScript error: ' + e);
            false;
        }
        """
        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("JavaScript error: \(error.localizedDescription)")
            } else if let success = result as? Bool, success {
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var isWebViewLoaded = false
        
        init(_ parent: WebView) {
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
