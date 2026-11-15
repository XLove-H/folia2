#!/usr/bin/env bash
# 在 macOS 上一条命令产出未签名 IPA（需要 Xcode + XcodeGen）
set -euo pipefail
cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null 2>&1 || {
  echo "缺少 xcodegen，先执行: brew install xcodegen"
  exit 1
}

echo "==> 生成 Xcode 工程"
xcodegen generate --spec project.yml

echo "==> 编译 Release（不签名）"
xcodebuild \
  -project Folia.xcodeproj \
  -scheme Folia \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  -quiet \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP="build/Build/Products/Release-iphoneos/Folia.app"
test -d "$APP" || { echo "编译产物缺失: $APP"; exit 1; }

echo "==> 打包 Payload"
rm -rf Payload Folia-unsigned.ipa
mkdir -p Payload
cp -R "$APP" Payload/
ditto -c -k --sequesterRsrc --keepParent Payload Folia-unsigned.ipa

echo "==> 完成: $(pwd)/Folia-unsigned.ipa"
ls -lh Folia-unsigned.ipa
