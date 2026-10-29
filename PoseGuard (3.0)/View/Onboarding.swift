//
//  Onboarding.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var showPrivacyPolicy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Image(systemName: "figure.stand")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                        .frame(width: 96, height: 96)
                        .background(.tint.opacity(0.15), in: .circle)
                        .symbolEffect(.bounce, options: .nonRepeating)
                        .accessibilityHidden(true)

                    Text("Welcome to PoseGuard")
                        .font(.largeTitle.bold())
                        .fontDesign(.rounded)
                }
                .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 28) {
                    InstructionRow(
                        icon: "airpodspro",
                        title: "Connect your AirPods",
                        description: "PoseGuard uses your AirPods' motion sensors to follow your head position."
                    )

                    InstructionRow(
                        icon: "hand.tap",
                        title: "Tap to start tracking",
                        description: "The main button turns green while your posture is being tracked."
                    )

                    InstructionRow(
                        icon: "chart.bar.xaxis",
                        title: "Check your report",
                        description: "See your daily and weekly progress at a glance."
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 48)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Label("Your posture data never leaves your iPhone.", systemImage: "lock.shield")
                        .foregroundStyle(.secondary)

                    Button("Privacy Policy") { showPrivacyPolicy = true }
                        .bold()
                }
                .font(.footnote)

                continueButton
            }
            .padding(24)
            .background(.bar)
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }

    @ViewBuilder
    private var continueButton: some View {
        let button = Button(action: completeOnboarding) {
            Text("Continue")
                .bold()
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonBorderShape(.capsule)

        if #available(iOS 26, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
