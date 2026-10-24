//
//  Onboarding.swift
//  PoseGuard (3.0)
//
//  Created by Acri Stefano on 10/03/25.
//

import Foundation

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var navigateToTrackingView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    Spacer()
                    
                    Text("What's\nPoseGuard")
                        .font(.system(size: 40, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.bottom, 30)
                    
                    InstructionRow(
                        icon: "airpodspro",
                        title: "Connect your AirPods",
                        description: "The app'll use your AirPods' gyroscope to track your posture."
                    )
                    
                    InstructionRow(
                        icon: "hand.tap",
                        title: "Tap to start tracking",
                        description: "When the main button goes green the app is tracking your posture."
                    )
                    
                    InstructionRow(
                        icon: "lightbulb",
                        title: "Read posture tips",
                        description: "Open Tips for everyday posture advice."
                    )
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Sostituito il ProfileButton con una visualizzazione non cliccabile
                        ProfileIcon()
                        
                        Text("Motion data is processed on your device. PoseGuard stores your onboarding preference and uses local notifications. Continuous background monitoring is not guaranteed.")
                            .font(.system(size: 12))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
//                        Button("See how your data is managed...") {
//                            // Action
//                        }
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        hasCompletedOnboarding = true
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(15)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct InstructionRow: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.green)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

// Versione non cliccabile dell'omino
struct ProfileIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 40, height: 40)
                .foregroundColor(.green)
            
            Image(systemName: "person.fill")
                .foregroundColor(.black)
                .font(.system(size: 20))
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
