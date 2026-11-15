import SwiftUI

/// 服务器地址填写页：没有地址时全屏显示，有地址时可从齿轮按钮以 sheet 形式打开。
struct ServerSettingsView: View {
    @EnvironmentObject private var store: WebStore
    @Environment(\.dismiss) private var dismiss

    var isFirstRun: Bool = false

    @State private var draft: String = ""
    @State private var note: String?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("https://folia.example.com", text: $draft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .labelsHidden()
                } header: {
                    Text("Folia 服务器地址")
                } footer: {
                    Text("填你自己部署好的 Folia Web 版地址。这个 App 是 WebView 外壳，在线搜索/播放依赖你部署的网易云（必需）、酷狗、QQ 音乐 API 服务。")
                }

                Section {
                    Button {
                        store.save(draft)
                        if !isFirstRun { dismiss() }
                    } label: {
                        Label("保存并打开", systemImage: "arrow.right.circle.fill")
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if !isFirstRun {
                        Button {
                            store.reload()
                            dismiss()
                        } label: {
                            Label("重新加载当前页面", systemImage: "arrow.clockwise")
                        }
                    }
                }

                Section {
                    Button {
                        store.clearWebsiteData {
                            note = "已清除，重新打开需要重新登录"
                        }
                    } label: {
                        Label("清除网站数据", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } footer: {
                    Text(note ?? "会清空缓存、Cookie、localStorage。只在页面异常时使用。")
                }

                if isFirstRun {
                    Section("为什么需要自己填地址？") {
                        Text("Folia 官方只分发桌面版（exe/dmg/deb 等），没有提供公共 Web 实例。Web 版按官方文档必须自行部署：Docker 一条命令即可同时拉起 Web、音乐接口和同步服务。部署完把地址填到这里就能用。")
                            .font(.footnote)
                    }
                    Section("已知限制") {
                        Text("• iOS 不支持 File System Access API，桌面版的「导入本地文件夹」用不了，建议走 Navidrome / Subsonic 或在线音源\n• 桌面增强（壁纸模式、视频录制、Stage API）是 Electron 专属，网页版本来就没有")
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(isFirstRun ? "连接 Folia" : "设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isFirstRun {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") { dismiss() }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            draft = store.serverURLString
        }
    }
}
