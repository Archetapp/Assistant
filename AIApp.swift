//
//  AIApp.swift
//  Assistant
//
//  Created by Jared Davidson on 11/4/24.
//

import SwiftUI
import HotKey

@main
struct AIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
