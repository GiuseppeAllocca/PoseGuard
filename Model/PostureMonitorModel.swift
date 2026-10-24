//
//  P.swift
//  PoseGuard (3.0)
//
//  Created by Matteo Cotena on 11/03/25.
//

import SwiftUI
import CoreMotion
import UserNotifications

struct PostureMotionSample {
    let pitch: Double
    let roll: Double
}

protocol PostureMotionSource: AnyObject {
    var isDeviceMotionAvailable: Bool { get }
    var authorizationStatus: CMAuthorizationStatus { get }
    func startUpdates(_ handler: @escaping (PostureMotionSample?, Error?) -> Void, onDisconnect: @escaping () -> Void)
    func stopUpdates()
}

final class HeadphoneMotionSource: PostureMotionSource {
    private let manager = CMHeadphoneMotionManager()
    private var connectionDelegate: HeadphoneConnectionDelegate?

    var isDeviceMotionAvailable: Bool { manager.isDeviceMotionAvailable }
    var authorizationStatus: CMAuthorizationStatus { CMHeadphoneMotionManager.authorizationStatus() }

    func startUpdates(_ handler: @escaping (PostureMotionSample?, Error?) -> Void, onDisconnect: @escaping () -> Void) {
        let delegate = HeadphoneConnectionDelegate(onDisconnect: onDisconnect)
        connectionDelegate = delegate
        manager.delegate = delegate
        manager.startConnectionStatusUpdates()
        manager.startDeviceMotionUpdates(to: .main) { motion, error in
            let sample = motion.map {
                PostureMotionSample(
                    pitch: $0.attitude.pitch * (180.0 / .pi),
                    roll: $0.attitude.roll * (180.0 / .pi)
                )
            }
            handler(sample, error)
        }
    }

    func stopUpdates() {
        manager.delegate = nil
        connectionDelegate = nil
        manager.stopDeviceMotionUpdates()
        manager.stopConnectionStatusUpdates()
    }
}

private final class HeadphoneConnectionDelegate: NSObject, CMHeadphoneMotionManagerDelegate {
    private let onDisconnect: () -> Void

    init(onDisconnect: @escaping () -> Void) {
        self.onDisconnect = onDisconnect
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        onDisconnect()
    }
}

@MainActor
protocol PostureNotificationCenter: AnyObject, Sendable {
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping @Sendable (Bool, Error?) -> Void)
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
    func getPendingNotificationRequests(completionHandler: @escaping @Sendable ([UNNotificationRequest]) -> Void)
    nonisolated func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: PostureNotificationCenter {}

@MainActor
class PostureMonitorModel: ObservableObject {
    enum State: Equatable {
        case idle
        case starting
        case tracking
        case failed(Failure)
    }

    enum Failure: Equatable {
        case unavailable
        case motionDenied
        case motionRestricted
        case configuration
        case disconnected
        case trackingFailed

        var title: String {
            let key: String
            switch self {
            case .unavailable: key = "Headphone motion unavailable"
            case .motionDenied: key = "Motion access denied"
            case .motionRestricted: key = "Motion access restricted"
            case .configuration: key = "Tracking unavailable"
            case .disconnected: key = "AirPods not connected"
            case .trackingFailed: key = "Tracking error"
            }
            return NSLocalizedString(key, comment: "")
        }

        var message: String {
            let key: String
            switch self {
            case .unavailable:
                key = "Headphone motion is unavailable. Connect compatible headphones, then try again."
            case .motionDenied:
                key = "Allow PoseGuard to access motion data in Settings to track your posture."
            case .motionRestricted:
                key = "Motion access is restricted on this device. Check its privacy settings and restrictions."
            case .configuration:
                key = "PoseGuard cannot access headphone motion because of an app configuration issue."
            case .disconnected:
                key = "Your headphones disconnected. Reconnect them, then tap to start again."
            case .trackingFailed:
                key = "Could not read headphone motion. Try starting again."
            }
            return NSLocalizedString(key, comment: "")
        }

        var canOpenSettings: Bool { self == .motionDenied || self == .motionRestricted }
    }

    private let motionManager: any PostureMotionSource
    private let notificationCenter: any PostureNotificationCenter
    private let now: () -> Date
    private static let postureNotificationNamespace = "poseguard.posture."
    private static let processNotificationPrefix = postureNotificationNamespace + UUID().uuidString + "."
    private let notificationOwnerPrefix: String
    nonisolated private static let thresholdAngle: Double = 15.0 // Threshold in degrees
    private var lastNotificationTime: Date?
    private let timer: Double = 5 //Notification timer
    private var monitoringSession: UUID?
    private var postureNotificationPrefix: String?
    private var hasRequestedNotifications = false
    
    @Published var isPostureCorrect: Bool = true
    @Published var postureMessage: String = NSLocalizedString("Correct Posture!", comment: "")
    @Published var roll: Double = 0.0
    @Published var pitch: Double = 0.0
    @Published private(set) var state: State = .idle

    var isMonitoring: Bool { state == .tracking }
    var isStarting: Bool { state == .starting }
    var failure: Failure? {
        if case .failed(let failure) = state { return failure }
        return nil
    }
    
