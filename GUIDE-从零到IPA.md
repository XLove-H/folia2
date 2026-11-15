# 从零到 IPA：一步步照做

> 全程不需要 Mac，不需要在这台 Windows 上装任何东西。只需要浏览器 + 一个邮箱。
> 预计耗时：注册 5 分钟 + 上传 3 分钟 + 构建 5 分钟 + 签名装机 10 分钟。

---

## 第 0 步：注册 GitHub 账号

1. 打开 <https://github.com/signup>
2. 依次填：**Email**（常用邮箱，QQ 邮箱/163/Gmail 都行）→ **Password**（≥8 位，含数字和小写）→ **Username**（英文+数字，会显示在仓库地址里，例如 `linyu-folia`）。
3. 会发一封验证码邮件，填进去。
4. 如果弹出「Verify your account」拼图/选题，按提示点完。
5. 完成后进 <https://github.com>，右上角看到你的头像 = 成功。

> 国内网络如果打不开或很慢，换网络/开代理再试；注册环节对 IP 比较敏感，尽量别频繁切换节点。

---

## 第 1 步：新建仓库

1. 右上角 **`+`** → **New repository**（或直接开 <https://github.com/new>）
2. **Repository name**：`folia-ios`
3. **Description**：随便写，比如 `Folia iOS shell`
4. 选 **Public**（推荐）
   - 原因：Public 仓库的 Actions 标准 runner **完全免费不限时长**；Private 仓库虽然也有免费额度，但 macOS runner 按 **10 倍**计费（免费额度≈200 分钟 macOS）。
   - 这份代码里没有任何密钥、服务器地址（地址是装机后手填的），公开没有泄露风险。
5. **不要**勾 "Add a README file"（我们自己的包里已经有 README）。
6. 点 **Create repository**。

**你应该看到**：一个空仓库页面，中间有 `Quick setup — if you've done this kind of thing before` 和一排 `Set up in Desktop / creating a new file / uploading an existing file` 链接。

---

## 第 2 步：上传工程文件 ⚠️ 最容易错的一步

1. 把 `folia-ios-shell.zip` 解压（右键 → 全部解压缩）。
2. 进入解压出来的文件夹，**确认里面直接就是这些**：

```
.github/        FoliaIOS/       Support/        scripts/
project.yml     README.md       .gitignore
```

3. 在该文件夹里按 **Ctrl+A 全选**，然后拖到第 4 步的网页上传区。
   ⚠️ **拖的是「文件夹里面的内容」，不是外面那层文件夹本身。**
   如果整个 `folia-ios` 文件夹被拖进去，文件会变成 `folia-ios/.github/...`，GitHub **永远不会**识别这个 workflow，你会卡在「Actions 里找不到 workflow」。

4. 回到仓库页面 → **Add file**（代码区右上） → **Upload files**
5. 把选中的内容拖进 `Drag files here to add them to your repository` 区域，等文件列表加载完（应显示 **30 个文件左右**，包含 `project.yml`、`README.md`、`.github/workflows/ios-unsigned-ipa.yml`）。
6. 底部 **Commit changes**。

**你应该看到**：仓库首页文件列表里有 `.github`、`FoliaIOS`、`Support`、`scripts`、`project.yml`、`README.md`。

> **如果 `.github` 没传上去**（网页上传偶尔会忽略点开头的目录）：别重来，手动建一个——
> 仓库 → **Add file** → **Create new file** → 文件名框里输入
> `.github/workflows/ios-unsigned-ipa.yml`（输入 `/` 会自动建目录）
> → 把项目里 `folia-ios/.github/workflows/ios-unsigned-ipa.yml` 的内容整段粘进去 → **Commit changes**。

---

## 第 3 步：跑构建

1. 仓库顶部标签栏点 **Actions**。
2. 第一次进来如果提示要不要启用，点 **I understand my workflows, go ahead and enable them**（自己新建的仓库一般默认已启用）。
3. 左侧列表点 **Build unsigned IPA**。
4. 右侧有 **Run workflow** 按钮 → 展开后分支选 `main` → 点绿色 **Run workflow**。
5. 刷新页面，会出现一条运行记录，图标是个**黄点**（转圈）→ **绿勾** 表示成功。

**耗时约 3–6 分钟**，主要花在 `brew install xcodegen` 上。

