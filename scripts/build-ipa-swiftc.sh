#!/usr/bin/env bash
# 备用方案：完全不用 XcodeGen / .xcodeproj，直接 swiftc 编出可执行文件再手工组 .app。
# 万一 `xcodegen generate` 在你的环境里出问题，用这个脚本。
set -euo pipefail
cd "$(dirname "$0")/.."

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
OUT="build-swiftc"
APP="$OUT/Payload/Folia.app"

rm -rf "$OUT"
mkdir -p "$APP"

echo "==> 用 swiftc 编译 (iOS SDK: $SDK)"
xcrun --sdk iphoneos swiftc \
  -sdk "$SDK" \
  -target arm64-apple-ios15.0 \
  -parse-as-library \
  -O -whole-module-optimization \
  -framework SwiftUI -framework WebKit -framework AVFoundation -framework UIKit \
  FoliaIOS/Sources/*.swift \
  -o "$APP/Folia"

echo "==> 编译 Asset Catalog（图标）"
xcrun actool FoliaIOS/Resources/Assets.xcassets \
  --compile "$APP" \
  --platform iphoneos \
  --minimum-deployment-target 15.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$OUT/asset-info.plist" \
  --errors --warnings \
  > /dev/null

cp Support/Info.plist "$APP/Info.plist"
# 把 actool 生成的图标键并入 Info.plist
/usr/libexec/PlistBuddy -c "Merge $OUT/asset-info.plist" "$APP/Info.plist" 2>/dev/null || true

echo "==> 打包 IPA"
cd "$OUT"
rm -f ../Folia-unsigned.ipa
ditto -c -k --sequesterRsrc --keepParent Payload ../Folia-unsigned.ipa
cd ..
ls -lh Folia-unsigned.ipa
echo "注意：这个包没有 Assets.car 之外的任何额外资源，也没有签名，用 Sideloadly 重新签名后再装。"
