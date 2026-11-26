# 体重时光 · iOS 工程

> 第一次用 GitHub：请直接看 **[新手步骤.md](新手步骤.md)**，里面有从注册/登录到下载 IPA 的逐步说明。

把现有的「体重时光」网页应用包成原生 iOS 外壳（Capacitor + WKWebView），通过 GitHub Actions 在 macOS 云端编译出**未签名 IPA**，再使用你自己的签名工具重签安装。

适配 iPhone 17 / iOS 27.2；部署目标为 iOS 15.0+，架构为 arm64。应用界面、照片、体重记录、趋势图、前后对比和备份逻辑与桌面版一致。

## 你需要准备

- 一个 GitHub 账号（免费即可）
- 你的签名工具 / 证书（ESign、全能签、轻松签等）
- 不需要 Mac，不需要本地装 Xcode；云端使用 Node 22 + pnpm 11 + Capacitor 7

> GitHub Actions 的 macOS runner 负责编译；仓库设为 Public 时 macOS 分钟数免费，Private 仓库会消耗账号额度。

## 第一次上传到 GitHub

1. 登录 GitHub，新建一个空仓库，例如 `weight-time-ios`。**不要**勾选自动生成 README。
2. 把本文件夹里的全部文件上传到仓库根目录（`node_modules`、`ios/App/Pods`、`build`、`dist` 不需要上传，`.gitignore` 已忽略它们）。
   - 用 GitHub Desktop 最简单：把本文件夹添加为本地仓库，提交并 Push。
   - 或者在本文件夹执行：
     ```bash
     git init
     git add .
     git commit -m "Weight Time iOS app"
     git branch -M main
     git remote add origin https://github.com/你的用户名/weight-time-ios.git
     git push -u origin main
     ```
3. 确保 `main` 分支上有 `.github/workflows/build-ios.yml` 和 `scripts/build-unsigned-ipa.sh` 两个文件。

## 云端编译出 IPA

1. 打开仓库的 **Actions** 标签页。
2. 左侧选择 **Build unsigned iOS IPA**。
3. 点右侧 **Run workflow** → 选择 `main` → **Run workflow**。
   - 如果上传/推送后已经自动开始构建，可以跳过这一步。
4. 等 5–10 分钟。成功后：
   - **Releases** 页面会出现 `体重时光 iOS Build N`，里面有 `WeightTime-unsigned.ipa`，可直接下载；
   - 本次运行的 Artifacts 里也有一份 zip 包。
5. 把 IPA 传到 iPhone，用你的签名工具导入、重签、安装。

## 签名时注意

- 默认 Bundle ID：`com.weighttime.journal`。
- 如果你的证书 / 描述文件绑定的是别的 App ID，在签名工具里把 Bundle ID 改成匹配的值，或使用通配符证书。
- 签完后如果首次打开闪退，优先检查：证书是否有效、描述文件是否包含这台 iPhone、Bundle ID 是否匹配。
- 未签名 IPA **不能**直接双击安装，必须先签名。

## 数据与备份

- 照片和体重数据保存在 WKWebView 的本地存储中，不会上传服务器。
- iOS 版还会自动把一份 `weight-time-data.json` 镜像写入 App 的 Documents 目录；如果系统清理了 WebView 存储，下次启动会尝试从这份镜像恢复。
- 应用内「导出备份」会调用 iOS 分享面板；选择 **存储到文件** 保存 JSON。照片包含在 JSON 里。
- 换手机 / 重装应用前，请先导出备份，再在新应用里用「导入备份」恢复。
- 卸载 App 会清空应用数据和 Documents 镜像。

## 本地 Mac 构建（可选）

有 Mac 时，安装 Xcode 和 CocoaPods，然后：

```bash
corepack enable
pnpm install
bash scripts/build-unsigned-ipa.sh
```

产物在 `dist/WeightTime-unsigned.ipa`。

## 常见问题

**Actions 报 pod install 失败？**
打开失败日志，确认 `macos-15` runner 和 CocoaPods 可用；重新运行一次通常能解决网络问题。

**iOS 27.2 能装吗？**
可以。App 使用 iOS 15.0 部署目标，能在 iOS 27.2 上运行；构建使用 GitHub runner 的 Xcode 16 / iOS 18 SDK，不要求本机有 iOS 27 SDK。Workflow 会优先选择 Xcode 16，避免 Capacitor 7 在新版 SDK 的场景生命周期要求下出现启动问题。

**想改 App 名称 / 图标？**
改 `ios/App/App/Info.plist` 里的 `CFBundleDisplayName`，图标替换 `resources/icon.png` 后运行 `pnpm assets:ios`，再提交重新构建。

**想改 Bundle ID？**
改 `capacitor.config.json` 里的 `appId`，以及 Xcode 工程里的 `PRODUCT_BUNDLE_IDENTIFIER`（两处 Release/Debug），或签名时在签名工具里直接改。
