//
//  SettingsView.swift
//  hiyo-notes
//
//  Created by kk-shinoda on 2025/06/01.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var genreManager: GenreManager
    var noteManager: NoteManager?
    @Environment(\.dismiss) private var dismiss
    @State private var newGenreName = ""
    @State private var showingAddGenre = false
    @State private var genreErrorMessage: String? = nil
    @State private var showGenreError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // ヘッダー
            HStack {
                Text("設定")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("完了") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 保存場所設定
                    VStack(alignment: .leading, spacing: 12) {
                        Text("保存場所")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("現在の保存場所:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(settingsManager.saveLocation)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Button("変更") {
                                settingsManager.selectSaveLocation()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // 権限状態の表示
                        HStack {
                            Image(systemName: settingsManager.isSaveLocationConfigured() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(settingsManager.isSaveLocationConfigured() ? .green : .orange)
                            
                            Text(settingsManager.isSaveLocationConfigured() ? 
                                 "保存場所が設定済み" : 
                                 "保存場所を選択してください")
                                .font(.caption)
                                .foregroundColor(settingsManager.isSaveLocationConfigured() ? .green : .orange)
                        }
                    }
                    
                    Divider()
                    
                    // ジャンル管理
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("ジャンル管理")
                                .font(.headline)
                            
                            // エラーメッセージ表示
                            if showGenreError, let errorMessage = genreErrorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                                    .transition(.opacity)
                            }
                            
                            Spacer()
                            
                            Button("追加") {
                                showingAddGenre = true
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // ジャンル一覧
                        LazyVStack(spacing: 8) {
                            ForEach(genreManager.genres) { genre in
                                HStack {
                                    Circle()
                                        .fill(genreManager.getGenreColor(genre))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(genre.name)
                                        .font(.body)
                                    
                                    if genre.isDefault {
                                        Text("デフォルト")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    
                                    Spacer()
                                    
                                    if !genre.isDefault {
                                        Button("削除") {
                                            genreManager.deleteGenre(genre)
                                        }
                                        .buttonStyle(.borderless)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 500, height: 500)
        .onChange(of: genreManager.errorId) { _, errorId in
            print("🔄 SettingsView: GenreManager.errorId changed to \(errorId)")
            if !genreManager.errorMessage.isEmpty {
                showGenreErrorMessage(genreManager.errorMessage)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showGenreError)
        .fileImporter(
            isPresented: $settingsManager.showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first {
                    settingsManager.setSaveLocation(url: selectedURL)
                    // 保存場所変更後、既存ノートを新しい場所に対応
                    noteManager?.handleSaveLocationChanged()
                }
            case .failure(let error):
                print("❌ Folder selection failed: \(error)")
            }
        }
        .alert("新しいジャンルを追加", isPresented: $showingAddGenre) {
            TextField("ジャンル名", text: $newGenreName)
            Button("追加") {
                if !newGenreName.isEmpty {
                    genreManager.addGenre(name: newGenreName)
                    newGenreName = ""
                }
            }
            Button("キャンセル", role: .cancel) {
                newGenreName = ""
            }
        } message: {
            Text("新しいジャンルの名前を入力してください")
        }
    }
    
    private func showGenreErrorMessage(_ message: String) {
        print("🟢 SettingsView: エラーメッセージ表示 - \(message)")
        genreErrorMessage = message
        showGenreError = true
        
        // 3秒後に自動クリア（設定画面なので短めに設定）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print("🟢 SettingsView: エラーメッセージクリア")
            self.genreErrorMessage = nil
            self.showGenreError = false
        }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager(), genreManager: GenreManager())
} 