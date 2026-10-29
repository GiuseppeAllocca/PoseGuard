//
//  P.swift
//  PoseGuard (3.0)
//
//  Created by Matteo Cotena on 11/03/25.
//

import SwiftUI
import CoreMotion
import UserNotifications
import AVFAudio
#if DEBUG
import OSLog
#endif

struct PostureMotionSample {
    let pitch: Double
    let roll: Double
    #if DEBUG
    var timestamp: TimeInterval? = nil
    #endif
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
    private let keepAlive = BackgroundAudioKeepAlive()

    var isDeviceMotionAvailable: Bool { manager.isDeviceMotionAvailable }
    var authorizationStatus: CMAuthorizationStatus { CMHeadphoneMotionManager.authorizationStatus() }

    func startUpdates(_ handler: @escaping (PostureMotionSample?, Error?) -> Void, onDisconnect: @escaping () -> Void) {
        keepAlive.start()
        let delegate = HeadphoneConnectionDelegate(onDisconnect: onDisconnect)
        connectionDelegate = delegate
        manager.delegate = delegate
        manager.startConnectionStatusUpdates()
        manager.startDeviceMotionUpdates(to: .main) { motion, error in
            let sample = motion.map {
                let sample = PostureMotionSample(
                    pitch: $0.attitude.pitch * (180.0 / .pi),
                    roll: $0.attitude.roll * (180.0 / .pi)
                )
                #if DEBUG
                return PostureMotionSample(pitch: sample.pitch, roll: sample.roll, timestamp: $0.timestamp)
                #else
                return sample
                #endif
            }
            handler(sample, error)
        }
    }

    func stopUpdates() {
        manager.delegate = nil
        connectionDelegate = nil
        manager.stopDeviceMotionUpdates()
        manager.stopConnectionStatusUpdates()
        keepAlive.stop()
    }
}

// Senza audio attivo iOS sospende l'app a schermo bloccato e i campioni degli AirPods si fermano:
// durante il monitoraggio si riproduce silenzio, mescolato all'audio delle altre app.
final class BackgroundAudioKeepAlive {
    private let engine = AVAudioEngine()
    private var interruptionObserver: NSObjectProtocol?

    init() {
        let silence = AVAudioSourceNode { isSilence, _, _, buffers in
            isSilence.pointee = true
            for buffer in UnsafeMutableAudioBufferListPointer(buffers) {
                if let data = buffer.mData { memset(data, 0, Int(buffer.mDataByteSize)) }
            }
            return noErr
        }
        engine.attach(silence)
        engine.connect(silence, to: engine.mainMixerNode,
                       format: AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))
    }

    func start() {
        guard interruptionObserver == nil else { return }
        // Una chiamata o un'altra app interrompe la sessione: alla fine dell'interruzione si riparte.
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                .flatMap(AVAudioSession.InterruptionType.init)
            if type == .ended { self?.activate() }
        }
        activate()
    }

    func stop() {
        guard let observer = interruptionObserver else { return }
        NotificationCenter.default.removeObserver(observer)
        interruptionObserver = nil
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func activate() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: .mixWithOthers)
            try session.setActive(true)
            if !engine.isRunning { try engine.start() }
        } catch {
            // In primo piano il tracking funziona comunque; in background si fermerà.
            print("Background audio error: \(error.localizedDescription)")
        }
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

private func postureTrace(_ message: @autoclosure () -> String) {
    #if DEBUG
    let entry = message()
    PostureDiagnosticLog.logger.notice("uptime=\(ProcessInfo.processInfo.systemUptime) \(entry, privacy: .public)")
    #endif
}

#if DEBUG
private enum PostureDiagnosticLog {
    static let logger = Logger(subsystem: "com.giuseppe-allocca.PoseGuardApp", category: "Monitoraggio")
}

struct PostureMotionDiagnostics {
    private(set) var sampleCount = 0
    private(set) var lastSensorTime: TimeInterval?
    private(set) var lastReceivedAt: TimeInterval?
    private(set) var maximumSensorGap: TimeInterval = 0
    private(set) var maximumProcessingGap: TimeInterval = 0

    mutating func record(sensorTime: TimeInterval?, receivedAt: TimeInterval) {
        sampleCount += 1
        if let previous = lastReceivedAt {
            maximumProcessingGap = max(maximumProcessingGap, receivedAt - previous)
        }
        lastReceivedAt = receivedAt
        if let sensorTime, sensorTime.isFinite {
            if let previous = lastSensorTime {
                maximumSensorGap = max(maximumSensorGap, sensorTime - previous)
            }
            lastSensorTime = sensorTime
        }
    }

    var summary: String {
        "campioni=\(sampleCount) ultimoSensore=\(lastSensorTime.map { String($0) } ?? "assente") ultimaElaborazione=\(lastReceivedAt.map { String($0) } ?? "assente") intervalloMassimoSensore=\(maximumSensorGap) intervalloMassimoElaborazione=\(maximumProcessingGap)"
    }
}
#endif

