//
//  NoteManager.swift
//  hiyo-notes
//
//  Created by kk-shinoda on 2025/06/01.
//

import SwiftUI
import UniformTypeIdentifiers

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    let filename: String
    let genre: String
    let content: String
    let createdAt: Date
    let modifiedAt: Date
    
    init(id: UUID = UUID(), filename: String, genre: String, content: String = "", createdAt: Date = Date(), modifiedAt: Date = Date()) {
        self.id = id
        self.filename = filename
        self.genre = genre
        self.content = content
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// 保存用のドキュメント
struct NoteDocument: FileDocument {
    var text: String
    var suggestedFilename: String
    
    init(text: String = "", suggestedFilename: String = "note.md") {
        self.text = text
        self.suggestedFilename = suggestedFilename
    }
    
    static var readableContentTypes: [UTType] { [.plainText, .text] }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
        suggestedFilename = "note.md"
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

class NoteManager: ObservableObject {
    @Published var currentNote: Note?
    @Published var notes: [Note] = []
    @Published var showingExporter = false
    @Published var showingFolderPicker = false
    @Published var documentToExport: NoteDocument?
    @Published var pendingSaveContent: String = ""
    @Published var needsInitialSetup = false
    
    private let settingsManager: SettingsManager
    private let genreManager: GenreManager
    private let logger = DebugLogger.shared
    
    // ファイル処理定数
    private struct FileConstants {
        static let defaultFilename = "001.md"
        static let fileExtension = ".md"
        static let filenamePattern = "%@_%03d.md"
        static let regexPattern = "%@_(\\d+)\\.md"
    }
    
    init(settingsManager: SettingsManager, genreManager: GenreManager) {
        self.settingsManager = settingsManager
        self.genreManager = genreManager
        
        // 初期化完了後にdefault_001.mdを作成
        DispatchQueue.main.async {
            self.ensureInitialNoteExists()
        }
        
        logger.log("NoteManager initialized")
    }
    
    // 初期ノートの確保
    private func ensureInitialNoteExists() {
        let defaultGenre = genreManager.currentGenre.name
        
        // 既存のノートがあるかチェック
        if let existingNote = findLatestNote(for: defaultGenre) {
            currentNote = existingNote
            logger.log("📝 Found existing note: \(existingNote.filename)")
        } else {
            // 初回起動時にdefault_001.mdを作成
            createNewNote()
        }
    }
    
    // 新規メモを作成（物理ファイルを即座に作成）
    func createNewNote() {
        let genre = genreManager.currentGenre
        let filename = generateFilename(for: genre.name)
        
        let newNote = Note(
            filename: filename,
            genre: genre.name,
            content: ""
        )
        
        // 物理ファイルを即座に作成
        createPhysicalFile(for: newNote)
        
        currentNote = newNote
        
        // メモリストに追加
        notes.append(newNote)
        notes.sort { $0.modifiedAt > $1.modifiedAt }
        
        logger.log("📝 Created new note with physical file: \(filename)")
    }
    
    // ジャンル変更時の処理
    func switchToGenre(_ genreName: String) {
        // 該当ジャンルの最新ノートを検索
        if let latestNote = findLatestNote(for: genreName) {
            currentNote = latestNote
            logger.log("📂 Switched to existing note: \(latestNote.filename)")
        } else {
            // 該当ジャンルのノートがない場合、001.mdを作成
            let filename = "\(genreName)_001.md"
            let newNote = Note(
                filename: filename,
                genre: genreName,
                content: ""
            )
            
            // 物理ファイルを即座に作成
            createPhysicalFile(for: newNote)
            
            currentNote = newNote
            notes.append(newNote)
            notes.sort { $0.modifiedAt > $1.modifiedAt }
            
            logger.log("📝 Created first note for genre: \(filename)")
        }
    }
    
    // 物理ファイルを作成
    private func createPhysicalFile(for note: Note) {
        guard let baseURL = settingsManager.getSaveLocationURL() else {
            logger.log("❌ No save location available")
            return
        }
        
        logger.log("📁 Creating physical file for: \(note.filename)")
        logger.log("📁 Base location: \(baseURL.path)")
        logger.log("📁 Genre: \(note.genre)")
        
        // ベースディレクトリの存在確認
        if !FileManager.default.fileExists(atPath: baseURL.path) {
            logger.log("❌ Base directory does not exist: \(baseURL.path)")
            do {
                try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
                logger.log("✅ Created base directory: \(baseURL.path)")
            } catch {
                logger.log("❌ Failed to create base directory: \(error)")
                return
            }
        } else {
            logger.log("✅ Base directory exists: \(baseURL.path)")
        }
        
        // ジャンル別ディレクトリを作成
        let genreURL = baseURL.appendingPathComponent(note.genre)
        logger.log("📂 Creating genre directory: \(genreURL.path)")
        
        do {
            try FileManager.default.createDirectory(at: genreURL, withIntermediateDirectories: true)
            logger.log("✅ Created/verified genre directory: \(genreURL.path)")
            
            // 権限チェック
            let isWritable = FileManager.default.isWritableFile(atPath: genreURL.path)
            logger.log("📝 Genre directory is writable: \(isWritable)")
            
        } catch {
            logger.log("❌ Failed to create genre directory: \(error)")
            logger.log("❌ Error details: \(error.localizedDescription)")
            return
        }
        
        // ファイルパスを作成
        let fileURL = genreURL.appendingPathComponent(note.filename)
        logger.log("📄 Creating file: \(fileURL.path)")
        
        // ファイルが存在しない場合のみ作成
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try note.content.write(to: fileURL, atomically: true, encoding: .utf8)
                logger.log("✅ Physical file created: \(fileURL.path)")
                
                // ファイル作成確認
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0
                    logger.log("✅ File creation confirmed, size: \(fileSize) bytes")
                } else {
                    logger.log("❌ File was not created successfully")
                }
                
            } catch {
                logger.log("❌ Failed to create physical file: \(error)")
                logger.log("❌ Error details: \(error.localizedDescription)")
            }
        } else {
            logger.log("ℹ️ Physical file already exists: \(fileURL.path)")
        }
    }
    
    // 最新のノートを検索
    private func findLatestNote(for genre: String) -> Note? {
        return notes.filter { $0.genre == genre }
                   .sorted { $0.modifiedAt > $1.modifiedAt }
                   .first
    }
    
    // メモを保存（上書き保存のみ）
    func saveNote(content: String) {
        guard let note = currentNote else {
            logger.log("⚠️ No current note to save")
            return
        }
        
        // 常に直接上書き保存を試行
        overwriteNote(note: note, content: content)
    }
    
    // ファイルを上書き保存
    private func overwriteNote(note: Note, content: String) {
        guard let baseURL = settingsManager.getSaveLocationURL() else {
            logger.log("❌ No save location available")
            return
        }
        
        let genreURL = baseURL.appendingPathComponent(note.genre)
        let fileURL = genreURL.appendingPathComponent(note.filename)
        
        logger.log("💾 Attempting to save to: \(fileURL.path)")
        
        // ジャンル別ディレクトリが存在しない場合は作成
        if !FileManager.default.fileExists(atPath: genreURL.path) {
            logger.log("📂 Genre directory doesn't exist, creating: \(genreURL.path)")
            do {
                try FileManager.default.createDirectory(at: genreURL, withIntermediateDirectories: true)
                logger.log("✅ Created genre directory: \(genreURL.path)")
            } catch {
                logger.log("❌ Failed to create genre directory: \(error)")
                return
            }
        }
        
        // ファイルを保存（存在しない場合は新規作成、存在する場合は上書き）
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                logger.log("✅ Note saved successfully: \(fileURL.path)")
            } else {
                logger.log("✅ Note created at new location: \(fileURL.path)")
            }
            
            // メモの内容を更新
            updateNoteAfterSave(note: note, content: content)
            
        } catch {
            logger.log("❌ Failed to save note: \(error)")
            logger.log("❌ Error details: \(error.localizedDescription)")
            logger.log("💡 Attempting to recreate file structure...")
            
            // エラーが発生した場合、物理ファイルとして再作成を試行
            createPhysicalFile(for: note)
            
            // 再度保存を試行
            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                logger.log("✅ Note saved after recreation: \(fileURL.path)")
                updateNoteAfterSave(note: note, content: content)
            } catch {
                logger.log("❌ Final save attempt failed: \(error)")
            }
        }
    }
    
    // 保存後のメモ更新処理
    private func updateNoteAfterSave(note: Note, content: String) {
        let updatedNote = Note(
            id: note.id,
            filename: note.filename,
            genre: note.genre,
            content: content,
            createdAt: note.createdAt,
            modifiedAt: Date()
        )
        
        currentNote = updatedNote
        
        // メモリストに追加または更新
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = updatedNote
        } else {
            notes.append(updatedNote)
        }
        
        // ソート
        notes.sort { $0.modifiedAt > $1.modifiedAt }
    }
    
    // fileExporter使用時の保存完了後の処理
    func onSaveCompleted() {
        guard let note = currentNote else { return }
        
        updateNoteAfterSave(note: note, content: pendingSaveContent)
        
        logger.log("✅ Note saved via file exporter: \(note.filename)")
        
        // リセット
        pendingSaveContent = ""
        documentToExport = nil
    }
    
    // メモを読み込み（fileImporter用）
    func loadNoteFromDocument(_ document: NoteDocument, filename: String) {
        let genre = genreManager.currentGenre.name
        
        let note = Note(
            filename: filename,
            genre: genre,
            content: document.text,
            createdAt: Date(),
            modifiedAt: Date()
        )
        
        currentNote = note
        
        // メモリストに追加
        if !notes.contains(where: { $0.filename == filename && $0.genre == genre }) {
            notes.append(note)
            notes.sort { $0.modifiedAt > $1.modifiedAt }
        }
        
        logger.log("✅ Note loaded: \(filename)")
    }
    
    // ファイル名を自動生成
    private func generateFilename(for genre: String) -> String {
        // 該当ジャンルの既存ファイル数から次の番号を決定
        let genreNotes = notes.filter { $0.genre == genre && $0.filename.hasPrefix(genre) }
        
        let maxNumber = genreNotes.compactMap { note -> Int? in
            let pattern = String(format: FileConstants.regexPattern, genre)
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: note.filename, range: NSRange(note.filename.startIndex..., in: note.filename)),
                  let numberRange = Range(match.range(at: 1), in: note.filename) else {
                return nil
            }
            return Int(note.filename[numberRange])
        }.max() ?? 0
        
        let nextNumber = maxNumber + 1
        return String(format: FileConstants.filenamePattern, genre, nextNumber)
    }
    
    // メモを削除
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        
        if currentNote?.id == note.id {
            currentNote = notes.first
        }
        
        logger.log("🗑️ Note deleted: \(note.filename)")
    }
    
    // 保存場所変更時の処理
    func handleSaveLocationChanged() {
        // 現在のノートが存在する場合、新しい場所で物理ファイルを作成
        if let currentNote = currentNote {
            logger.log("🔄 Save location changed, recreating current note at new location")
            createPhysicalFile(for: currentNote)
        }
        
        // 全てのノートを新しい場所で再作成（必要に応じて）
        for note in notes {
            if let baseURL = settingsManager.getSaveLocationURL() {
                let genreURL = baseURL.appendingPathComponent(note.genre)
                let fileURL = genreURL.appendingPathComponent(note.filename)
                
                // ファイルが存在しない場合のみ作成
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    logger.log("📝 Recreating note at new location: \(note.filename)")
                    createPhysicalFile(for: note)
                }
            }
        }
    }
} 