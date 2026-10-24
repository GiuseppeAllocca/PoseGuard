//
//  MyTipsView.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Tip Card Component
struct TipCard: View {
    let tip: PostureTip
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Tip icon
            VStack(alignment: .center) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "figure.walk")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Title and timestamp
                HStack {
                    Text(tip.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                // Description
                Text(tip.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.darkGray).opacity(0.2))
        .cornerRadius(16)
    }
}

// MARK: - Tips View
struct MyTipsView: View {
    @Binding var isShowing: Bool
    @StateObject private var viewModel = TipsViewModel()
    @State private var offset: CGFloat = -UIScreen.main.bounds.height
    @State private var isDismissing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var isCloseButtonFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if isShowing {
                    // Semi-transparent background overlay
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            hideView()
                        }
                        .accessibilityHidden(true)
                }
                
                // Tips panel
                VStack(spacing: 0) {
                    // Spazio aggiuntivo per evitare la sovrapposizione con la barra di stato
                    Spacer()
                        .frame(height: 40)
                        
                    // Header
                    HStack {
                        Text("Tips")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        Spacer()

                        Button(action: hideView) {
                            Label("Close tips", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                            .padding(.trailing, 16)
                            .padding(.top, 20)
                            .accessibilityFocused($isCloseButtonFocused)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 15)
                    .contentShape(Rectangle())
                    .gesture(dismissGesture)
                    
                    // Tips list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.tips) { tip in
                                TipCard(tip: tip)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                    
                    Rectangle()
                        .frame(width: 80, height: 4)
                        .cornerRadius(2)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("tipsDismissHandle")
                        .accessibilityHidden(true)
                        .gesture(dismissGesture)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 5)
                }
                .frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                .background(Color.black.opacity(0.99))
                .cornerRadius(25, corners: [.topLeft, .topRight])
                .offset(y: offset)
                .accessibilityElement(children: .contain)
                .accessibilityAddTraits(isShowing ? .isModal : [])
                .accessibilityHidden(!isShowing)
                .accessibilityAction(.escape, hideView)

            }
            .edgesIgnoringSafeArea(.all)
            .onChange(of: isShowing, initial: true) { _, newValue in
                if newValue {
                    showView()
                } else {
                    isCloseButtonFocused = false
                }
            }
            .onChange(of: reduceMotion) {
                if reduceMotion {
                    offset = isShowing ? (isDismissing ? -UIScreen.main.bounds.height : 0) : -UIScreen.main.bounds.height
                }
            }
        }
        .opacity(isShowing ? 1 : 0)
        .allowsHitTesting(isShowing && !isDismissing)
        .transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
    }
    
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .global)
            .onChanged { value in
                guard !isDismissing else { return }
                offset = min(0, value.translation.height)
            }
            .onEnded { value in
                guard !isDismissing else { return }
                if value.translation.height < -24 || value.velocity.height < -100 {
                    hideView()
                } else {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                    }
                }
            }
    }

    // Animation for showing the view
    private func showView() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0  // Impostato a 0 per visualizzare completamente il pannello dall'alto
        } completion: {
            if isShowing && !isDismissing { isCloseButtonFocused = true }
        }
    }
    
    // Animation for hiding the view
    private func hideView() {
        guard isShowing && !isDismissing else { return }
        isDismissing = true
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
            offset = -UIScreen.main.bounds.height
        } completion: {
            isCloseButtonFocused = false
            isShowing = false
            offset = -UIScreen.main.bounds.height
            isDismissing = false
        }
    }
}
