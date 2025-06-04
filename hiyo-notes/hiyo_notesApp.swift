//
//  hiyo_notesApp.swift
//  hiyo-notes
//
//  Created by kk-shinoda on 2025/06/01.
//

import SwiftUI

@main
struct hiyo_notesApp: App {
    @StateObject private var windowManager = WindowManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(windowManager)
                .onAppear {
                    windowManager.setupWindow()
                }
        }
        .windowResizability(.contentSize)
        .commands {
            // 重複ウィンドウを防ぐためにコマンドメニューを制限
            CommandGroup(replacing: .newItem) {
                // 新規ウィンドウコマンドを無効化
            }
        }
    }
}

// ウィンドウ管理クラス
class WindowManager: ObservableObject {
    @Published var isAlwaysOnTop: Bool = false {
        didSet {
            updateWindowLevel()
        }
    }
    
    private var window: NSWindow?
    private let logger = DebugLogger.shared
    
    // ウィンドウ設定定数
    private struct WindowConstants {
        static let widthRatio: CGFloat = 0.25       // 画面幅の25%
        static let heightRatio: CGFloat = 1.0       // 画面高の100%
        static let rightMargin: CGFloat = 5         // 右端からの余白
    }
    
    func setupWindow() {
        DispatchQueue.main.async {
            // 最初のウィンドウのみを取得
            for window in NSApplication.shared.windows {
                if window.title.isEmpty || window.title.contains("hiyo-notes") {
                    self.window = window
                    self.setupWindowSizeAndPosition()
                    self.logger.logWindowSetup("Window reference established")
                    break
                }
            }
        }
    }
    
    func toggleAlwaysOnTop() {
        isAlwaysOnTop.toggle()
        logger.logWindowSetup("isAlwaysOnTop changed to: \(isAlwaysOnTop)")
    }
    
    private func setupWindowSizeAndPosition() {
        guard let window = self.window else {
            logger.logWindowSetup("Window not available for sizing")
            return
        }
        
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        
        // 画面幅の25%をウィンドウ幅として使用
        let windowWidth = screenFrame.width * WindowConstants.widthRatio
        let windowHeight = screenFrame.height  // 画面高の100%
        
        // 画面の右側に配置（右端から少し余白を持たせる）
        let margin: CGFloat = WindowConstants.rightMargin
        let windowX = screenFrame.maxX - windowWidth - margin
        let windowY = screenFrame.minY
        
        let newFrame = NSRect(
            x: windowX,
            y: windowY,
            width: windowWidth,
            height: windowHeight
        )
        
        window.setFrame(newFrame, display: true, animate: false)
        logger.logWindowSetup("Window positioned at right 25% (full height): width=\(Int(windowWidth)), height=\(Int(windowHeight))")
        logger.logWindowSetup("Window position: x=\(Int(windowX)), y=\(Int(windowY))")
    }
    
    private func updateWindowLevel() {
        guard let window = self.window else {
            return
        }
        
        DispatchQueue.main.async {
            if self.isAlwaysOnTop {
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                self.logger.logWindowSetup("Window set to floating level")
            } else {
                window.level = .normal
                window.collectionBehavior = [.canJoinAllSpaces]
                self.logger.logWindowSetup("Window set to normal level")
            }
        }
    }
}