    init(
        motionManager: any PostureMotionSource = HeadphoneMotionSource(),
        notificationCenter: any PostureNotificationCenter = UNUserNotificationCenter.current(),
        now: @escaping () -> Date = Date.init
    ) {
        self.motionManager = motionManager
        self.notificationCenter = notificationCenter
        self.now = now
        let processPrefix = Self.processNotificationPrefix
        self.notificationOwnerPrefix = processPrefix + UUID().uuidString + "."
        let namespace = Self.postureNotificationNamespace

        notificationCenter.getPendingNotificationRequests { requests in
            // Anche una query di un model già rilasciato preserva gli avvisi del processo corrente.
            let identifiers = requests.filter {
                $0.identifier.hasPrefix(namespace) && !$0.identifier.hasPrefix(processPrefix)
            }.map(\.identifier)
            guard !identifiers.isEmpty else { return }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    private func setupNotifications() {
        guard !hasRequestedNotifications else { return }
        hasRequestedNotifications = true
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Authorized notifications")
            } else if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    func startMonitoring() {
        guard monitoringSession == nil else { return }
        if let failure = authorizationFailure {
            fail(failure)
            return
        }
        guard motionManager.isDeviceMotionAvailable else {
            fail(.unavailable)
            return
        }
        
        let session = UUID()
        monitoringSession = session
        state = .starting
        motionManager.startUpdates({ [weak self] sample, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.monitoringSession == session else { return }
                if let failure = self.authorizationFailure {
                    self.fail(failure)
                } else if let error = error {
                    self.fail(self.failure(for: error))
                } else if let sample = sample {
                    guard sample.pitch.isFinite, sample.roll.isFinite else {
                        self.fail(.trackingFailed)
                        return
                    }
                    self.state = .tracking
                    self.checkPosture(sample: sample)
                    self.setupNotifications()
                }
            }
        }, onDisconnect: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.monitoringSession == session else { return }
                self.fail(self.authorizationFailure ?? .disconnected)
            }
        })
    }
    
    func stopMonitoring() {
        monitoringSession = nil
        state = .idle
        cancelPostureNotifications()
        motionManager.stopUpdates()
    }

    func dismissFailure() {
        guard failure != nil else { return }
        state = .idle
    }

    private var authorizationFailure: Failure? {
        switch motionManager.authorizationStatus {
        case .denied: return .motionDenied
        case .restricted: return .motionRestricted
        case .authorized, .notDetermined: return nil
        @unknown default: return .motionRestricted
        }
    }

    private func failure(for error: Error) -> Failure {
        let error = error as NSError
        guard error.domain == CMErrorDomain else { return .trackingFailed }
        switch error.code {
        case Int(CMErrorNotAuthorized.rawValue), Int(CMErrorMotionActivityNotAuthorized.rawValue):
            return .motionDenied
        case Int(CMErrorNotAvailable.rawValue), Int(CMErrorMotionActivityNotAvailable.rawValue):
            return .unavailable
        case Int(CMErrorNotEntitled.rawValue), Int(CMErrorMotionActivityNotEntitled.rawValue):
            return .configuration
        default:
            return .trackingFailed
        }
    }

    private func fail(_ failure: Failure) {
        monitoringSession = nil
        cancelPostureNotifications()
        motionManager.stopUpdates()
        postureMessage = failure.message
        state = .failed(failure)
    }
    
    nonisolated static func isPostureWithinThreshold(pitch: Double, roll: Double) -> Bool {
        !(abs(roll) > thresholdAngle || abs(pitch) > thresholdAngle)
    }

    private func checkPosture(sample: PostureMotionSample) {
        self.roll = sample.roll
        self.pitch = sample.pitch

        let wasPostureCorrect = self.isPostureCorrect
        let now = self.now()

        if !Self.isPostureWithinThreshold(pitch: sample.pitch, roll: sample.roll) {
            self.isPostureCorrect = false
            self.postureMessage = NSLocalizedString("Bad Posture!", comment: "")

            if !wasPostureCorrect && postureNotificationPrefix == nil {
                if let lastTime = self.lastNotificationTime, now.timeIntervalSince(lastTime) < self.timer {
                    return
                }
                self.sendPostureNotification()
                self.lastNotificationTime = now
            }
        } else {
            self.isPostureCorrect = true
            self.postureMessage = NSLocalizedString("Correct Posture!", comment: "")
            self.cancelPostureNotifications()

            /*if wasPostureCorrect {
                if let lastTime = self.lastNotificationTime, now.timeIntervalSince(lastTime) < self.timer {
                    return
                }
                self.sendNotification(title: "PoseGuard", message: "Correct Posture!")
                self.lastNotificationTime = now
            }*/
        }
    }

    private func sendPostureNotification() {
        let prefix = postureNotificationPrefix ?? notificationOwnerPrefix + UUID().uuidString + "."
        postureNotificationPrefix = prefix
        let identifier = prefix + UUID().uuidString
        let center = notificationCenter

        sendNotification(title: "PoseGuard", message: "Bad Posture!", identifier: identifier) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.isMonitoring, self.postureNotificationPrefix == prefix else {
                    // La registrazione può terminare dopo il recupero, lo stop o la distruzione del model.
                    center.removePendingNotificationRequests(withIdentifiers: [identifier])
                    return
                }
                if error != nil { self.postureNotificationPrefix = nil }
            }
        }
    }

    private func cancelPostureNotifications() {
        guard let prefix = postureNotificationPrefix else { return }
        postureNotificationPrefix = nil
        let center = notificationCenter
        center.getPendingNotificationRequests { requests in
            let identifiers = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            guard !identifiers.isEmpty else { return }
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    private func sendNotification(
        title: String,
        message: String,
        identifier: String = UUID().uuidString,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7.0, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
            completion?(error)
        }
    }
    
    isolated deinit {
        stopMonitoring()
    }
}
