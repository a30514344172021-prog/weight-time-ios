#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "错误：没有找到 xcodebuild。这个脚本必须在 macOS + Xcode 上运行。" >&2
  exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
  if command -v corepack >/dev/null 2>&1; then
    corepack enable
  else
    echo "错误：没有找到 pnpm，请先安装 Node.js 22+ 和 pnpm 11。" >&2
    exit 1
  fi
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "==> 安装 CocoaPods"
  sudo gem install cocoapods
fi

echo "==> 安装 JavaScript 依赖"
pnpm install --frozen-lockfile

echo "==> 同步 Capacitor 插件与 www 资源"
npx cap sync ios

echo "==> 安装 CocoaPods 依赖"
(
  cd ios/App
  pod install
)

echo "==> 编译 Release（关闭代码签名）"
(
  cd ios/App
  xcodebuild \
    -workspace App.xcworkspace \
    -scheme App \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -derivedDataPath build \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    build
)

APP_PATH="$ROOT/ios/App/build/Build/Products/Release-iphoneos/App.app"
if [ ! -d "$APP_PATH" ]; then
  echo "错误：没有找到编译产物 $APP_PATH" >&2
  exit 1
fi

echo "==> 打包未签名 IPA"
STAGE="$ROOT/build/ipa-stage"
DIST="$ROOT/dist"
rm -rf "$STAGE"
rm -rf "$DIST"
mkdir -p "$STAGE/Payload" "$DIST"
cp -R "$APP_PATH" "$STAGE/Payload/App.app"
(
  cd "$STAGE"
  zip -qr "$DIST/WeightTime-unsigned.ipa" Payload
)

echo "==> 完成"
ls -lh "$DIST/WeightTime-unsigned.ipa"
shasum -a 256 "$DIST/WeightTime-unsigned.ipa" || true
