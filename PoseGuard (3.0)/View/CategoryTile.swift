//
//  CategoryTile.swift
//  PoseGuard (3.0)
//

import SwiftUI

/// Small tinted tile showing one posture category and a detail line.
struct CategoryTile: View {
    let category: PostureCategory
    let detail: Text

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundStyle(category.color)
                .accessibilityHidden(true)

            Text(category.title)
                .font(.subheadline.bold())

            detail
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(category.color.opacity(0.15), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}
