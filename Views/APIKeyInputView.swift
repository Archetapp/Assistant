//
//  APIKeyInputView.swift
//  Assistant
//
//  Created by Jared Davidson on 11/6/24.
//

import SwiftUI

struct APIKeyInputView: View {
    @Binding var apiKey: String
    @Binding var isEditing: Bool
    @State private var temporaryKey: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Update API Key")
                .font(.headline)
            
            SecureField("API Key", text: $temporaryKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    isEditing = false
                }
                
                Button("Save") {
                    if !temporaryKey.isEmpty {
                        apiKey = temporaryKey
                    }
                    isEditing = false
                }
                .disabled(temporaryKey.isEmpty)
            }
        }
        .padding()
    }
}

