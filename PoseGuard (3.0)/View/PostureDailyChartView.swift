//
//  PostureDailyChartView.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import SwiftUI

// MARK: - PostureDailyChart Component
struct PostureDailyChart: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Side by side normally, stacked at accessibility text sizes so words never break.
        let row = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))

        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Posture")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)

                Text("Daily statistics")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let today = sessionStore.today() {
                QualityRing(value: today.averageQuality, lineWidth: 18)
                    .frame(width: 180, height: 180)
                    .overlay {
                        VStack(spacing: 2) {
                            Text(today.averageQuality / 100, format: .percent.precision(.fractionLength(0)))
                                .font(.largeTitle.bold())
                                .fontDesign(.rounded)
                                .monospacedDigit()
                                .minimumScaleFactor(0.5)

                            Text("Quality")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                row {
                    ForEach(PostureCategory.allCases) { category in
                        let seconds = today.seconds(for: category)
                        CategoryTile(
                            category: category,
                            detail: Text("\(seconds.durationText) · \(seconds / today.totalSeconds, format: .percent.precision(.fractionLength(0)))")
                        )
                    }
                }

                Divider()

                row {
                    StatView(title: "Time", value: today.totalSeconds.durationText, icon: "clock.fill")
                    StatView(title: "Quality", value: (today.averageQuality / 100).formatted(.percent.precision(.fractionLength(0))), icon: "chart.bar.fill")
                    StatView(title: "Sessions", value: today.sessions.count.formatted(), icon: "list.bullet")
                }
            } else {
                ContentUnavailableView(
                    "No data for today",
                    systemImage: "airpodspro",
                    description: Text("Wear your AirPods to start tracking your posture")
                )
            }
        }
        .card()
    }
}

#Preview {
    ScrollView {
        PostureDailyChart()
            .padding()
    }
    .environment(SessionStore())
}