---

## 第 4 步：下载 IPA

1. 点进那条绿色的运行记录。
2. 页面**最底部**有个 **Artifacts** 区块。
3. 下载 **`Folia-unsigned-ipa`**（会得到一个 zip）。
4. 解压，里面就是 **`Folia-unsigned.ipa`**。

> 未登录 GitHub 是下载不了 Artifact 的，注意保持登录。

---

## 第 5 步：签名并装进 iPhone

未签名 IPA 不能直接装，要用你自己的 Apple ID 重签。

**准备（Windows 上）**
1. 先装 **iTunes**（Apple 官网下载版或 Microsoft Store 版都行）——Sideloadly 依赖它的驱动，**没装会连不上手机**。
2. 装 **Sideloadly**：<https://sideloadly.io/> → 下载 Windows 版 → 安装。

**签名**
1. 数据线连 iPhone，手机上点 **信任此电脑**。
2. 打开 Sideloadly，顶部 **iDevice** 一栏应该自动出现你的设备。
3. **IPA** 一栏点开，选中 `Folia-unsigned.ipa`。
4. **Apple ID** 填你的 Apple ID。
5. 点 **Start** → 输入 Apple ID 密码 → 如果账号开了双重认证，会弹框要 6 位验证码，填进去。
6. 等进度条结束，日志出现 `done` / `success` 字样。

**装机收尾（iPhone 上）**
1. **设置 → 通用 → VPN与设备管理** → 点你的 Apple ID → **信任**。
2. iOS 16 及以上还需要开开发者模式：**设置 → 隐私与安全性 → 开发者模式** → 打开 → **重启手机** → 重启后确认。
3. 回到桌面，打开 **Folia**。

---

## 第 6 步：首次打开

第一屏是地址输入框，填你部署好的 Folia Web 版地址：

- Docker 部署在 NAS/服务器：`https://folia.你的域名.com`
- 局域网自测：`http://192.168.1.10:3000`

填完点 **保存并打开**。右上角有个淡色齿轮，随时可以改地址或清缓存。

> ⚠️ **没部署后端的话，这里填什么都没用**——Folia Web 版必须有自己的服务端（网易云 API 是必需的）。见文末。

---

## 每 7 天要重签一次

免费 Apple ID 的证书 **7 天过期**，到期 App 打不开（闪退）。解决：

- 重新用 Sideloadly 装一次同一个 IPA（不用重新下载，也不用重新构建）；
- 或者改用 **AltStore**，它能在同一 Wi-Fi 下自动续签。

同一账号最多同时装 3 个自签 App。想彻底免掉这个麻烦，只有 $99/年 的付费开发者账号（1 年有效 + 可上 TestFlight）。

---

## 常见问题对照表

| 现象 | 原因 | 处理 |
|---|---|---|
| Actions 里找不到 "Build unsigned IPA" | `.github/workflows/` 路径不对 | 见第 2 步末尾的手动创建法 |
| 运行记录红色 ✗，日志卡在 `brew install` | runner 上 brew 抽风 | 重跑一次；也不影响，路线 B 会接管编译 |
| 日志报 `xcodegen: command not found` | brew 装失败 | 正常，路线 B（swiftc）会继续尝试 |
| 两条路线都红 | Swift 编译错误 | 把 `路线 A` / `路线 B` 那段红字发我，我改代码你重跑 |
| Artifacts 里没有东西 | 构建失败没到上传步 | 看失败那步的日志 |
| Sideloadly 连不上 iPhone | 没装 iTunes / 没信任电脑 | 装 iTunes 后重开 Sideloadly |
| 装完点开闪退 | 证书没信任 / 没开开发者模式 | 第 5 步的「装机收尾」 |
| 用了一周突然打不开 | 免费证书过期 | 重新签，见上节 |

---

## 后端怎么办

这个 App 只是外壳。要真正听歌，你需要一个跑起来的 Folia Web 服务：

```bash
# 官方 Docker 全栈方案，一条命令同时拉起 Web + 音乐接口 + 同步服务
docker compose up -d
```

之后把访问地址填进 App。如果你的机器能跑 Docker（NAS、云服务器、常年开机的电脑），告诉我系统类型，我可以直接给你写好 compose 配置和反向代理（HTTPS）设置。