#if DEBUG && targetEnvironment(simulator)
// La sequenza controllata è attivabile solo dagli UI test sul Simulator.
private final class SimulatorPostureMotionSource: PostureMotionSource {
    let isDeviceMotionAvailable = true
    let authorizationStatus: CMAuthorizationStatus = .authorized
    private var pending: [DispatchWorkItem] = []

    func startUpdates(_ handler: @escaping (PostureMotionSample?, Error?) -> Void, onDisconnect: @escaping () -> Void) {
        stopUpdates()
        for (delay, pitch) in [(6.0, 0.0), (12.0, 20.0), (12.1, 20.0)] {
            let item = DispatchWorkItem {
                handler(PostureMotionSample(pitch: pitch, roll: 0,
                                            timestamp: ProcessInfo.processInfo.systemUptime), nil)
            }
            pending.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        }
    }

    func stopUpdates() {
        pending.forEach { $0.cancel() }
        pending.removeAll()
    }
}

@MainActor
private final class SimulatorPostureNotifications: PostureNotificationCenter {
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping @Sendable (Bool, Error?) -> Void) {
        completionHandler(false, nil)
    }
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?) {
        completionHandler?(nil)
    }
    func getPendingNotificationRequests(completionHandler: @escaping @Sendable ([UNNotificationRequest]) -> Void) {
        completionHandler([])
    }
    nonisolated func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}
#endif

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
            case .disconnected: key = "Headphone motion interrupted"
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
                key = "PoseGuard lost the headphone motion connection. Check that your headphones are connected and worn, then tap to start again."
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
    #if DEBUG
    private(set) var motionDiagnostics = PostureMotionDiagnostics()
    private var lastDiagnosticEmission: TimeInterval = 0
    #endif
    
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

    static func makeForTrackingView() -> PostureMonitorModel {
        #if DEBUG && targetEnvironment(simulator)
        if ProcessInfo.processInfo.environment["POSEGUARD_UI_TRACKING_SEQUENCE"] == "1" {
            return PostureMonitorModel(motionManager: SimulatorPostureMotionSource(),
                                       notificationCenter: SimulatorPostureNotifications())
        }
        #endif
        return PostureMonitorModel()
    }

    func recordScenePhase(_ phase: ScenePhase) {
        trace("lifecycle=\(phase)")
    }

    private func trace(_ event: @autoclosure () -> String) {
        #if DEBUG
        postureTrace("\(event()) sessione=\(monitoringSession?.uuidString ?? "nessuna") stato=\(state) \(motionDiagnostics.summary)")
        #endif
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
        #if DEBUG
        motionDiagnostics = PostureMotionDiagnostics()
        lastDiagnosticEmission = 0
        #endif
        trace("avvio consenso=\(motionManager.authorizationStatus.rawValue) disponibile=\(motionManager.isDeviceMotionAvailable)")
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
        trace("attesa")
        motionManager.startUpdates({ [weak self] sample, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.monitoringSession == session else { return }
                if let failure = self.authorizationFailure {
                    self.fail(failure)
                } else if let error = error {
                    self.trace("erroreMotion dominio=\((error as NSError).domain) codice=\((error as NSError).code)")
                    self.fail(self.failure(for: error))
                } else if let sample = sample {
                    guard sample.pitch.isFinite, sample.roll.isFinite else {
                        self.fail(.trackingFailed)
                        return
                    }
                    self.state = .tracking
                    #if DEBUG
                    let receivedAt = ProcessInfo.processInfo.systemUptime
                    self.motionDiagnostics.record(sensorTime: sample.timestamp, receivedAt: receivedAt)
                    if self.motionDiagnostics.sampleCount == 1 || receivedAt - self.lastDiagnosticEmission >= 5 {
                        self.trace("campioni")
                        self.lastDiagnosticEmission = receivedAt
                    }
                    #endif
                    self.checkPosture(sample: sample)
                    self.setupNotifications()
                }
            }
        }, onDisconnect: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.monitoringSession == session else { return }
                self.trace("callbackDisconnessioneMotion")
                self.fail(self.authorizationFailure ?? .disconnected)
            }
        })
    }
    
    func stopMonitoring() {
        trace("stop")
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
        trace("arresto motivo=\(failure)")
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
        trace("richiestaCancellazione episodio=\(prefix)")
        postureNotificationPrefix = nil
        let center = notificationCenter
        center.getPendingNotificationRequests { requests in
            let identifiers = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            postureTrace("cancellazione episodio=\(prefix) pendenti=\(identifiers.count)")
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
        trace("programmazioneAvviso id=\(identifier) ritardo=7s")
        
        notificationCenter.add(request) { error in
            postureTrace("esitoProgrammazione id=\(identifier) errore=\(error.map { String(($0 as NSError).code) } ?? "nessuno")")
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
