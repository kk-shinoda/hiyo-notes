//
//  ContentView.swift
//  hiyo-notes
//
//  Created by kk-shinoda on 2025/06/01.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var noteText: String = ""
    @State private var showingSettings = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var saveTimer: Timer?
    @State private var showingExporter = false
    @EnvironmentObject private var windowManager: WindowManager
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // ツールバー
            HStack {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                }
                .buttonStyle(.borderless)
                .help("設定")
                
                Spacer()
                
                // 手動保存ボタンを追加
                Button(action: {
                    showingExporter = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                }
                .buttonStyle(.borderless)
                .help("名前を付けて保存")
                
                Button(action: {
                    windowManager.toggleAlwaysOnTop()
                }) {
                    Image(systemName: windowManager.isAlwaysOnTop ? "pin.fill" : "pin")
                        .font(.system(size: 16))
                        .foregroundColor(windowManager.isAlwaysOnTop ? .blue : .primary)
                }
                .buttonStyle(.borderless)
                .help(windowManager.isAlwaysOnTop ? "最前面表示を解除" : "最前面に表示")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // メインエディタ
            TextEditor(text: $noteText)
                .font(.system(.body, design: .default))
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
                .padding(12)
        }
        .onAppear {
            loadNote()
        }
        .onChange(of: noteText) { _, _ in
            autoSave()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settingsManager: settingsManager)
        }
        .alert("エラー", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: TextDocument(text: noteText),
            contentType: .plainText,
            defaultFilename: "hiyo-notes"
        ) { result in
            switch result {
            case .success(let url):
                print("✅ File exported to: \(url)")
            case .failure(let error):
                showAlert("エクスポートに失敗しました: \(error.localizedDescription)")
            }
        }
    }
    
    // シンプルなノート保存（デフォルト場所のみ）
    private func saveNote() {
        guard let saveURL = settingsManager.getSaveLocationURL() else {
            showAlert("保存場所が設定されていません")
            return
        }
        
        let fileURL = saveURL.appendingPathComponent("hiyo-notes.txt")
        
        do {
            try noteText.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ ファイルを保存しました: \(fileURL.path)")
        } catch {
            // デフォルト場所での保存に失敗した場合はfileExporterを使用
            print("⚠️ Default save failed, using fileExporter: \(error)")
            showingExporter = true
        }
    }
    
    // ノートの読み込み
    private func loadNote() {
        guard let saveURL = settingsManager.getSaveLocationURL() else {
            noteText = "ここにメモを入力してください..."
            return
        }
        
        let fileURL = saveURL.appendingPathComponent("hiyo-notes.txt")
        
        do {
            noteText = try String(contentsOf: fileURL, encoding: .utf8)
            print("✅ ファイルを読み込みました: \(fileURL.path)")
        } catch {
            noteText = "ここにメモを入力してください..."
            print("📝 新規ファイルを作成します")
        }
    }
    
    // 自動保存（デバウンス付き）
    private func autoSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            DispatchQueue.main.async {
                self.saveNote()
            }
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// FileDocumentプロトコルに準拠したTextDocument
struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var text: String
    
    init(text: String = "") {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

#Preview {
    ContentView()
        .frame(width: 600, height: 400)
        .environmentObject(WindowManager())
}
