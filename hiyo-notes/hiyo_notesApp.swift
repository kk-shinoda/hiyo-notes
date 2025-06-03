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
                    // ウィンドウが表示された後にWindowManagerに参照を設定
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        windowManager.setupWindow()
                        windowManager.setupWindowSizeAndPosition()
                    }
                }
        }
        .windowResizability(.contentSize)
    }
}

// ウィンドウ管理クラス
class WindowManager: ObservableObject {
    @Published var isAlwaysOnTop: Bool = false {
        didSet {
            print("🔄 isAlwaysOnTop changed to: \(isAlwaysOnTop)")
            updateWindowLevel()
        }
    }
    
    private weak var window: NSWindow?
    
    func setupWindow() {
        // より確実にウィンドウを取得
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible }) else {
            print("❌ Failed to find window")
            return
        }
        
        self.window = window
        print("✅ Window setup completed: \(window)")
    }
    
    func setupWindowSizeAndPosition() {
        guard let window = self.window,
              let screen = NSScreen.main else {
            print("❌ Failed to get window or screen")
            return
        }
        
        let screenFrame = screen.visibleFrame
        
        // ウィンドウサイズを計算（横25%、縦100%）
        let windowWidth = screenFrame.width * 0.25
        let windowHeight = screenFrame.height
        
        // 右端に配置するためのX座標を計算
        let windowX = screenFrame.maxX - windowWidth
        let windowY = screenFrame.minY
        
        let newFrame = NSRect(
            x: windowX,
            y: windowY,
            width: windowWidth,
            height: windowHeight
        )
        
        DispatchQueue.main.async {
            window.setFrame(newFrame, display: true, animate: true)
            print("📐 Window positioned: width=\(windowWidth), height=\(windowHeight)")
            print("📍 Window position: x=\(windowX), y=\(windowY)")
        }
    }
    
    private func updateWindowLevel() {
        // ウィンドウ参照がない場合は再取得を試行
        if window == nil {
            print("❌ Window reference is nil, trying to find window...")
            setupWindow()
        }
        
        guard let window = self.window else {
            print("❌ Still no window found")
            return
        }
        
        DispatchQueue.main.async {
            if self.isAlwaysOnTop {
                print("🔝 Setting window to floating level")
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            } else {
                print("📱 Setting window to normal level")
                window.level = .normal
                window.collectionBehavior = [.canJoinAllSpaces]
            }
            
            // 現在のウィンドウレベルを確認
            print("📊 Current window level: \(window.level.rawValue)")
        }
    }
}
