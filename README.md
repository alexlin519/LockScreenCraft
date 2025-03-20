# LockScreenCraft Debug Features

This branch preserves the development and testing features that were removed from the App Store submission version of LockScreenCraft.

## 📋 Table of Contents

- [Overview](#-overview)
- [Debug Features in Detail](#-debug-features-in-detail)
  - [Text File Processing System](#-text-file-processing-system)
  - [Desktop File Saving](#-desktop-file-saving)
  - [Debug UI Elements](#-debug-ui-elements)
  - [Console Logging](#-console-logging)
- [Implementation Guide](#-implementation-guide)
- [Usage Instructions](#-usage-instructions)

## 🔍 Overview

The debug features in LockScreenCraft help with:
- Batch processing multiple text inputs
- Saving wallpapers directly to desktop
- Tracking progress through console logs
- Testing with detailed UI feedback

All debug features use `#if DEBUG` conditional compilation to ensure they're excluded from release builds.

## 🛠️ Debug Features in Detail

### 📝 Text File Processing System

**Purpose**: Process multiple text files automatically to generate batches of wallpapers.

**Key Methods**:

```

// WallpaperGeneratorViewModel.swift

// Main entry point for batch processing
func startProcessingAllFiles() async {
    // Loads all text files from bundle
    await loadAvailableTextFiles()
    
    if !availableTextFiles.isEmpty {
        currentFileIndex = 0
        currentProcessingFile = availableTextFiles[0]
        
        // Load first file and generate
        await loadTextFromFile(currentProcessingFile!)
        await generateWallpaper()
        
        // Switch to Preview tab
        selectedTab = 1
    }
}

// Loads all text files from bundle
func loadAvailableTextFiles() async {
    guard let bundleURL = Bundle.main.resourceURL else { return }
    
    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: bundleURL, 
            includingPropertiesForKeys: nil
        )
        
        availableTextFiles = fileURLs
            .filter { $0.pathExtension == "txt" }
            .map { $0.lastPathComponent }
            
        print("📚 Found \(availableTextFiles.count) text files")
    } catch {
        print("❌ Error loading text files: \(error)")
    }
}

// Loads and processes single text file
func loadTextFromFile(_ filename: String) async {
    guard let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".txt", with: ""), 
                                   withExtension: "txt") else {
        return
    }
    
    do {
        let content = try String(contentsOf: url)
        await MainActor.run {
            inputText = content
        }
    } catch {
        print("❌ Error loading text: \(error)")
    }
}

// Process the next file after saving current
func saveAndProcessNext() async {
    await saveWallpaperToPhotos()
    
    // Also save to desktop in debug mode
    if let _ = try? await saveWallpaperToDesktop() {
        print("💾 Saved to desktop")
    }
    
    // Process next file if available
    currentFileIndex += 1
    if currentFileIndex < availableTextFiles.count {
        currentProcessingFile = availableTextFiles[currentFileIndex]
        await loadTextFromFile(currentProcessingFile!)
        await generateWallpaper()
    } else {
        print("✅ Processed all \(availableTextFiles.count) files")
        currentProcessingFile = nil
    }
}
```

**Required Properties**:

```

// WallpaperGeneratorViewModel.swift - Add these properties
@Published var availableTextFiles: [String] = []
@Published var currentProcessingFile: String?
@Published var currentFileIndex: Int = 0
```

### 💾 Desktop File Saving

**Purpose**: Save generated wallpapers directly to Mac desktop for easy access during development.

**Implementation**:

```

// WallpaperGeneratorViewModel.swift

func saveWallpaperToDesktop() async throws -> URL? {
    #if os(macOS)
    guard let homeURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop") else {
        return nil
    }
    
    guard let image = generatedImage else { return nil }
    
    // Create filename with timestamp and device
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    let timestamp = formatter.string(from: Date())
    let device = selectedDevice.modelName.replacingOccurrences(of: " ", with: "_")
    let filename = "Wallpaper_\(device)_\(timestamp).png"
    
    let fileURL = homeURL.appendingPathComponent(filename)
    
    // Save image to desktop
    if let data = image.pngData() {
        try data.write(to: fileURL)
        print("💾 Saved to \(fileURL.path)")
        return fileURL
    }
    #endif
    
    return nil
}
```

### 🖥️ Debug UI Elements

**Process All Files Button**:

```

// WallpaperGeneratorView.swift - In ActionButtonsSection
#if DEBUG
Button(action: {
    Task {
        await viewModel.startProcessingAllFiles()
    }
}) {
    Label("Process All Files", systemImage: "text.badge.plus")
        .frame(maxWidth: .infinity)
}
.buttonStyle(.bordered)
#endif
```

**File Progress Indicator**:

```

// WallpaperGeneratorView.swift - In PreviewTabView toolbar
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        #if DEBUG
        if let currentFile = viewModel.currentProcessingFile {
            Text("\(currentFile) (\(viewModel.currentFileIndex + 1)/\(viewModel.availableTextFiles.count))")
                .foregroundStyle(.secondary)
        }
        #endif
    }
    
    // Other toolbar items...
}
```

### 📊 Console Logging

Debug prints are scattered throughout the code to provide feedback:

```

// Example logging points
print("📚 Found \(availableTextFiles.count) text files")
print("📄 Loaded text from \(filename)")
print("🖼️ Generated wallpaper for \(selectedDevice.modelName)")
print("💾 Saved to desktop: \(fileURL.path)")
print("⏭️ Moving to next file: \(currentProcessingFile!)")
print("✅ Processed all \(availableTextFiles.count) files")
```

## 📖 Implementation Guide

To reimplement these features in future versions:

1. **Add Debug Properties to ViewModel**:
   ```swift
   #if DEBUG
   @Published var availableTextFiles: [String] = []
   @Published var currentProcessingFile: String?
   @Published var currentFileIndex: Int = 0
   #endif
   ```

2. **Add Debug Methods**:
   ```swift
   #if DEBUG
   func startProcessingAllFiles() async { /* ... */ }
   func loadAvailableTextFiles() async { /* ... */ }
   func loadTextFromFile(_ filename: String) async { /* ... */ }
   func saveWallpaperToDesktop() async throws -> URL? { /* ... */ }
   #endif
   ```

3. **Add Debug UI Elements**:
   ```swift
   #if DEBUG
   // Add Process All Files button
   // Add file progress indicator
   #endif
   ```

4. **Update saveAndProcessNext**:
   ```swift
   func saveAndProcessNext() async {
       await saveWallpaperToPhotos()
       
       #if DEBUG
       // Desktop saving
       // Next file processing
       #endif
   }
   ```

5. **Add MainActor Attribute**:
   ```swift
   @MainActor
   class WallpaperGeneratorViewModel: ObservableObject {
       // Implementation...
   }
   ```

## 📱 Usage Instructions

### Setting Up Text Files:

1. Create text files with your desired wallpaper content
2. Add them to your Xcode project:
   - File → Add Files to "LockScreenCraft"
   - Select your text files
   - Ensure "Copy items if needed" is checked
   - Make sure your app target is selected

### Text File Format:

```

This is line one
This is line two

Use blank lines for spacing
\\ Backslashes for line breaks
// Forward slashes also work
```

### Running Batch Processing:

1. Run the app in Xcode (DEBUG mode)
2. Go to Generate tab
3. Click "Process All Files" button
4. App will:
   - Load first text file
   - Generate wallpaper
   - Switch to Preview tab
5. In Preview tab:
   - Check the generated wallpaper
   - See which file is being processed in navigation bar
   - Click "Save & Next" to continue
6. Process continues until all files are complete

---

*Created: March 2024* 