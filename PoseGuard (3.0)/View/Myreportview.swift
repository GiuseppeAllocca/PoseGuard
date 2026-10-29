//
//  Myreportview.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import SwiftUI

struct MyReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReportType: ReportType = .weekly

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Report", selection: $selectedReportType) {
                        ForEach(ReportType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch selectedReportType {
                    case .daily: PostureDailyChart()
                    case .weekly: PostureSessionChart()
                    }
                }
                .padding()
            }
            .navigationTitle("My Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
            .sensoryFeedback(.selection, trigger: selectedReportType)
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    MyReportView()
        .environment(SessionStore())
}
