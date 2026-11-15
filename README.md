# Folia iOS 外壳（非官方）

把 [chthollyphile/folia-major](https://github.com/chthollyphile/folia-major) 的 Web 版包成一个可以在 iPhone 上安装的 App。

> **这不是 Folia 官方 iOS 版。** 上游仓库没有 iOS 目标，也没有任何 IPA 产物；本工程是照着它「Web 版 + Electron 桌面端」的架构写的 WKWebView 宿主。

---

## 一、先说清楚三件事实

**1. 没有东西可以「逆向成 IPA」。**
folia-major 是 TypeScript/React 的 PWA，桌面端用 Electron 打包，发布产物只有 `.exe / .dmg / .deb / .rpm / tar.gz`。仓库里没有 `.xcodeproj`、没有 Swift/ObjC 的 iOS 代码，也就没有可逆向的 iOS 二进制。要得到 IPA，只能**新写一个 iOS 壳**——也就是本工程做的事。

**2. IPA 只能在 macOS 上编出来。**
IPA 里的可执行文件是 arm64 Mach-O，必须用 iOS SDK 的 clang + Apple 的 codesign 产出，Windows 上没有可行的交叉编译路径。所以本工程提供两条路：GitHub Actions 的免费 macOS runner，或者你自己的 Mac。

**3. Folia 的 Web 版没有公共实例。**
官方文档写明 Web 版要自己部署：**网易云 API 服务是必需的**，酷狗/QQ 音源、AI 主题、同步服务各自另配。所以这个 App **不内置地址**，首次启动让你填自己部署好的 URL。没有后端的话，App 能打开但搜不到歌。

---

## 二、目录结构

```
.
├── project.yml                  # XcodeGen 工程描述（.xcodeproj 由它生成，不提交进仓库）
├── Support/Info.plist           # 后台音频、ATS、深色模式等
├── FoliaIOS/Sources/
│   ├── FoliaApp.swift           # @main
│   ├── RootView.swift           # 主界面 + 加载/错误浮层
│   ├── FoliaWebView.swift       # WKWebView 封装、导航策略、进程回收恢复
│   ├── ServerSettingsView.swift # 服务器地址 / 清缓存
│   ├── WebStore.swift           # 地址持久化 + 重载信号
│   └── AudioSession.swift       # AVAudioSession(.playback)
├── FoliaIOS/Resources/Assets.xcassets/   # AppIcon（按官方 icon.svg 几何复刻）
├── scripts/build-ipa.sh         # 一条命令出未签名 IPA
├── scripts/build-ipa-swiftc.sh  # 备用：不用 XcodeGen，直接 swiftc
├── scripts/make-icons.py        # 重新生成图标（改了配色/尺寸时用）
└── .github/workflows/ios-unsigned-ipa.yml
```

## 三、已实现的 iOS 适配

| 能力 | 做法 |
|---|---|
| 全屏 WebView + 安全区 | SwiftUI 布局，`contentInsetAdjustmentBehavior = .never` 避免双重内缩 |
| 静音键下也能出声 | `AVAudioSession` 类别 `.playback` |
| 切后台继续播 | `UIBackgroundModes = audio` + 会话保持 |
| 免手势自动播放 | `mediaTypesRequiringUserActionForPlayback = []` |
| 登录状态保留 | `WKWebsiteDataStore.default()`（Cookie/localStorage/IndexedDB 持久化） |
| `target="_blank"` 不乱弹窗 | 拦截后在同一 WebView 打开 |
| 外链 / `tel:` / `mailto:` | 交给系统 |
| 渲染进程被回收 | `webViewWebContentProcessDidTerminate` 自动 reload |
| 页内识别外壳 | 注入 `window.__FOLIA_IOS__`，UA 追加 `FoliaIOS/1.0` |
| 加载失败 | 居中错误卡片 + 重试 / 改地址 |

## 四、路线 A：没有 Mac，用 GitHub Actions 出 IPA

> 完整逐步说明见 **[GUIDE-从零到IPA.md](GUIDE-从零到IPA.md)**（含每步该看到什么、出错对照表）。

准备：一个免费 GitHub 账号（邮箱注册即可，不绑卡不求人）。

1. 新建仓库：GitHub → 右上角 `+` → **New repository** → 名字随便（如 `folia-ios`）→ 建议选 **Public**（Actions 免费不限时长）→ Create。
2. 上传文件：进入仓库 → **Add file → Upload files** → 把解压后文件夹**里面的内容**（含 `.github`、`Support`、`FoliaIOS`、`project.yml`）拖进去 → **Commit changes**。
   - 注意：拖的是文件夹内部，不是外面那层文件夹，否则 workflow 不会被识别。
3. 跑构建：仓库顶部 **Actions** → 左侧 **Build unsigned IPA** → 右侧 **Run workflow** → 绿按钮。
4. 等约 3–5 分钟，进入这次运行 → 页面底部 **Artifacts** → 下载 `Folia-unsigned-ipa` → 解压得到 `Folia-unsigned.ipa`。

> 首次构建如果报编译错误，把红色日志贴给我，我改代码再让你重跑。这份 Swift 我是在没有 Swift 编译器的 Windows 上写的，没做过本地编译验证——所以 workflow 里做了双保险：路线 A（XcodeGen + xcodebuild）失败会自动切到路线 B（swiftc 直接编译）。

## 五、路线 B：有 Mac

```bash
brew install xcodegen
./scripts/build-ipa.sh          # 产出 Folia-unsigned.ipa
```

想直接装到自己手机上（不用 Sideloadly）：`xcodegen generate` 后打开 `Folia.xcodeproj`，在 *Signing & Capabilities* 里选自己的 Apple ID Team，连上 iPhone 直接 Run。

## 六、把未签名 IPA 装进 iPhone

未签名包不能直接装，必须用你自己的 Apple ID 重签：

1. Windows/Mac 装 [Sideloadly](https://sideloadly.io/)。
2. 数据线连 iPhone，Sideloadly 里选中 `Folia-unsigned.ipa`，填 Apple ID，Start。
3. iPhone 上：**设置 → 通用 → VPN与设备管理** → 信任你的开发者证书。
4. 首次打开若提示「不受信任的开发者」，同上路径再点一次信任。

**免费 Apple ID 的限制**：证书 7 天过期，到期要用 Sideloadly 重签一次；同时最多 3 个自签 App。付费开发者账号（$99/年）可签到 1 年并走 TestFlight。

## 七、构建完要先做的事

打开 App 第一屏就是地址输入框，填你部署好的 Folia Web 地址，例如：

- Docker 部署在 NAS/服务器：`https://folia.你的域名.com`
- 局域网自测：`http://192.168.1.10:3000`

> 局域网 HTTP 地址已在 `Info.plist` 里放开（`NSAllowsArbitraryLoads`），但公网使用请务必上 HTTPS —— 否则 Cookie、Service Worker、音频流都可能被限制。

## 八、已知限制（基本都是 Web 版本身的限制）

- **本地音乐导入不可用**：桌面版靠 File System Access API 扫文件夹，iOS Safari/WKWebView 没有这个 API。请用 Navidrome/Subsonic 或在线音源。
- **桌面增强全都没有**：壁纸模式、视频录制、Stage API、遥控窗是 Electron 专属。
- **锁屏控制**：目前没有接 `MPNowPlayingInfoCenter`，锁屏只显示系统级音频信息，切歌按钮不可靠。要的话告诉我，加一个 `navigator.mediaSession` 桥接。
- **后台保活**：iOS 会在内存压力下杀 WebView 的渲染进程；本工程做了自动 reload，但播放会中断。
- **音频效果器/AI 主题**：依赖你后端的配置，与外壳无关。

## 九、想改什么改哪里

| 想改 | 位置 |
|---|---|
| App 显示名 | `Support/Info.plist` → `CFBundleDisplayName` |
| Bundle ID | `Support/Info.plist` + `project.yml` → `PRODUCT_BUNDLE_IDENTIFIER` |
| 版本号 | `Support/Info.plist` 的 `CFBundleShortVersionString` / `CFBundleVersion` |
| 最低系统版本 | `project.yml` 的 `deploymentTarget` 与 `Info.plist` 的 `MinimumOSVersion` |
| 图标 | 改 `scripts/make-icons.py` 后重跑（需要 Pillow） |
| 默认服务器地址 | `WebStore.swift` 里 `serverURLString` 的初始值 |

## 十、许可

上游 folia-major 是 **AGPL-3.0**。本工程只包含「加载网页的壳」，不复制其源代码，但**如果你把它分发给别人，请遵守 AGPL 的相应义务并注明来源于 folia-major**。自用无影响。
