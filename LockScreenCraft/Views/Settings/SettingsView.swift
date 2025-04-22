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
                    NavigationLink(destination: BugReportView()) {
                        HStack {
                            Image(systemName: "ant")
                                .foregroundColor(.red)
                            Text("Report a Bug".localized)
                        }
                    }
                    
                    NavigationLink(destination: FeatureRequestView()) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.yellow)
                            Text("Feature Request".localized)
                        }
                    }
                    
                    NavigationLink(destination: FAQView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("FAQ".localized)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/alexlin519/LockScreenCraft")!) {
                        HStack {
                            Image(systemName: "git")
                                .foregroundColor(.purple)
                            Text("GitHub Repository".localized)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                // About Section
                Section(header: Text("About".localized)) {
                    NavigationLink(destination: AppInfoView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("App Info".localized)
                        }
                    }
                    
                    NavigationLink(destination: VersionHistoryView()) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.gray)
                            Text("Version History".localized)
                        }
                    }
                    
                    NavigationLink(destination: CreditsView()) {
                        HStack {
                            Image(systemName: "person.3")
                                .foregroundColor(.pink)
                            Text("Credits".localized)
                        }
                    }
                    
                    NavigationLink(destination: LicensesView()) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                            Text("Licenses".localized)
                        }
                    }
                    
                    // Add direct developer links
                    Link(destination: URL(string: "https://github.com/alexlin519")!) {
                        HStack {
                            Image(systemName: "git")
                                .foregroundColor(.black)
                            Text("Developer GitHub".localized)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings".localized)
        }
        .id(localizationManager.refreshID)
    }
} 