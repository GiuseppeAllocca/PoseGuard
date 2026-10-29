//
//  SessionDetailsView.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import SwiftUI
import Charts

struct SessionDetailsView: View {
    let day: DayData

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        QualityRing(value: day.averageQuality, lineWidth: 8)
                            .frame(width: 64, height: 64)
                            .overlay {
                                Text(day.averageQuality / 100, format: .percent.precision(.fractionLength(0)))
                                    .font(.footnote.bold())
                                    .monospacedDigit()
                                    .minimumScaleFactor(0.5)
                                    .padding(8)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.title)
                                .font(.title2.bold())

                            Text("Average quality: \(Int(day.averageQuality))%")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    // One stacked bar showing how the day's time splits across categories.
                    Chart(PostureCategory.allCases) { category in
                        BarMark(x: .value("Hours", day.seconds(for: category)))
                            .foregroundStyle(category.color.gradient)
                    }
                    .chartXAxis(.hidden)
                    .frame(height: 14)
                    .clipShape(.capsule)
                    .accessibilityHidden(true)

                    ForEach(PostureCategory.allCases) { category in
                        LabeledContent {
                            Text(day.seconds(for: category).durationText)
                                .monospacedDigit()
                        } label: {
                            Label {
                                Text(category.title)
                            } icon: {
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.color)
                            }
                        }
                    }
                }

                ForEach(PostureCategory.allCases) { category in
                    let sessions = day.sessions.filter { $0.category == category }
                    if !sessions.isEmpty {
                        Section {
                            ForEach(sessions) { session in
                                LabeledContent {
                                    QualityRing(value: Double(session.avgQuality), lineWidth: 4)
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Text("\(session.avgQuality)")
                                                .font(.caption.bold())
                                                .monospacedDigit()
                                                .minimumScaleFactor(0.5)
                                                .padding(4)
                                        }
                                } label: {
                                    Text("\(session.start.formatted(date: .omitted, time: .shortened)) – \(session.end.formatted(date: .omitted, time: .shortened))")
                                        .font(.headline)
                                        .monospacedDigit()
                                    Text("Duration: \(session.seconds.durationText)")
                                }
                            }
                        } header: {
                            Label {
                                Text(category.title)
                            } icon: {
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.color)
                            }
                        }
                    }
                }

                Section {
                    LabeledContent("Total sessions", value: day.sessions.count.formatted())
                    LabeledContent("Total time", value: day.totalSeconds.durationText)
                }
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
