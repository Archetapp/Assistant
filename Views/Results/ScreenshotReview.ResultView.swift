//
//  ScreenshotReview.ResultView.swift
//  Assistant
//
//  Created by Jared Davidson on 11/6/24.
//

import SwiftUI
import AppKit
import Combine

struct ResultView: View {
    // MARK: - Types
    
    private enum Constants {
        static let textFieldHeight: CGFloat = 30
        static let cornerRadius: CGFloat = 8
        static let strokeWidth: CGFloat = 2
        static let contentPadding: CGFloat = 10
        static let resultCornerRadius: CGFloat = 15
    }
    
    // MARK: - Properties
    
    private let image: NSImage
    @State private var processor: ImageAnalysisProcessor? = nil
    
    @State private var inputText: String = ""
    @State private var text: String = ""
    @State private var isShowing: Bool = false
    @AppStorage("apiKey") private var storedApiKey: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Initialization
    
    init(image: NSImage) {
        self.image = image
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            queryInputField
            resultDisplay
        }
        .padding()
        .allowsHitTesting(true)
        .onAppear {
            processor = ImageAnalysisProcessor(apiKey: storedApiKey)
        }
    }
    
    // MARK: - View Components
    
    private var queryInputField: some View {
        HStack {
            TextField("What do you want?", text: $inputText)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .frame(height: Constants.textFieldHeight)
                .onSubmit(loadAnalysis)
                .onTapGesture {
                    isTextFieldFocused = true
                }
            
            if !inputText.isEmpty {
                clearButton
            }
        }
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .stroke(isTextFieldFocused ? Color.blue : Color.clear,
                       lineWidth: Constants.strokeWidth)
        )
    }
    
    private var clearButton: some View {
        Button(action: { inputText = "" }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
        }
        .buttonStyle(.plain)
    }
    
    private var resultDisplay: some View {
        ScrollView {
            Text(text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(Constants.contentPadding)
                .background(isShowing ? Color.black : Color.clear)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: Constants.resultCornerRadius))
        }
        .opacity(isShowing ? 1.0 : 0)
    }
    
    // MARK: - Actions
    
    private func loadAnalysis() {
        guard let processor = processor else { return }
        
        Task {
            text = ""
            isShowing = true
            do {
                _ = try await processor.analyze(
                    image: image,
                    requestString: inputText
                ) { value in
                    text += value
                }
            } catch {
                await MainActor.run {
                    text = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
