#!/bin/bash

# プロジェクトのルートディレクトリに移動
cd "$(dirname "$0")/.."

# ビルド用ディレクトリをクリーンアップ
rm -rf build
rm -f hiyo-notes.dmg

echo "🔨 アプリをビルド中..."

# アプリをビルド
xcodebuild -project hiyo-notes.xcodeproj \
           -scheme hiyo-notes \
           -configuration Release \
           -derivedDataPath build \
           clean build

if [ $? -ne 0 ]; then
    echo "❌ ビルドに失敗しました"
    exit 1
fi

echo "📦 DMGを作成中..."

# DMG作成用の一時ディレクトリを作成
mkdir -p dmg_temp

# ビルドされたアプリをコピー
cp -R "build/Build/Products/Release/hiyo-notes.app" dmg_temp/

# DMGを作成
hdiutil create -volname "hiyo-notes" \
               -srcfolder dmg_temp \
               -ov \
               -format UDZO \
               hiyo-notes.dmg

# 一時ディレクトリを削除
rm -rf dmg_temp
rm -rf build

if [ -f "hiyo-notes.dmg" ]; then
    echo "✅ DMGが正常に作成されました: hiyo-notes.dmg"
else
    echo "❌ DMGの作成に失敗しました"
    exit 1
fi 