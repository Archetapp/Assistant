//
//  ScreenshotReviewView.swift
//  Assistant
//
//  Created by Jared Davidson on 11/4/24.
//

import SwiftUI
import AppKit
import Combine

struct ScreenshotReviewView: View {
    // MARK: - Types
    
    private enum Constants {
        static let overlayOpacity: Double = 0.2
        static let cornerRadius: CGFloat = 20
        static let verticalOffset: CGFloat = 55
        static let shadowRadius: CGFloat = 30
        static let closeButtonSize: CGFloat = 24
        static let closeButtonOffset: CGFloat = 15
        static let resultViewWidth: CGFloat = 260
        static let resultViewMargin: CGFloat = 130
        static let resultViewOffset: CGFloat = 300
        
        enum Animation {
            static let imageAppearDuration: Double = 0.3
            static let answerDelay: Double = 0.2
            static let springResponse: Double = 0.6
            static let springDamping: Double = 0.8
        }
    }
    
    // MARK: - Properties
    
    let image: NSImage
    let rect: NSRect
    let screenFrame: NSRect
    
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingImage: Bool = false
    @State private var isShowingAnswer: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        let viewRect = convertToViewCoordinates(rect)
        
        ZStack {
            dismissableOverlay
            
            GeometryReader { geometry in
                ZStack {
                    screenshotImage(viewRect)
                    closeButton(viewRect)
                    resultView(geometry, viewRect)
                }
            }
        }
        .onAppear(perform: animateViewAppearance)
    }
    
    // MARK: - View Components
    
    private var dismissableOverlay: some View {
        Color.black
            .opacity(Constants.overlayOpacity)
            .edgesIgnoringSafeArea(.all)
            .allowsHitTesting(true)
            .contentShape(Rectangle())  // Makes entire overlay tappable
            .onTapGesture {
                dismiss()
            }
    }
    
    private func screenshotImage(_ viewRect: CGRect) -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: viewRect.width, height: viewRect.height)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .position(
                x: viewRect.midX,
                y: viewRect.midY - Constants.verticalOffset
            )
            .shadow(radius: isShowingImage ? Constants.shadowRadius : 0)
    }
    
    private func closeButton(_ viewRect: CGRect) -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: Constants.closeButtonSize))
                .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .position(
            x: viewRect.minX - Constants.closeButtonOffset,
            y: viewRect.minY - Constants.closeButtonOffset
        )
    }
    
    private func resultView(_ geometry: GeometryProxy, _ viewRect: CGRect) -> some View {
        ResultView(image: image)
            .frame(width: Constants.resultViewWidth, height: viewRect.height)
            .position(
                x: min(viewRect.maxX + 150, geometry.size.width - Constants.resultViewMargin),
                y: viewRect.midY
            )
            .offset(x: isShowingAnswer ? 0 : Constants.resultViewOffset)
            .allowsHitTesting(true)
    }
    
    // MARK: - Helpers
    
    private func convertToViewCoordinates(_ rect: NSRect) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: screenFrame.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
    
    private func animateViewAppearance() {
        withAnimation(.easeOut(duration: Constants.Animation.imageAppearDuration)) {
            isShowingImage = true
        }
        
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Constants.Animation.answerDelay
        ) {
            withAnimation(
                .spring(
                    response: Constants.Animation.springResponse,
                    dampingFraction: Constants.Animation.springDamping
                )
            ) {
                isShowingAnswer = true
            }
        }
    }
}
