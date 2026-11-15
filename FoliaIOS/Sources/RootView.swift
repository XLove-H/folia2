import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: WebStore
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let url = store.serverURL {
                FoliaWebView(
                    url: url,
                    reloadToken: store.reloadToken,
                    isLoading: $isLoading,
                    errorMessage: $errorMessage
                )

                if let message = errorMessage {
                    errorCard(message)
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.top, 6)
                        .padding(.trailing, 12)
                }

                if errorMessage == nil && !isLoading {
                    settingsButton
                }
            } else {
                ServerSettingsView(isFirstRun: true)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showSettings) {
            ServerSettingsView()
                .environmentObject(store)
        }
    }

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .opacity(0.45)
        .padding(.top, 4)
        .padding(.trailing, 8)
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34))
                .foregroundColor(.white.opacity(0.9))
            Text("页面加载失败")
                .font(.headline)
            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Button("重试") { store.reload() }
                    .buttonStyle(.borderedProminent)
                Button("设置") { showSettings = true }
                    .buttonStyle(.bordered)
            }
            .padding(.top, 4)
        }
        .padding(22)
        .frame(maxWidth: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 24)
    }
}
