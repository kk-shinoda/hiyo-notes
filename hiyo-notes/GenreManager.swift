//
//  GenreManager.swift
//  hiyo-notes
//
//  Created by kk-shinoda on 2025/06/01.
//

import SwiftUI
import Foundation

struct Genre: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let color: String? // Color名を文字列で保存
    let isDefault: Bool
    
    init(id: UUID = UUID(), name: String, color: String? = nil, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.color = color
        self.isDefault = isDefault
    }
}

class GenreManager: ObservableObject {
    @Published var genres: [Genre] = []
    @Published var currentGenre: Genre = Genre(name: "default", color: "blue", isDefault: true)
    @Published var errorMessage: String = ""
    @Published var errorId: UUID = UUID()
    
    private let logger = DebugLogger.shared
    private var errorTimer: Timer?
    
    // 設定キー定数
    private struct UserDefaultsKeys {
        static let savedGenres = "savedGenres"
        static let currentGenre = "currentGenre"
        static let genresInitialized = "genresInitialized"
    }
    
    // デフォルトジャンル定数
    private struct DefaultGenres {
        static let list = [
            Genre(name: "default", color: "blue", isDefault: true),
        ]
        static let defaultGenreName = "default"
    }
    
    // 利用可能な色のリスト
    private struct AvailableColors {
        static let list = [
            "blue", "green", "orange", "red", "purple", "pink", "yellow"
        ]
    }
    
    init() {
        // デフォルトジャンルを設定
        let defaultGenres = DefaultGenres.list
        
        // genresを初期化
        if let savedData = UserDefaults.standard.data(forKey: UserDefaultsKeys.savedGenres),
           let savedGenres = try? JSONDecoder().decode([Genre].self, from: savedData),
           !savedGenres.isEmpty {
            self.genres = savedGenres
        } else {
            self.genres = defaultGenres
        }
        
        // currentGenreを適切な値に更新
        self.currentGenre = self.genres.first { $0.name == DefaultGenres.defaultGenreName } ?? self.genres.first!
        
        // 保存された現在のジャンルがあれば更新
        loadSavedCurrentGenre()
        
        // すべてのプロパティが初期化された後に保存処理を実行
        if !UserDefaults.standard.bool(forKey: UserDefaultsKeys.genresInitialized) {
            saveGenres()
            saveCurrentGenre()
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.genresInitialized)
        }
        
