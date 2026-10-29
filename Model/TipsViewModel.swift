//
//  TipsViewModel.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import Foundation
import SwiftUI

// MARK: - Model
struct PostureTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - ViewModel
class TipsViewModel: ObservableObject {
    @Published var tips: [PostureTip] = []
    
    init() {
        loadDemoTips()
    }
    
    func loadDemoTips() {
        tips = [
            PostureTip(
                icon: "figure.stand",
                title: NSLocalizedString("Keep your shoulders back!", comment: ""),
                description: NSLocalizedString("Avoid slouching and gently roll your shoulders back to open up your chest.", comment: "")
            ),
            PostureTip(
                icon: "display",
                title: NSLocalizedString("Adjust your screen height!", comment: ""),
                description: NSLocalizedString("Ensure your screen is at eye level to prevent neck strain.", comment: "")
            ),
            PostureTip(
                icon: "figure.walk",
                title: NSLocalizedString("Take breaks regularly!", comment: ""),
                description: NSLocalizedString("Stand up, stretch, and move around every 30-60 minutes to relieve tension.", comment: "")
            ),
            PostureTip(
                icon: "figure.core.training",
                title: NSLocalizedString("Engage your core!", comment: ""),
                description: NSLocalizedString("Strengthening your core muscles helps support your spine and improves posture.", comment: "")
            ),
            PostureTip(
                icon: "shoeprints.fill",
                title: NSLocalizedString("Keep your feet flat on the ground!", comment: ""),
                description: NSLocalizedString("When sitting, make sure your feet are fully supported and not dangling.", comment: "")
            )
        ]
    }
}
