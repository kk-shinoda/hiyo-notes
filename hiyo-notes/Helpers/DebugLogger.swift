import Foundation

class DebugLogger {
    static let shared = DebugLogger()
    private init() {}
    
    enum LogLevel {
        case info
        case success
        case warning
        case error
        
        var emoji: String {
            switch self {
            case .info: return "ℹ️"
            case .success: return "✅"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }
    
    func log(_ message: String, level: LogLevel = .info) {
        print("\(level.emoji) \(message)")
    }
    
    // 特定機能用のログメソッド
    func logWindowSetup(_ message: String) {
        log("Window: \(message)", level: .info)
    }
    
    func logFileOperation(_ message: String, success: Bool = true) {
        log("File: \(message)", level: success ? .success : .error)
    }
    
    func logGenreOperation(_ message: String) {
        log("Genre: \(message)", level: .info)
    }
    
    func logSaveOperation(_ message: String, success: Bool = true) {
        log("Save: \(message)", level: success ? .success : .error)
    }
} 