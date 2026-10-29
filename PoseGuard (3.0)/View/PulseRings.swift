//
//  PulseRings.swift
//  PoseGuard (3.0)
//

import SwiftUI

/// Rings rippling outward from the track button, staggered one second apart over a 3-second cycle.
/// Callers hide it when Reduce Motion is on.
struct PulseRings: View {
    let color: Color
    var count = 3

    // Driven by the clock, not by a repeatForever animation: that one also captured the first
    // layout and replayed the move from the top-left corner on every cycle.
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    let progress = Self.easeOut((time - Double(index)).truncatingRemainder(dividingBy: 3) / 3)
                    Circle()
                        .fill(color.opacity(0.15))
                        .stroke(color.opacity(0.4), lineWidth: 2)
                        .frame(width: 210, height: 210)
                        .scaleEffect(1 + 1.2 * progress)
                        .opacity(1 - progress)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func easeOut(_ progress: Double) -> Double {
        1 - (1 - progress) * (1 - progress)
    }
}
