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
    
    private var window: NSWindow?
    
    func setupWindow() {
        // 現在のウィンドウを取得
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                self.window = window
                print("✅ Window reference established")
            } else {
                print("❌ No window found")
            }
        }
    }
    
    // 最前面表示をトグルするメソッドを追加
    func toggleAlwaysOnTop() {
        isAlwaysOnTop.toggle()
    }
    
    func setupWindowSizeAndPosition() {
        guard let window = self.window else {
            print("❌ Window not available for sizing")
            return
        }
        
        let windowWidth: CGFloat = 600
        let windowHeight: CGFloat = 400
        
        // 画面の中央に配置
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowX = screenFrame.midX - windowWidth / 2
        let windowY = screenFrame.midY - windowHeight / 2
        
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
