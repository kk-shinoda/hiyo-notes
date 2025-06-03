//
//  ContentView.swift
//  hiyo-notes
//
//  Created by kk-shinoda on 2025/06/01.
//

import SwiftUI

struct ContentView: View {
    @State private var noteText: String = ""
    @EnvironmentObject private var windowManager: WindowManager
    
    var body: some View {
        VStack(spacing: 0) {
            // ツールバー
            HStack {              
                Spacer()

                // 最前面表示トグル
                Toggle("常に最前面", isOn: $windowManager.isAlwaysOnTop)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                
                // 保存ボタン（後で実装）
                Button(action: saveNote) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("保存")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // メインエディタ
            TextEditor(text: $noteText)
                .font(.system(size: 14).monospaced())
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
                .padding(8)
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            loadNote()
        }
        .onChange(of: noteText) { _, _ in
            // リアルタイム自動保存（デバウンス付き）
            autoSave()
        }
    }
    
    // ノートの保存
    private func saveNote() {
        // 後でファイル保存機能を実装
        print("保存機能は後で実装します")
    }
    
    // ノートの読み込み
    private func loadNote() {
        // 後でファイル読み込み機能を実装
        noteText = "ここにメモを入力してください...\n\n```swift\n// コードブロックのテスト\nprint(\"Hello, World!\")\n```"
    }
    
    // 自動保存（デバウンス付き）
    private func autoSave() {
        // 後で実装：タイマーを使用してデバウンス処理
        print("自動保存: \(noteText.count)文字")
    }
}

#Preview {
    ContentView()
        .frame(width: 600, height: 400)
        .environmentObject(WindowManager())
}
