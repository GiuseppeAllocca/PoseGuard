import SwiftUI

struct TrackingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @StateObject private var postureMonitor = PostureMonitorModel.makeForTrackingView()
    /// Non-nil while motion samples arrive; also measures the session's time in a correct posture.
    @State private var postureTimer: CorrectPostureTimer?
    @State private var showTips = false
    @State private var showReport = false
    /// Shown only when the first sample is late, usually because the AirPods aren't in the ears.
    @State private var showAirPodsHint = false

    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var isTracking: Bool { postureTimer != nil }
    /// Waiting for the first sample or tracking: the button stops either.
    private var isActive: Bool { isTracking || postureMonitor.isStarting }

    /// Gray while idle, green or red while tracking, as in the original design.
    private var stateColor: Color {
        guard isTracking else { return .gray }
        return postureMonitor.isPostureCorrect ? PostureCategory.buona.color : PostureCategory.cattiva.color
    }

    private var isShowingFailure: Binding<Bool> {
        Binding(
            get: { postureMonitor.failure != nil },
            set: { if !$0 { postureMonitor.dismissFailure() } }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                ZStack {
                    // Idle: one slow gray ripple invites a tap. Tracking: three ripples in the posture color.
                    if !reduceMotion {
                        PulseRings(color: stateColor, count: isTracking ? 3 : 1)
                            .id(isTracking)
                    }

                    TrackButton(isTracking: isActive, tint: stateColor, action: toggleTracking)
                }
                .overlay(alignment: .top) {
                    Group {
                        if isTracking {
                            Text(postureMonitor.postureMessage)
                        } else if postureMonitor.isStarting {
                            if showAirPodsHint {
                                Text("Put on your AirPods")
                            }
                        } else if reduceMotion {
                            // Without the motion cues, spell out what the button does.
                            Text("Tap to Track")
                        }
                    }
                    .font(.title2.weight(.medium))
                    .foregroundStyle(stateColor)
                    .multilineTextAlignment(.center)
                    .containerRelativeFrame(.horizontal) { width, _ in width - 32 }
                    .fixedSize(horizontal: false, vertical: true)
                    // Sit above the button without moving it off center.
                    .alignmentGuide(.top) { $0[.bottom] + 56 }
                }
                // Centered on the physical screen, ignoring the toolbar.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            }
            .overlay(alignment: .bottom) {
                if let postureTimer {
                    LiveStatsCard(startDate: postureTimer.start, pitch: postureMonitor.pitch, roll: postureMonitor.roll)
                        .padding()
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(Theme.spring, value: isTracking)
            .animation(.smooth, value: postureMonitor.isPostureCorrect)
            // Named for VoiceOver and the app switcher, but not drawn in the bar.
            .navigationTitle("PoseGuard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(removing: .title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("How it works", systemImage: "info.circle", action: showOnboarding)
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Tips", systemImage: "lightbulb") { showTips = true }
                    Button("My Report", systemImage: "chart.bar.xaxis") { showReport = true }
                }
            }
            .sheet(isPresented: $showTips) {
                MyTipsView()
            }
            .sheet(isPresented: $showReport) {
                MyReportView()
            }
            .alert(Text(postureMonitor.failure?.title ?? ""), isPresented: isShowingFailure, presenting: postureMonitor.failure) { failure in
                if failure.canOpenSettings {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Button("OK", role: .cancel) {}
            } message: { failure in
                Text(failure.message)
            }
            .sensoryFeedback(.impact, trigger: isTracking)
            .sensoryFeedback(trigger: postureMonitor.isPostureCorrect) { _, isCorrect in
                isTracking && !isCorrect ? .warning : nil
            }
            // The model owns the session: the timer starts with the first sample and ends on stop or failure.
            .task(id: postureMonitor.isStarting) {
                showAirPodsHint = false
                guard postureMonitor.isStarting else { return }
                try? await Task.sleep(for: .seconds(5))
                if !Task.isCancelled { showAirPodsHint = true }
            }
            .onChange(of: postureMonitor.state) { oldState, newState in
                if newState == .starting {
                    // The wait has no text on screen, so VoiceOver users still need to hear it.
                    AccessibilityNotification.Announcement("Waiting for your AirPods").post()
                } else if newState == .tracking, postureTimer == nil {
                    postureTimer = CorrectPostureTimer(start: .now, isCorrect: postureMonitor.isPostureCorrect)
                } else if oldState == .tracking, newState != .tracking {
                    if let session = postureTimer?.session(endingAt: .now) {
                        sessionStore.add(session)
                    }
                    postureTimer = nil
                }
            }
            .onChange(of: postureMonitor.isPostureCorrect) { _, isCorrect in
                guard isTracking else { return }
                postureTimer?.update(isCorrect: isCorrect, at: .now)
                // VoiceOver users can't see the color change, so speak it.
                AccessibilityNotification.Announcement(postureMonitor.postureMessage).post()
            }
            .onChange(of: scenePhase) { _, phase in postureMonitor.recordScenePhase(phase) }
            .onDisappear { postureMonitor.stopMonitoring() }
        }
    }

    private func showOnboarding() {
        hasCompletedOnboarding = false
    }

    private func toggleTracking() {
        if isActive {
            postureMonitor.stopMonitoring()
        } else {
            postureMonitor.startMonitoring()
        }
    }
}

#Preview {
    TrackingView(hasCompletedOnboarding: .constant(true))
        .environment(SessionStore())
}
