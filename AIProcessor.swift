//
//  AIProcessor.swift
//  Assistant
//
//  Created by Jared Davidson on 11/4/24.
//

import SwiftUI
import Foundation
import OpenAI

/// Processes images using OpenAI's Vision API for analysis
final class ImageAnalysisProcessor {
    
    // MARK: - Types
    
    enum ProcessingError: LocalizedError {
        case imageConversionFailed
        case invalidImageData
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image to required format"
            case .invalidImageData:
                return "Invalid image data provided"
            case .apiError(let message):
                return "API Error: \(message)"
            }
        }
    }
    
    // MARK: - Properties
    
    private let openAIClient: any OpenAIProtocol
    private let imageQuality: CGFloat = 0.8
    
    // MARK: - Initialization
    
    init(apiKey: String? = nil) {
        let key = apiKey ?? ""
        self.openAIClient = OpenAI(apiToken: key)
    }
    
    // MARK: - Public Methods
    
    /// Analyzes an image with the provided query string
    /// - Parameters:
    ///   - image: The image to analyze
    ///   - requestString: The analysis request/query
    ///   - update: Closure to handle streaming updates
    func analyze(
        image: NSImage,
        requestString: String,
        update: @escaping (_ text: String) -> Void
    ) async throws {
        let pngData = try convertImageToPNGData(image)
        guard let processableImage = NSImage(data: pngData) else {
            throw ProcessingError.invalidImageData
        }
        
        try await sendAnalysisRequest(
            with: processableImage,
            requestString: requestString,
            update: update
        )
    }
    
    // MARK: - Private Methods
    
    private func convertImageToPNGData(_ image: NSImage) throws -> Data {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ProcessingError.imageConversionFailed
        }
        return pngData
    }
    
    private func convertImageToBase64(_ image: NSImage) throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let imageData = NSBitmapImageRep(cgImage: cgImage).representation(
                using: .jpeg,
                properties: [.compressionFactor: imageQuality]
              ) else {
            throw ProcessingError.imageConversionFailed
        }
        
        return "data:image/jpeg;base64," + imageData.base64EncodedString()
    }
    
    private func sendAnalysisRequest(
        with image: NSImage,
        requestString: String,
        update: @escaping (_ text: String) -> Void
    ) async throws {
        let base64Image = try convertImageToBase64(image)
        let request = createChatQuery(requestString: requestString, base64Image: base64Image)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var hasCompleted = false
            
            openAIClient.chatsStream(query: request) { result in
                switch result {
                case .success(let response):
                    if let content = response.choices.first?.delta.content {
                        update(content)
                    }
                case .failure(let error):
                    if !hasCompleted {
                        hasCompleted = true
                        continuation.resume(throwing: ProcessingError.apiError(error.localizedDescription))
                    }
                }
            } completion: { error in
                if !hasCompleted {
                    hasCompleted = true
                    if let error {
                        continuation.resume(throwing: ProcessingError.apiError(error.localizedDescription))
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    }
    
    private func createChatQuery(requestString: String, base64Image: String) -> ChatQuery {
        ChatQuery(
            messages: [
                .user(
                    .init(
                        content: .vision([
                            .chatCompletionContentPartTextParam(
                                .init(text: requestString)
                            ),
                            .chatCompletionContentPartImageParam(
                                .init(
                                    imageUrl: .init(
                                        url: base64Image,
                                        detail: .auto
                                    )
                                )
                            )
                        ])
                    )
                )
            ],
            model: .gpt4_o,
            stream: true
        )
    }
}

// MARK: - Protocols

protocol OpenAIClientProtocol {
    func chatsStream(
        query: ChatQuery,
        onResult: @escaping (Result<ChatStreamResult, Error>) -> Void,
        completion: @escaping (Error?) -> Void
    )
}
