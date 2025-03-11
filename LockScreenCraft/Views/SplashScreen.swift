import SwiftUI

struct SplashScreen: View {
    @State private var isLoading = true
    @State private var progress: Float = 0.0
    @State private var loadingMessage = "Initializing..."
    @State private var loadingTask = ""
    @Binding var isFinished: Bool
    
    // Define our loading tasks for tracking
    private let loadingTasks = [
        "Loading fonts...",
        "Scanning background images...",
        "Preparing text files...",
        "Setting up templates...",
        "Initializing renderer..."
    ]
    
    var body: some View {
        VStack(spacing: 25) {
            // App logo/icon
            Image(systemName: "text.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            // App name with subtle animation
            Text("LockScreenCraft")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Spacer()
                .frame(height: 20)
            
            // Loading progress indicator
            VStack(spacing: 15) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                            .frame(width: CGFloat(progress) * geometry.size.width, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)
                
                // Current task text
                Text(loadingTask)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeIn, value: loadingTask)
                    .transition(.opacity)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .task {
            // Simulate or actually track initialization tasks
            await loadResources()
        }
    }
    
    private func loadResources() async {
        // Initialize resources with progress tracking
        for (index, task) in loadingTasks.enumerated() {
            // Update task display
            loadingTask = task
            
            // Simulate or actually perform the task
            await performTask(index)
            
            // Update progress
            progress = Float(index + 1) / Float(loadingTasks.count)
        }
        
        // Allow a moment to see 100% completion
        loadingTask = "Ready!"
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        
        // Signal completion
        isFinished = true
    }
    
    private func performTask(_ taskIndex: Int) async {
        // Simulate task time - in real implementation, we'd call actual initialization methods
        let taskDuration = UInt64(0.5 * 1_000_000_000) // 0.5 seconds in nanoseconds
        try? await Task.sleep(nanoseconds: taskDuration)
        
        // In the real implementation, we'll call the actual loading methods:
        // switch taskIndex {
        // case 0: await loadFonts()
        // case 1: await scanBackgrounds()
        // ...and so on
        // }
    }
} 