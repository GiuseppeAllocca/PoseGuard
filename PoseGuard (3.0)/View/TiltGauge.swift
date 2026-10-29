//
//  TiltGauge.swift
//  PoseGuard (3.0)
//

import SwiftUI

/// Circular gauge for one head-tilt angle. The 15° alert threshold sits at the midpoint.
struct TiltGauge: View {
    let title: LocalizedStringResource
    let angle: Double

    private var degrees: Int { Int(abs(angle).rounded()) }

    var body: some View {
        VStack(spacing: 4) {
            // The caption below names the gauge, so its own label stays empty.
            Gauge(value: min(abs(angle), 30), in: 0...30) {
                EmptyView()
            } currentValueLabel: {
                Text("\(degrees)°")
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [Theme.brandGreen, Theme.gold, Theme.alertRed]))

            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text("\(degrees) degrees"))
    }
}
