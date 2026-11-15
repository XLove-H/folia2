import SwiftUI
import UIKit
import WebKit

/// 包住 WKWebView 的 SwiftUI 组件。
struct FoliaWebView: UIViewRepresentable {
    let url: URL
    let reloadToken: Int
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        // 自动播放：不要求用户手势才能出声（原生 App 里是合理默认）
        configuration.mediaTypesRequiringUserActionForPlayback = []
        // 默认数据存储 = 持久化 Cookie / localStorage / IndexedDB，登录状态不会丢
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        // 追加到 UA 末尾，方便网页端识别「这是 iOS 外壳」
        configuration.applicationNameForUserAgent = "FoliaIOS/1.0"

        let controller = WKUserContentController()
        controller.addUserScript(
            WKUserScript(
                source: "window.__FOLIA_IOS__ = { version: '1.0', platform: 'ios', shell: 'wkwebview' };",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
        )
        configuration.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        context.coordinator.loadedURL = url
        context.coordinator.loadedToken = reloadToken
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        let changedURL = context.coordinator.loadedURL != url
        let needsReload = changedURL || context.coordinator.loadedToken != reloadToken
        guard needsReload else { return }

        context.coordinator.loadedURL = url
        context.coordinator.loadedToken = reloadToken
        errorMessage = nil

        if changedURL || webView.url == nil {
            webView.load(URLRequest(url: url))
        } else {
            webView.reload()
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: FoliaWebView
        var loadedURL: URL?
        var loadedToken: Int = 0

        init(_ parent: FoliaWebView) {
            self.parent = parent
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.errorMessage = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            // 有些 WebAudio 场景在页面加载后需要再激活一次才能出声
            AudioSession.activate()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            handle(error)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            // 渲染进程被系统回收（内存压力）后自动恢复
            webView.reload()
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let target = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let scheme = target.scheme?.lowercased() ?? ""
            if scheme != "http", scheme != "https", scheme != "about", scheme != "blob", scheme != "data", scheme != "file" {
                // mailto: / tel: / alipays: 之类交给系统
                UIApplication.shared.open(target, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }

            // target="_blank" 的链接在同一个 WebView 里打开，不要弹空白窗口
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        // MARK: - WKUIDelegate

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let target = navigationAction.request.url {
                let scheme = target.scheme?.lowercased() ?? ""
                if scheme == "http" || scheme == "https" {
                    webView.load(navigationAction.request)
                } else {
                    UIApplication.shared.open(target, options: [:], completionHandler: nil)
                }
            }
            return nil
        }

        // MARK: - Private

        private func handle(_ error: Error) {
            let nsError = error as NSError
            // -999 = 被我们主动取消的导航（比如 target=_blank 转投），不算失败
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                return
            }
            parent.isLoading = false
            parent.errorMessage = nsError.localizedDescription
        }
    }
}
