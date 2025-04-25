//
//  LockScreenCraftApp.swift
//  LockScreenCraft
//
//  Created by Alex Lin on 2025-01-25.
//

import SwiftUI

@main
struct LockScreenCraftApp: App {
    @State private var splashFinished = false
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedTab: Int = 0
    
    init() {
        // Set up localization
        Bundle.setupLocalizationBundle()
    }
    
    var body: some Scene {
        WindowGroup {
            if splashFinished {
                TabView(selection: $selectedTab) {
                    WallpaperGeneratorView()
                        .tabItem {
                            Label("Wallpaper".localized, systemImage: "photo")
                        }
                        .tag(0)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings".localized, systemImage: "gearshape")
                        }
                        .tag(1)
                }
                // Listen for tab change notifications
                .onReceive(NotificationCenter.default.publisher(for: .suggestPreviewTab)) { _ in
                    selectedTab = 1
                }
                // Force refresh when language changes
                .id(localizationManager.refreshID)
                // Add this to your TabView
                .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notification in
                    if let tabIndex = notification.object as? Int {
                        selectedTab = tabIndex
                    }
                }
            } else {
                SplashScreen(isFinished: $splashFinished)
            }
        }
    }
}
