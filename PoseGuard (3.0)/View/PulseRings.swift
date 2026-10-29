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

    @State private var isExpanded = false

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(color.opacity(0.15))
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .frame(width: 210, height: 210)
                    .scaleEffect(isExpanded ? 2.2 : 1)
                    .opacity(isExpanded ? 0 : 1)
                    .animation(
                        .easeOut(duration: 3)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index)),
                        value: isExpanded
                    )
            }
        }
        .onAppear { isExpanded = true }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
