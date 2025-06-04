//
//  SettingsManager.swift
//  hiyo-notes
//
//  Created by kk-shinoda on 2025/06/01.
//

import SwiftUI
import AppKit

class SettingsManager: ObservableObject {
    @Published var saveLocation: String {
        didSet {
            UserDefaults.standard.set(saveLocation, forKey: UserDefaultsKeys.saveLocation)
        }
    }
    
    @Published var showingFolderPicker = false
    
    private let logger = DebugLogger.shared
    
    // 設定キー定数
    private struct UserDefaultsKeys {
        static let saveLocation = "saveLocation"
    }
    
    // パス定数
    private struct PathConstants {
        static let defaultFolderName = "hiyo-notes"
        static let testFileName = "test.txt"
        static let testContent = "test"
    }
    
    init() {
        // デフォルトはDocuments/hiyo-notesフォルダ
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? NSHomeDirectory()
        let defaultPath = "\(documentsPath)/\(PathConstants.defaultFolderName)"
        
        self.saveLocation = UserDefaults.standard.string(forKey: UserDefaultsKeys.saveLocation) ?? defaultPath
        
        // デフォルトフォルダを作成
        createDefaultFolder()
        
        logger.log("SettingsManager initialized with: \(saveLocation)")
    }
    
    private func createDefaultFolder() {
        let url = URL(fileURLWithPath: saveLocation)
        
        logger.log("Attempting to create default folder: \(saveLocation)")
        logger.log("Full URL: \(url)")
        logger.log("Parent directory exists: \(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))")
        logger.log("Parent directory writable: \(FileManager.default.isWritableFile(atPath: url.deletingLastPathComponent().path))")
        
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            logger.log("Default folder created/verified: \(saveLocation)")
            
            // 権限をチェック
            let isWritable = FileManager.default.isWritableFile(atPath: saveLocation)
            logger.log("Folder is writable: \(isWritable)")
            
            // テストファイル作成で権限確認
            performWritePermissionTest(at: url)
            
        } catch {
            logger.log("Failed to create default folder: \(error)", level: .error)
            logger.log("Error details: \(error.localizedDescription)", level: .error)
        }
    }
    
    private func performWritePermissionTest(at url: URL) {
        let testFile = url.appendingPathComponent(PathConstants.testFileName)
        do {
            try PathConstants.testContent.write(to: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFile)
            logger.log("Write permission confirmed", level: .success)
        } catch {
            logger.log("Write permission test failed: \(error)", level: .error)
        }
    }
    
    func selectSaveLocation() {
        showingFolderPicker = true
    }
    
    func setSaveLocation(url: URL) {
        saveLocation = url.path
        logger.log("Save location updated: \(saveLocation)", level: .success)
    }
    
    func getSaveLocationURL() -> URL? {
        return URL(fileURLWithPath: saveLocation)
    }
    
    func isLocationWritable() -> Bool {
        return FileManager.default.isWritableFile(atPath: saveLocation)
    }
    
    func isSaveLocationConfigured() -> Bool {
        return !saveLocation.isEmpty && FileManager.default.fileExists(atPath: saveLocation)
    }
} 
 