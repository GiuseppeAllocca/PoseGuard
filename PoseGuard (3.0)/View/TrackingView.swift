import Foundation
import SwiftUI

struct TrackingView: View {
    @State private var showTips = false
    @State private var pulseAnimation = false
    @State private var waveAnimation = false
    @State private var rotationAnimation = false
    @State private var showReport = false
    @State private var panOffset: CGFloat = 0
    @State private var previousPanOffset: CGFloat = 0
    
    @Binding var hasCompletedOnboarding: Bool
    // For sound wave animation
    let waveCount = 5
    
    // Add PostureMonitorModel instance
    @StateObject private var postureMonitor = PostureMonitorModel.makeForTrackingView()
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AccessibilityFocusState private var isTipsButtonFocused: Bool

    private var isTracking: Bool { postureMonitor.isMonitoring }

    private var trackingStatus: String {
        if postureMonitor.isStarting {
            return NSLocalizedString("Waiting for headphone motion…", comment: "")
        }
        return isTracking ? postureMonitor.postureMessage : NSLocalizedString("Tap To Track", comment: "")
    }

    private var trackingActionLabel: LocalizedStringKey {
        if postureMonitor.isStarting { return "Cancel starting" }
        return isTracking ? "Stop tracking" : "Start tracking"
    }

    private var isShowingFailure: Binding<Bool> {
        Binding(
            get: { postureMonitor.failure != nil },
            set: { if !$0 { postureMonitor.dismissFailure() } }
        )
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Animated background waves when tracking (similar to Shazam's listening animation)
            if isTracking && !reduceMotion {
                ZStack {
                    // Multiple expanding circles
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(postureMonitor.isPostureCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 2)
                            .scaleEffect(pulseAnimation ? 2 + CGFloat(index) * 0.4 : 0.2)
                            .opacity(pulseAnimation ? 0 : 0.7)
                            .animation(
                                Animation.easeInOut(duration: 2)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.5),
                                value: pulseAnimation
                            )
                            .padding(.bottom, -45)
                    }
                    /*
                    // Sound wave animation (vertical bars)
                    HStack(spacing: 8) {
                        ForEach(0..<waveCount, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(postureMonitor.isPostureCorrect ? Color.green.opacity(0.7) : Color.red.opacity(0.7))
                                .frame(width: 6, height: waveAnimation ? 40 + CGFloat(Int.random(in: 10...60)) : 5)
                                .animation(
                                    Animation.easeInOut(duration: 0.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.1),
                                    value: waveAnimation
                                )
                        }
                    }*/
                }
                .accessibilityHidden(true)
            }
            
