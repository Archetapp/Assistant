//
//  MainMenuView.swift
//  Assistant
//
//  Created by Jared Davidson on 11/6/24.
//

import SwiftUI

struct MainMenuView: View {
    let apiKey: String
    @Binding var storedApiKey: String
    @State private var isEditingKey: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("AI Assistant")
                    .font(.headline)
                Spacer()
                Button(action: {
                    isEditingKey.toggle()
                }) {
                    Image(systemName: "key.fill")
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            if isEditingKey {
                APIKeyInputView(apiKey: $storedApiKey, isEditing: $isEditingKey)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Instructions Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("How to Use", systemImage: "info.circle")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InstructionRow(
                                icon: "command",
                                text: "⇧⌘A to capture screen area"
                            )
                            
                            InstructionRow(
                                icon: "cursorarrow.click.2",
                                text: "Select area to analyze"
                            )
                            
                            InstructionRow(
                                icon: "text.bubble",
                                text: "AI will analyze selection"
                            )
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Status Section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Status", systemImage: "circle.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("API Key: Connected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Quit Button at the bottom
                    MenuButton(title: "Quit", systemImage: "power") {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Spacer()
        }
        .frame(width: 300, height: 300)
    }
}

// Auxiliary

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

struct MenuButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
