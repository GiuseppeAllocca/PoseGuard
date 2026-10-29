//
//  WeekChart.swift
//  PoseGuard (3.0)
//

import SwiftUI
import Charts

/// Stacked daily bars of time per posture category, with a thin gap between segments
/// so adjacent colors stay distinguishable.
struct WeekChart: View {
    let week: [DayData]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.calendar) private var calendar

    var body: some View {
        let maxHours = (week.map(\.totalSeconds).max() ?? 0) / 3600
        // Minutes read better than "0h" while every day is under an hour.
        let useMinutes = maxHours < 1
        let scale = useMinutes ? 60.0 : 1.0
        // Gap between stacked segments, proportional to the tallest bar.
        let gap = maxHours * scale * 0.012
        // Always span the whole week, even when only some days have sessions.
        let firstDay = week.first?.date ?? .now
        let lastDay = calendar.date(byAdding: .day, value: 1, to: week.last?.date ?? .now) ?? .now

        Chart {
            ForEach(week) { day in
                ForEach(day.stack, id: \.category) { segment in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        yStart: .value("Time", segment.start * scale),
                        yEnd: .value("Time", max(segment.start * scale, segment.end * scale - gap))
                    )
                    .foregroundStyle(segment.category.color.gradient)
                    .accessibilityLabel("\(day.title), \(String(localized: segment.category.title))")
                    .accessibilityValue(day.seconds(for: segment.category).durationText)
                }
            }
        }
        .chartXScale(domain: firstDay...lastDay)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(
                    format: dynamicTypeSize.isAccessibilitySize ? .dateTime.weekday(.narrow) : .dateTime.weekday(.abbreviated),
                    centered: true
                )
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text("\(amount, format: .number.precision(.fractionLength(0...1)))\(useMinutes ? "m" : "h")")
                    }
                }
            }
        }
        .frame(height: 220)
    }
}
