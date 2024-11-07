//
//  OnboardingView.swift
//  Assistant
//
//  Created by Jared Davidson on 11/6/24.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var apiKey: String
    @State private var temporaryKey: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
            
            Text("Welcome")
                .font(.headline)
            
            Text("Please enter your OpenAI API key to begin")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                SecureField("Enter API key", text: $temporaryKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if showError {
                    Text("Please enter a valid API key")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            
            Button("Continue") {
                validateAndSaveKey()
            }
            .disabled(temporaryKey.isEmpty)
            
            Link("Need an API key?",
                 destination: URL(string: "https://platform.openai.com/api-keys")!)
            .font(.caption)
            .padding(.top)
        }
        .padding()
    }
    
    private func validateAndSaveKey() {
        if !temporaryKey.isEmpty {
            apiKey = temporaryKey
            showError = false
        } else {
            showError = true
        }
    }
}
