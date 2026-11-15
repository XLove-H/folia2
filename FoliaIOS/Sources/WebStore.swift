import Combine
import Foundation
import WebKit

/// 保存用户填写的 Folia 服务器地址，并提供强制重载 / 清除站点数据的入口。
final class WebStore: ObservableObject {
    private static let urlKey = "folia.server.url"

    @Published var serverURLString: String
    /// 每次自增都会让 WebView 重新加载（相当于「刷新」）。
    @Published var reloadToken: Int = 0

    init() {
        serverURLString = UserDefaults.standard.string(forKey: Self.urlKey) ?? ""
    }

    var serverURL: URL? {
        let raw = serverURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        if let url = URL(string: raw),
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            return url
        }
        // 用户只填了域名或 IP:端口时，默认补 https://
        return URL(string: "https://" + raw)
    }

    func save(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        serverURLString = trimmed
        UserDefaults.standard.set(trimmed, forKey: Self.urlKey)
        reloadToken += 1
    }

    func reload() {
        reloadToken += 1
    }

    func clearWebsiteData(completion: @escaping () -> Void = {}) {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) {
            DispatchQueue.main.async { completion() }
        }
    }
}