            VStack {
                // Top toolbar
                HStack {
                    Button(action: {
                        hasCompletedOnboarding = false
                    }) {
                        Text("PoseGuard")
                            .font(.system(size:24, weight: .medium))
                            .foregroundColor(.gray)
                            .transition(.opacity)
                        
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showTips = true
                    }) {
                        Label("Show posture tips", systemImage: "lightbulb")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 50, height: 50)
                            )
                    }
                    .accessibilityFocused($isTipsButtonFocused)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // L'ancora conserva la geometria; il messaggio può crescere senza animare l'altezza.
                Text("Tap To Track")
                    .font(.system(size: 24, weight: .medium))
                    .hidden()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .overlay {
                        Text(trackingStatus)
                            .font(.system(size: 24, weight: .medium))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .foregroundColor(isTracking ? (postureMonitor.isPostureCorrect ? .green : .red) : .gray)
                            .multilineTextAlignment(.center)
                            .id(trackingStatus)
                            .transition(.opacity)
                            .accessibilityIdentifier("trackingStatus")
                    }
                    .layoutPriority(1)
                    .padding(.bottom, 50)
                    .animation(.easeInOut(duration: 0.5), value: isTracking)
                    .animation(.easeInOut(duration: 0.5), value: postureMonitor.isPostureCorrect)
                
                // Main circle button with advanced animations
                Button(action: {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                        if isTracking || postureMonitor.isStarting {
                            postureMonitor.stopMonitoring()
                        } else {
                            postureMonitor.startMonitoring()
                        }
                    }
                }) {
                    ZStack {
                        // Animated outer glow
                        if isTracking && !reduceMotion {
                            Circle()
                                .stroke(postureMonitor.isPostureCorrect ? Color.green.opacity(0.5) : Color.red.opacity(0.5), lineWidth: 3)
                                .frame(width: 170, height: 170)
                                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                        }
                        
                        // Main button background
                        Circle()
                            .fill(
                                isTracking ?
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        postureMonitor.isPostureCorrect ? Color.green : Color.red,
                                        postureMonitor.isPostureCorrect ? Color.green.opacity(0.7) : Color.red.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 150, height: 150)
                            .shadow(color: isTracking ? (postureMonitor.isPostureCorrect ? Color.green.opacity(0.7) : Color.red.opacity(0.7)) : Color.black.opacity(0.3), radius: 15)
                        
                        // Optional glowing effect
                        if isTracking {
                            Circle()
                                .fill(postureMonitor.isPostureCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                                .frame(width: 150, height: 150)
                                .blur(radius: 5)
                        }
                        
                        // Icon with rotation animation
                        Image(systemName: "airpodspro")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .rotationEffect(Angle(degrees: rotationAnimation ? 360 : 0))
                            .animation(
                                reduceMotion ? nil : (isTracking ?
                                Animation.linear(duration: 10).repeatForever(autoreverses: false) :
                                .default),
                                value: rotationAnimation
                            )
                    }
                    .frame(width: 150, height: 150)
                }
                .padding(.bottom, 100)
                .scaleEffect(isTracking && !reduceMotion ? 1.05 : 1.0)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6), value: isTracking)
                .accessibilityLabel(trackingActionLabel)
                .accessibilityIdentifier("Airpods Pro")
                .alert(Text(postureMonitor.failure?.title ?? ""), isPresented: isShowingFailure, presenting: postureMonitor.failure) { failure in
                    if failure.canOpenSettings {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                    }
                    Button("OK", role: .cancel) {}
                } message: { failure in
                    Text(failure.message)
                }
                Spacer()
                
               /*
                // Bottom report bar with enhanced design and animations - now with drag gesture
                VStack {
                    // Drag indicator with subtle pulse
                    Rectangle()
                        .frame(width: 60, height: 5)
                        .cornerRadius(2.5)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 10)
                        .scaleEffect(x: isTracking ? 1.2 : 1.0, y: 1.0)
                        .animation(
                            isTracking ?
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true) :
                            .default,
                            value: isTracking
                        )
                    
                    HStack {
                        Text("My Report")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                        
                        Spacer()
                        
                        if isTracking {
                            // Animated time counter (similar to Shazam)
                            HStack(spacing: 2) {
                                Image(systemName: "timer")
                                    .foregroundColor(.green)
                                
                                TimeCounter()
                                    .foregroundColor(.white)
                            }
                            .padding(.trailing)
                            .transition(.opacity)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedCornerShape(radius: 25, corners: [.topLeft, .topRight])
                        .fill(Color(UIColor.darkGray).opacity(0.6))
                        .edgesIgnoringSafeArea(.bottom)
                )
                .offset(y: showReport ? 120 : 1 + panOffset) // Effetto sheet
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.height
                            if translation > 0 || showReport { // Blocca il trascinamento verso il basso se è già chiuso
                                panOffset = translation
                            }
                        }
                        .onEnded { value in
                            let velocity = value.predictedEndTranslation.height
                            if velocity < -50 || value.translation.height < -100 {
                                showReport = true
                            } else if value.translation.height > 50 {
                                showReport = false
                            }
                            panOffset = 0
                        }
                )
                .animation(.spring(), value: showReport)
                */
            }
            .accessibilityElement(children: .contain)
            .accessibilityHidden(showTips)
            .allowsHitTesting(!showTips)
            
            // Report view overlay
            MyReportView(isShowing: $showReport)
                .accessibilityHidden(!showReport || showTips)
                .allowsHitTesting(showReport && !showTips)
            MyTipsView(isShowing: $showTips)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: isTracking)
        .transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        .onChange(of: isTracking) { _, tracking in updateAnimations(tracking) }
        .onChange(of: reduceMotion) { updateAnimations(isTracking) }
        .onChange(of: scenePhase) { _, phase in postureMonitor.recordScenePhase(phase) }
        .onChange(of: showTips) { _, isShowing in
            if !isShowing { isTipsButtonFocused = true }
        }
        .onAppear {
            updateAnimations(isTracking)
            postureMonitor.recordScenePhase(scenePhase)
        }
        .onDisappear { postureMonitor.stopMonitoring() }
    }
    
    private func updateAnimations(_ tracking: Bool) {
        withAnimation(reduceMotion ? nil : .default) {
            pulseAnimation = tracking && !reduceMotion
            waveAnimation = tracking && !reduceMotion
            rotationAnimation = tracking && !reduceMotion
        }
    }
    
}

// Time counter component (like Shazam's timer during listening)
struct TimeCounter: View {
    @StateObject private var viewModel = TimeCounterViewModel()
    
    var body: some View {
        Text(timeString)
            .font(.system(size: 16, weight: .medium))
            .monospacedDigit()
    }
    
    var timeString: String {
        let minutes = viewModel.seconds / 60
        let remainingSeconds = viewModel.seconds % 60
        return String(format: "%01d:%02d", minutes, remainingSeconds)
    }
}

    // Custom Shape for specific corner radius
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
        // Custom function name to avoid redeclaration conflict with SwiftUI's built-in cornerRadius
    func cornerRadiusForSpecificCorners(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var hasCompletedOnboarding = true
        
        var body: some View {
            TrackingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
    
    return PreviewWrapper()
}