        logger.logGenreOperation("GenreManager initialized with \(genres.count) genres")
        logger.logGenreOperation("Current genre: \(currentGenre.name)")
    }
    
    // UserDefaultsとジャンルデータをリセット（デバッグ用）
    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.savedGenres)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.currentGenre)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.genresInitialized)
        
        self.genres = DefaultGenres.list
        self.currentGenre = self.genres.first { $0.name == DefaultGenres.defaultGenreName } ?? self.genres.first!
        
        saveGenres()
        saveCurrentGenre()
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.genresInitialized)
        
        logger.logGenreOperation("Reset genres to defaults")
    }
    
    // 保存された現在のジャンルを読み込み
    private func loadSavedCurrentGenre() {
        guard let currentGenreData = UserDefaults.standard.data(forKey: UserDefaultsKeys.currentGenre),
              let savedCurrentGenre = try? JSONDecoder().decode(Genre.self, from: currentGenreData),
              self.genres.contains(where: { $0.id == savedCurrentGenre.id }) else {
            return
        }
        self.currentGenre = savedCurrentGenre
    }
    
    // ジャンルを変更
    func setCurrentGenre(_ genre: Genre) {
        currentGenre = genre
        saveCurrentGenre()
        logger.logGenreOperation("Genre changed to: \(genre.name)")
    }
    
    // 新しいジャンルを追加
    @discardableResult
    func addGenre(name: String, color: String? = nil) -> Bool {
        // ジャンル名の重複チェック
        if genres.contains(where: { $0.name.lowercased() == name.lowercased() }) {
            let message = "すでに存在するジャンル名です"
            showErrorMessage(message)
            logger.logGenreOperation("Cannot add genre: '\(name)' already exists")
            return false
        }
        
        let selectedColor = color ?? getNextAvailableColor()
        let newGenre = Genre(name: name, color: selectedColor, isDefault: false)
        genres.append(newGenre)
        saveGenres()
        logger.logGenreOperation("Added new genre: \(name) with color: \(selectedColor)")
        return true
    }
    
    // ジャンル名の重複チェック
    func isGenreNameDuplicate(_ name: String) -> Bool {
        return genres.contains(where: { $0.name.lowercased() == name.lowercased() })
    }
    
    // 次に利用可能な色を取得
    private func getNextAvailableColor() -> String {
        let usedColors = Set(genres.compactMap { $0.color })
        
        // 使用されていない色があれば最初のものを返す
        for color in AvailableColors.list {
            if !usedColors.contains(color) {
                return color
            }
        }
        
        // すべての色が使用されている場合は循環的に選択
        let colorIndex = genres.count % AvailableColors.list.count
        return AvailableColors.list[colorIndex]
    }
    
    // ジャンルを削除（デフォルトジャンルは削除不可）
    func deleteGenre(_ genre: Genre) {
        guard !genre.isDefault else {
            let message = "デフォルトジャンル「\(genre.name)」は削除できません"
            showErrorMessage(message)
            logger.logGenreOperation("Cannot delete default genre: \(genre.name)")
            return
        }
        
        genres.removeAll { $0.id == genre.id }
        
        // 削除されたジャンルが現在のジャンルの場合、defaultに変更
        if currentGenre.id == genre.id {
            currentGenre = genres.first { $0.name == DefaultGenres.defaultGenreName } ?? genres[0]
            saveCurrentGenre()
        }
        
        saveGenres()
        logger.logGenreOperation("Deleted genre: \(genre.name)")
    }
    
    // ジャンル名でジャンルを取得
    func getGenre(by name: String) -> Genre? {
        return genres.first { $0.name == name }
    }
    
    // ジャンルの色を取得
    func getGenreColor(_ genre: Genre) -> Color {
        guard let colorName = genre.color else { return .primary }
        
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        default: return .primary
        }
    }
    
    // ジャンルを保存
    private func saveGenres() {
        if let encoded = try? JSONEncoder().encode(genres) {
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.savedGenres)
        }
    }
    
    // 現在のジャンルを保存
    private func saveCurrentGenre() {
        if let encoded = try? JSONEncoder().encode(currentGenre) {
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.currentGenre)
        }
    }
    
    // エラーメッセージを表示
    private func showErrorMessage(_ message: String) {
        logger.logGenreOperation("Showing error message: \(message)")
        
        // 既存のタイマーをクリア
        errorTimer?.invalidate()
        
        // @Publishedプロパティで通知
        logger.logGenreOperation("🔄 Setting @Published properties...")
        DispatchQueue.main.async {
            self.errorMessage = message
            self.errorId = UUID()
            self.logger.logGenreOperation("🔄 @Published properties updated - errorMessage: \(self.errorMessage), errorId: \(self.errorId)")
        }
        
        // タイマーをメインスレッドで設定
        DispatchQueue.main.async {
            self.errorTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
                self?.clearError()
            }
        }
    }
    
    // エラーをクリア
    func clearError() {
        logger.logGenreOperation("Clearing error message")
        errorTimer?.invalidate()
        errorTimer = nil
        
        // @Publishedプロパティをクリア
        DispatchQueue.main.async {
            self.errorMessage = ""
            self.errorId = UUID()
            self.logger.logGenreOperation("🔄 @Published properties cleared")
        }
        
        logger.logGenreOperation("Error cleared")
    }
    
    // メモリリークを防ぐためのクリーンアップ
    deinit {
        errorTimer?.invalidate()
    }
    
    // 現在のエラー状態を確認（デバッグ用）
    func debugErrorState() {
        logger.logGenreOperation("Error state - errorTimer: \(errorTimer != nil)")
        logger.logGenreOperation("errorMessage: '\(errorMessage)', errorId: \(errorId)")
    }
} 