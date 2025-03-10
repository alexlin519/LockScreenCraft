import SwiftUI

struct SplashScreen: View {
    @State private var isLoading = true
    @State private var loadingMessage = "Initializing..."
    
    var body: some View {
        VStack {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("LockScreenCraft")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            if isLoading {
                VStack {
                    ProgressView()
                        .padding()
                    Text(loadingMessage)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)
            }
        }
        .task {
            // Initialize resources here
            // When done, set isLoading = false
        }
    }
} 