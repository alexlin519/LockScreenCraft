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
            } else {
                SplashScreen(isFinished: $splashFinished)
            }
        }
    }
}
