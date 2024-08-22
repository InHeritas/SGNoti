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
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {

    }
    
    func replaceContent(_ webView: WKWebView) {
        let noticeBody = content
        let jsCode = """
        try {
            document.body.innerHTML = `<p style=\"min-height: 1px;\"></p>\(noticeBody)`;
        
            const targetIframes = document.querySelectorAll('iframe[src*="https://scc.sogang.ac.kr/pdfviewer"]');
            targetIframes.forEach(targetIframe => {
                const replacementLink = document.createElement('a');
                replacementLink.className = 'rounded-rectangle';
                replacementLink.href = targetIframe.src;
                replacementLink.target = "_blank";
                replacementLink.style.display = "flex";
                replacementLink.style.alignItems = "center";
                
                const svg = `
                    <svg class="pdf" xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                        class="bi bi-file-earmark-pdf" viewBox="0 0 16 16">
                        <path
                            d="M14 14V4.5L9.5 0H4a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2M9.5 3A1.5 1.5 0 0 0 11 4.5h2V14a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1h5.5z" />
                        <path
                            d="M4.603 14.087a.8.8 0 0 1-.438-.42c-.195-.388-.13-.776.08-1.102.198-.307.526-.568.897-.787a7.7 7.7 0 0 1 1.482-.645 20 20 0 0 0 1.062-2.227 7.3 7.3 0 0 1-.43-1.295c-.086-.4-.119-.796-.046-1.136.075-.354.274-.672.65-.823.192-.077.4-.12.602-.077a.7.7 0 0 1 .477.365c.088.164.12.356.127.538.007.188-.012.396-.047.614-.084.51-.27 1.134-.52 1.794a11 11 0 0 0 .98 1.686 5.8 5.8 0 0 1 1.334.05c.364.066.734.195.96.465.12.144.193.32.2.518.007.192-.047.382-.138.563a1.04 1.04 0 0 1-.354.416.86.86 0 0 1-.51.138c-.331-.014-.654-.196-.933-.417a5.7 5.7 0 0 1-.911-.95 11.7 11.7 0 0 0-1.997.406 11.3 11.3 0 0 1-1.02 1.51c-.292.35-.609.656-.927.787a.8.8 0 0 1-.58.029m1.379-1.901q-.25.115-.459.238c-.328.194-.541.383-.647.547-.094.145-.096.25-.04.361q.016.032.026.044l.035-.012c.137-.056.355-.235.635-.572a8 8 0 0 0 .45-.606m1.64-1.33a13 13 0 0 1 1.01-.193 12 12 0 0 1-.51-.858 21 21 0 0 1-.5 1.05zm2.446.45q.226.245.435.41c.24.19.407.253.498.256a.1.1 0 0 0 .07-.015.3.3 0 0 0 .094-.125.44.44 0 0 0 .059-.2.1.1 0 0 0-.026-.063c-.052-.062-.2-.152-.518-.209a4 4 0 0 0-.612-.053zM8.078 7.8a7 7 0 0 0 .2-.828q.046-.282.038-.465a.6.6 0 0 0-.032-.198.5.5 0 0 0-.145.04c-.087.035-.158.106-.196.283-.04.192-.03.469.046.822q.036.167.09.346z" />
                    </svg>
                `;
                
                replacementLink.innerHTML = svg + "본문 PDF 내용 보기";
                
                replacementLink.style.width = "100%";
                replacementLink.style.padding = "12px";
                replacementLink.style.backgroundColor = "#F1F4F6";
                replacementLink.style.borderRadius = "10px";
                replacementLink.style.textAlign = "center";
                replacementLink.style.boxSizing = "border-box";
                replacementLink.style.textDecoration = "none"; // 링크 밑줄 제거
                replacementLink.style.color = "inherit"; // 링크 색상 상속
                
                const svgElement = replacementLink.querySelector('.pdf');
                if (svgElement) {
                    svgElement.style.marginRight = "12px"; // 텍스트와 아이콘 간 간격
                    svgElement.style.color = "red";
                }
                
                targetIframe.parentNode.replaceChild(replacementLink, targetIframe);
            });
        
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
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
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
