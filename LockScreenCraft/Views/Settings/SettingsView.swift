import SwiftUI

struct SettingsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationView {
            List {
                // General Settings Section
                Section(header: Text("General".localized)) {
                    NavigationLink(destination: LanguageSettingsView()) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                            Text("Language".localized)
                            Spacer()
                            Text(localizationManager.currentLanguage.displayName)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Theme (placeholder)
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.purple)
                            Text("Theme".localized)
                        }
                    }
                    
                    // Default Device (placeholder)
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "iphone")
                                .foregroundColor(.green)
                            Text("Default Device".localized)
                        }
                    }
                }
                
                // Instructions Section
                Section(header: Text("Instructions".localized)) {
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "book")
                                .foregroundColor(.orange)
                            Text("Quick Start Guide".localized)
                        }
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "textformat")
                                .foregroundColor(.orange)
                            Text("Text Formatting Tips".localized)
                        }
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.orange)
                            Text("Saving & Sharing".localized)
                        }
                    }
                }
                
                // Support Section
                Section(header: Text("Support".localized)) {
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "ant")
                                .foregroundColor(.red)
                            Text("Report a Bug".localized)
                        }
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.yellow)
                            Text("Feature Request".localized)
                        }
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                            Text("Contact Developer".localized)
                        }
                    }
                }
                
                // About Section
                Section(header: Text("About".localized)) {
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("App Info".localized)
                        }
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.gray)
                            Text("Version History".localized)
                        }
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "person.3")
                                .foregroundColor(.pink)
                            Text("Credits".localized)
                        }
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                            Text("Licenses".localized)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings".localized)
        }
    }
} 