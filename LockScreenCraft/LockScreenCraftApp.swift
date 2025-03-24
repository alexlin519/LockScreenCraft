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
    
    init() {
        // Set up localization
        Bundle.setupLocalizationBundle()
    }
    
    var body: some Scene {
        WindowGroup {
            if splashFinished {
                TabView {
                    WallpaperGeneratorView()
                        .tabItem {
                            Label("Wallpaper".localized, systemImage: "photo")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings".localized, systemImage: "gearshape")
                        }
                }
                // Force refresh when language changes
                .id(localizationManager.refreshID)
            } else {
                SplashScreen(isFinished: $splashFinished)
            }
        }
    }
}
