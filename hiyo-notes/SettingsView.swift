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
    @Environment(\.dismiss) private var dismiss
    
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
                    Image(systemName: settingsManager.isLocationWritable() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(settingsManager.isLocationWritable() ? .green : .orange)
                    
                    Text(settingsManager.isLocationWritable() ? "書き込み可能" : "書き込み権限を確認してください")
                        .font(.caption)
                        .foregroundColor(settingsManager.isLocationWritable() ? .green : .orange)
                }
            }
            
            Spacer()
            
            // 簡潔なヒント
            Text("メモは選択したフォルダに「hiyo-notes.txt」として保存されます")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 450, height: 280)
        .fileImporter(
            isPresented: $settingsManager.showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first {
                    settingsManager.setSaveLocation(url: selectedURL)
                }
            case .failure(let error):
                print("❌ Folder selection failed: \(error)")
            }
        }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
} 