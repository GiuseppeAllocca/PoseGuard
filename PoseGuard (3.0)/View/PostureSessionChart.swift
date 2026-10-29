//
//  PostureSessionChart.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import SwiftUI

struct PostureSessionChart: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedDay: DayData?

    var body: some View {
        let week = sessionStore.lastWeek()
        let recordedDays = week.filter { !$0.sessions.isEmpty }
        // Side by side normally, stacked at accessibility text sizes so words never break.
        let row = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))

        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Posture Analysis")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)

                    Text("Last 7 days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if recordedDays.isEmpty {
                    ContentUnavailableView(
                        "No sessions this week",
                        systemImage: "airpodspro",
                        description: Text("Start tracking to see your posture here.")
                    )
                } else {
                    WeekChart(week: week)

                    row {
                        ForEach(PostureCategory.allCases) { category in
                            CategoryTile(
                                category: category,
                                detail: Text("^[\(week.sessionCount(for: category)) session](inflect: true)")
                            )
                        }
                    }

                    Divider()

                    row {
                        StatView(title: "Time", value: week.totalSeconds.durationText, icon: "clock.fill")
                        StatView(title: "Quality", value: (week.averageQuality / 100).formatted(.percent.precision(.fractionLength(0))), icon: "chart.bar.fill")
                        StatView(title: "Sessions", value: week.sessionCount.formatted(), icon: "list.bullet")
                    }
                }
            }
            .card()

            if !recordedDays.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Days")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        ForEach(recordedDays.reversed()) { day in
                            Button {
                                selectedDay = day
                            } label: {
                                DayRow(day: day)
                            }
                            .buttonStyle(.plain)

                            if day != recordedDays.first {
                                Divider()
                                    .padding(.leading, 64)
                            }
                        }
                    }
                    .background(Theme.cardBackground, in: .rect(cornerRadius: Theme.cardRadius))
                }
            }
        }
        .sheet(item: $selectedDay, content: SessionDetailsView.init)
    }
}

#Preview {
    ScrollView {
        PostureSessionChart()
            .padding()
    }
    .environment(SessionStore())
}
