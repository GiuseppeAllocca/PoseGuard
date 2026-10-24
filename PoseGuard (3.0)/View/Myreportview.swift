//
//  Myreportview.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import Foundation
import SwiftUI
import UIKit

struct MyReportView: View {
    @Binding var isShowing: Bool
    @State private var offset: CGFloat = UIScreen.main.bounds.height
    @State private var selectedReportType: ReportType = .weekly
    
    // Colori principali
    private let bgColor = Color.black
    private let accentColor = Color(hex: "4CEF7E") // Verde brillante
    private let textColor = Color.white
    private let secondaryTextColor = Color.gray
    private let cardBgColor = Color(hex: "121212") // Grigio molto scuro
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                if isShowing {
                    // Semi-transparent background overlay
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            hideView()
                        }
                }
                
                // Main report content
                VStack(spacing: 0) {
                    // Drag indicator
                    Rectangle()
                        .frame(width: 60, height: 5)
                        .cornerRadius(2.5)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 15)
                        .padding(.bottom, 10)
                    
                    // Title section
                    HStack {
                        Text("My Report")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    
                    // Report Type Selector
                    ReportTypeSelector(
                        selectedType: $selectedReportType,
                        accentColor: accentColor,
                        textColor: textColor,
                        backgroundColor: cardBgColor
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 15)
                    
                    // Content area with selected chart
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            if selectedReportType == .weekly {
                                PostureSessionChart()
                                    .padding(.horizontal, 16)
                            } else {
                                PostureDailyChart()
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.85)
                .background(Color(UIColor.darkGray).opacity(0.99))
                .cornerRadius(25, corners: [.topLeft, .topRight])
                .offset(y: offset)
                .gesture(
                    // Gesture for dragging the panel
                    DragGesture(minimumDistance: 5, coordinateSpace: .global)
                        .onChanged { value in
                            // Only allow dragging down
                            let newOffset = value.translation.height
                            if newOffset > 0 {
                                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.3)) {
                                    offset = newOffset
                                }
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 50 || value.velocity.height > 100 {
                                hideView()
                            } else {
                                // Otherwise snap back
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = 0
                                }
                            }
                        }
                )
            }
            .edgesIgnoringSafeArea(.all)
        }
        .opacity(isShowing ? 1 : 0)
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                showView()
            }
        }
    }
    
    // Animation for showing the view
    private func showView() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
        }
    }
    
    // Animation for hiding the view
    private func hideView() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = UIScreen.main.bounds.height
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShowing = false
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        
        MyReportView(isShowing: .constant(true))
    }
}
