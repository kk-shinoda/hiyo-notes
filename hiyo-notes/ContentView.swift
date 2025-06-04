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
    @State private var showingImporter = false
    @EnvironmentObject private var windowManager: WindowManager
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var genreManager = GenreManager()
    @StateObject private var noteManager: NoteManager
    
    init() {
        let settings = SettingsManager()
        let genres = GenreManager()
        let notes = NoteManager(settingsManager: settings, genreManager: genres)
        
        _settingsManager = StateObject(wrappedValue: settings)
        _genreManager = StateObject(wrappedValue: genres)
        _noteManager = StateObject(wrappedValue: notes)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ツールバー
            HStack {
                // ジャンル選択ドロップダウン
                Menu {
                    ForEach(genreManager.genres) { genre in
                        Button(action: {
                            genreManager.setCurrentGenre(genre)
                            noteManager.switchToGenre(genre.name)
                        }) {
                            HStack {
                                Circle()
                                    .fill(genreManager.getGenreColor(genre))
                                    .frame(width: 8, height: 8)
                                Text(genre.name)
                                if genre.id == genreManager.currentGenre.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(genreManager.getGenreColor(genreManager.currentGenre))
                            .frame(width: 8, height: 8)
                        Text(genreManager.currentGenre.name)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("ジャンルを選択")
                
                // 新規メモボタン
                Button(action: createNewNote) {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                }
                .buttonStyle(.borderless)
                .help("新規メモ (⌘N)")
                .keyboardShortcut("n", modifiers: .command)
                
                // 保存ボタン
                Button(action: saveCurrentNote) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16))
                }
                .buttonStyle(.borderless)
                .help("保存 (⌘S)")
                .keyboardShortcut("s", modifiers: .command)
                
                // 読み込みボタン
                Button(action: { showingImporter = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                }
                .buttonStyle(.borderless)
                .help("読み込み (⌘O)")
                .keyboardShortcut("o", modifiers: .command)
                
                Spacer()
                
                // 現在のメモ情報
                if let currentNote = noteManager.currentNote {
                    Text(currentNote.filename)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                }
                
                // 設定ボタン
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                }
                .buttonStyle(.borderless)
                .help("設定")
                
                // 最前面表示ボタン
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
            initializeApp()
        }
        .onChange(of: genreManager.currentGenre) { _, newGenre in
            noteManager.switchToGenre(newGenre.name)
        }
        .onChange(of: noteManager.currentNote) { _, newNote in
            if let note = newNote {
                noteText = note.content
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settingsManager: settingsManager, genreManager: genreManager, noteManager: noteManager)
        }
        .fileExporter(
            isPresented: $noteManager.showingExporter,
            document: noteManager.documentToExport,
            contentType: .plainText,
            defaultFilename: noteManager.currentNote?.filename ?? "note.md"
        ) { result in
            switch result {
            case .success(let url):
                print("✅ Note saved to: \(url)")
                noteManager.onSaveCompleted()
            case .failure(let error):
                print("❌ Save failed: \(error)")
                showAlert("保存に失敗しました: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    loadNoteFromFile(url)
                }
            case .failure(let error):
                print("❌ Import failed: \(error)")
                showAlert("読み込みに失敗しました: \(error.localizedDescription)")
            }
        }
        .alert("エラー", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // アプリ初期化
    private func initializeApp() {
        // NoteManagerの初期化で自動的にdefault_001.mdが作成される
        print("🚀 App initialized")
    }
    
    // 新規メモを作成
    private func createNewNote() {
        noteManager.createNewNote()
        noteText = ""
        print("📝 New note created for genre: \(genreManager.currentGenre.name)")
    }
    
    // メモを保存
    private func saveCurrentNote() {
        noteManager.saveNote(content: noteText)
    }
    
    // ファイルからメモを読み込み
    private func loadNoteFromFile(_ url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let filename = url.lastPathComponent
            let document = NoteDocument(text: content, suggestedFilename: filename)
            noteManager.loadNoteFromDocument(document, filename: filename)
        } catch {
            showAlert("ファイルの読み込みに失敗しました: \(error.localizedDescription)")
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
