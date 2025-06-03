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
            UserDefaults.standard.set(saveLocation, forKey: "saveLocation")
        }
    }
    
    @Published var showingFolderPicker = false
    
    init() {
        // デフォルトはDocumentsフォルダ
        let defaultPath = FileManager.default.urls(for: .documentDirectory, 
                                                 in: .userDomainMask).first?.path ?? NSHomeDirectory()
        self.saveLocation = UserDefaults.standard.string(forKey: "saveLocation") ?? defaultPath
    }
    
    func selectSaveLocation() {
        showingFolderPicker = true
    }
    
    func setSaveLocation(url: URL) {
        saveLocation = url.path
        print("✅ Save location updated: \(saveLocation)")
    }
    
    func getSaveLocationURL() -> URL? {
        return URL(fileURLWithPath: saveLocation)
    }
    
    func isLocationWritable() -> Bool {
        return FileManager.default.isWritableFile(atPath: saveLocation)
    }
} 
 