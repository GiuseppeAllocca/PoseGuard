//
//  Theme.swift
//  PoseGuard (3.0)
//

import SwiftUI

/// Shared design tokens, so every screen feels like part of the same app.
enum Theme {
    static let cardRadius: CGFloat = 24
    static let spring = Animation.spring(duration: 0.45, bounce: 0.25)

    // Original PoseGuard palette (#4CEF7E, #FFD700, #FF5252, #121212) on an always-dark interface.
    // The asset catalog adds light and Increase Contrast variants.
    static let brandGreen = Color(.accent)
    static let gold = Color(.gold)
    static let alertRed = Color(.alertRed)
    static let cardBackground = Color(.cardBackground)
}

extension View {
    /// Rounded card on the original near-black card color.
    func card() -> some View {
        padding()
            .frame(maxWidth: .infinity)
            .background(Theme.cardBackground, in: .rect(cornerRadius: Theme.cardRadius))
    }
}
