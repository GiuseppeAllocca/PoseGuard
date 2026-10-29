//
//  DayRow.swift
//  PoseGuard (3.0)
//

import SwiftUI

/// Tappable summary of one day, leading to its session details.
struct DayRow: View {
    let day: DayData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility text sizes the quality moves under the title instead of squeezing it.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 16))

        layout {
            QualityRing(value: day.averageQuality, lineWidth: 5)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(day.title)
                    .font(.headline)

                Text("^[\(day.sessions.count) session](inflect: true) · \(day.totalSeconds.durationText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }

            Text(day.averageQuality / 100, format: .percent.precision(.fractionLength(0)))
                .font(.headline)
                .fontDesign(.rounded)
                .monospacedDigit()

            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
