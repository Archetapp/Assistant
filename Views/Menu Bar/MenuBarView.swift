//
//  MenuBarView.swift
//  Assistant
//
//  Created by Jared Davidson on 11/6/24.
//

import SwiftUI
import HotKey

struct MenuBarView: View {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("apiKey") private var storedApiKey: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var temporaryKey: String = ""
    @State private var showError: Bool = false

    var apiKey: String {
        return storedApiKey
    }
    
    init() {
    
    }
    
    var body: some View {
        Group {
            if apiKey.isEmpty {
                OnboardingView(apiKey: $storedApiKey)
            } else {
                MainMenuView(apiKey: apiKey, storedApiKey: $storedApiKey)
            }
        }
    }
}

