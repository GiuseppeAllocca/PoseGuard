//
//  StatView.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import SwiftUI

// MARK: - StatView
struct StatView: View {
    let title: LocalizedStringResource
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(height: 28)
                .accessibilityHidden(true)

            Text(value)
                .font(.title3.bold())
                .fontDesign(.rounded)
                .monospacedDigit()

            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
