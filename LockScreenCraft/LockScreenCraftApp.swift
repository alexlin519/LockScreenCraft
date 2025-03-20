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
    
    var body: some Scene {
        WindowGroup {
            if splashFinished {
                WallpaperGeneratorView()
            } else {
                SplashScreen(isFinished: $splashFinished)
            }
        }
    }
}
