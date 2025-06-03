#!/bin/bash

echo "🚀 hiyo-notesをインストール中..."

# DMGを作成
./scripts/build_dmg.sh

if [ $? -ne 0 ]; then
    echo "❌ DMGの作成に失敗しました"
    exit 1
fi

# DMGをマウント
hdiutil attach hiyo-notes.dmg -mountpoint /tmp/hiyo-notes-mount

# アプリをApplicationsフォルダにコピー
cp -R "/tmp/hiyo-notes-mount/hiyo-notes.app" "/Applications/"

# DMGをアンマウント
hdiutil detach /tmp/hiyo-notes-mount

echo "✅ hiyo-notesが正常にインストールされました"
echo "Launchpadまたは/Applications/hiyo-notes.appから起動できます" 