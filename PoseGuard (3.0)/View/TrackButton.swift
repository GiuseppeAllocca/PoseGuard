//
//  TrackButton.swift
//  PoseGuard (3.0)
//

import SwiftUI

/// The big circular start/stop button: gray while idle, green or red while tracking.
/// Tinted Liquid Glass on iOS 26+, the original gradient fill before that.
struct TrackButton: View {
    let isTracking: Bool
    let tint: Color
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let size: CGFloat = 210

    var body: some View {
        Button(action: action) {
            Image(systemName: "airpodspro")
                .font(.system(size: 76))
                // Black on the bright green keeps the glyph above 3:1 contrast; white elsewhere.
                .foregroundStyle(tint == Theme.brandGreen ? .black : .white)
                .symbolEffect(.breathe, isActive: isTracking && !reduceMotion)
                // A periodic bounce while idle hints that the button is tappable.
                .symbolEffect(.bounce, options: .repeat(.periodic(delay: 2.5)), isActive: !isTracking && !reduceMotion)
                .frame(width: size, height: size)
                .modifier(TrackButtonBackground(tint: tint))
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .shadow(color: isTracking ? tint.opacity(0.7) : .clear, radius: 24)
        .scaleEffect(isTracking ? 1.06 : 1)
        .accessibilityLabel(isTracking ? "Stop tracking" : "Start tracking")
    }
}

private struct TrackButtonBackground: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular.tint(tint).interactive(), in: .circle)
        } else {
            content.background(
                LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .circle
            )
        }
    }
}

#Preview {
    VStack(spacing: 60) {
        TrackButton(isTracking: false, tint: .gray) {}
        TrackButton(isTracking: true, tint: Theme.brandGreen) {}
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
}
