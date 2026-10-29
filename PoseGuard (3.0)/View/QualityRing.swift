//
//  QualityRing.swift
//  PoseGuard (3.0)
//

import SwiftUI

/// Progress ring for a 0–100 quality score, colored by its posture category.
/// Size it with `frame`, and overlay any label.
struct QualityRing: View {
    let value: Double
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: value / 100)
                .stroke(
                    PostureCategory(quality: value).color.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2)
        .accessibilityElement()
        .accessibilityLabel("Quality")
        .accessibilityValue(Text(value / 100, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    QualityRing(value: 72, lineWidth: 12)
        .frame(width: 120, height: 120)
}
