//
//  Posturesession.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import Foundation

/// One recorded tracking session.
struct PostureSession: Identifiable, Equatable, Codable {
    var id = UUID()
    let start: Date
    let end: Date
    /// Percentage (0–100) of the session spent in a correct posture.
    let avgQuality: Int

    var seconds: TimeInterval { end.timeIntervalSince(start) }
    var category: PostureCategory { PostureCategory(quality: Double(avgQuality)) }
}

extension TimeInterval {
    /// Compact duration such as "1h 25m" or "4m 10s".
    var durationText: String {
        Duration.seconds(self).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow, maximumUnitCount: 2))
    }
}
