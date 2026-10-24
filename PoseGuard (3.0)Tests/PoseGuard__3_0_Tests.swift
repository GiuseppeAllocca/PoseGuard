//
//  PoseGuard__3_0_Tests.swift
//  PoseGuard (3.0)Tests
//
//  Created by Acri Stefano on 10/03/25.
//

import Testing
import Foundation
import CoreMotion
import UserNotifications
@testable import PoseGuard

struct PoseGuard__3_0_Tests {

    struct ThresholdCase: Sendable {
        let pitch: Double
        let roll: Double
        let expected: Bool
    }

    @Test("La soglia include quindici gradi su ciascun asse", arguments: [
        ThresholdCase(pitch: 0, roll: 0, expected: true),
        ThresholdCase(pitch: 15, roll: 0, expected: true),
        ThresholdCase(pitch: -15, roll: 0, expected: true),
        ThresholdCase(pitch: 0, roll: 15, expected: true),
        ThresholdCase(pitch: 0, roll: -15, expected: true),
        ThresholdCase(pitch: 15, roll: 15, expected: true),
        ThresholdCase(pitch: 15, roll: -15, expected: true),
        ThresholdCase(pitch: -15, roll: 15, expected: true),
        ThresholdCase(pitch: -15, roll: -15, expected: true),
        ThresholdCase(pitch: 15.0.nextUp, roll: 0, expected: false),
        ThresholdCase(pitch: (-15.0).nextDown, roll: 0, expected: false),
        ThresholdCase(pitch: 0, roll: 15.0.nextUp, expected: false),
        ThresholdCase(pitch: 0, roll: (-15.0).nextDown, expected: false),
        ThresholdCase(pitch: 15.0.nextUp, roll: -15, expected: false),
        ThresholdCase(pitch: (-15.0).nextDown, roll: 15, expected: false),
        ThresholdCase(pitch: 15, roll: (-15.0).nextDown, expected: false),
        ThresholdCase(pitch: -15, roll: 15.0.nextUp, expected: false),
        ThresholdCase(pitch: 15.0.nextUp, roll: (-15.0).nextDown, expected: false),
        ThresholdCase(pitch: (-15.0).nextDown, roll: 15.0.nextUp, expected: false)
    ])
    func postureThreshold(_ sample: ThresholdCase) {
        #expect(PostureMonitorModel.isPostureWithinThreshold(
            pitch: sample.pitch,
            roll: sample.roll
        ) == sample.expected)
    }
}

extension PoseGuard__3_0_Tests {
    @Test("Il recupero e lo stop annullano gli avvisi posturali pendenti", arguments: [false, true])
    @MainActor
    func pendingPostureNotificationsAreCancelled(stopInsteadOfRecovering: Bool) async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()

        #expect(fixture.notifications.addedRequests.count == 1)
        #expect(fixture.notifications.pendingIdentifiers.count == 1)
        fixture.endEpisode(byStopping: stopInsteadOfRecovering)
        await drainPostureCallbacks()

        #expect(fixture.notifications.pendingIdentifiers.isEmpty)
        #expect(fixture.model.isMonitoring == !stopInsteadOfRecovering)
    }

    @Test("Un avviso aggiunto dopo la fine dell'episodio viene rimosso", arguments: [false, true])
    @MainActor
    func delayedPostureNotificationIsCancelled(stopInsteadOfRecovering: Bool) async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.notifications.defersAdds = true
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()

        #expect(fixture.notifications.addedRequests.count == 1)
        #expect(fixture.notifications.pendingIdentifiers.isEmpty)
        fixture.endEpisode(byStopping: stopInsteadOfRecovering)
        await drainPostureCallbacks()
        fixture.notifications.completeDeferredAdds()
        await drainPostureCallbacks()

        #expect(fixture.notifications.pendingIdentifiers.isEmpty)
    }

    @Test("I callback di una sessione conclusa non alterano il monitoraggio", arguments: [false, true])
    @MainActor
    func staleMotionCallbacksAreIgnored(restart: Bool) async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        fixture.model.stopMonitoring()
        if restart { fixture.model.startMonitoring() }
        let originalMessage = fixture.model.postureMessage

        fixture.sendBadSamples(stream: 0)
        fixture.motion.send(nil, error: NSError(domain: "PoseGuardTests", code: 1), stream: 0)
        fixture.motion.disconnect(stream: 0)
        await drainPostureCallbacks()

        #expect(fixture.model.state == (restart ? .starting : .idle))
        #expect(!fixture.model.isMonitoring)
        #expect(fixture.model.isStarting == restart)
        #expect(fixture.model.isPostureCorrect)
        #expect(fixture.model.postureMessage == originalMessage)
        #expect(fixture.model.pitch == 0)
        #expect(fixture.model.roll == 0)
        #expect(fixture.notifications.addedRequests.isEmpty)
    }

    @Test("Anche i callback già accodati vengono invalidati dallo stop", arguments: [false, true])
    @MainActor
    func queuedMotionCallbacksAreIgnored(restart: Bool) async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        let originalMessage = fixture.model.postureMessage
        fixture.sendBadSamples()
        fixture.motion.send(nil, error: NSError(domain: "PoseGuardTests", code: 3))
        fixture.motion.disconnect(stream: 0)
        fixture.model.stopMonitoring()
        if restart { fixture.model.startMonitoring() }
        await drainPostureCallbacks()

        #expect(fixture.model.state == (restart ? .starting : .idle))
        #expect(!fixture.model.isMonitoring)
        #expect(fixture.model.isStarting == restart)
        #expect(fixture.model.isPostureCorrect)
        #expect(fixture.model.postureMessage == originalMessage)
        #expect(fixture.model.pitch == 0)
        #expect(fixture.notifications.addedRequests.isEmpty)
    }

    @Test("Una cancellazione vecchia preserva gli avvisi del nuovo episodio", arguments: [false, true])
    @MainActor
    func delayedCancellationPreservesNewEpisode(stopInsteadOfRecovering: Bool) async throws {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        let oldIdentifier = try #require(fixture.notifications.addedRequests.last?.identifier)
        fixture.notifications.defersPendingQueries = true
        fixture.endEpisode(byStopping: stopInsteadOfRecovering)
        await drainPostureCallbacks()

        fixture.clock.advance(by: 5)
        if stopInsteadOfRecovering { fixture.model.startMonitoring() }
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 2)
        let newIdentifier = try #require(fixture.notifications.addedRequests.last?.identifier)
        #expect(newIdentifier != oldIdentifier)
        #expect(fixture.notifications.pendingIdentifiers == Set([oldIdentifier, newIdentifier]))

        fixture.notifications.defersPendingQueries = false
        fixture.notifications.completeDeferredPendingQueries()
        await drainPostureCallbacks()
        #expect(fixture.notifications.pendingIdentifiers == Set([newIdentifier]))
    }

    @Test("La completion di un vecchio avviso preserva il nuovo episodio", arguments: [false, true])
    @MainActor
    func delayedAdditionPreservesNewEpisode(stopInsteadOfRecovering: Bool) async throws {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.notifications.defersAdds = true
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        fixture.endEpisode(byStopping: stopInsteadOfRecovering)
        await drainPostureCallbacks()

        fixture.notifications.defersAdds = false
        fixture.clock.advance(by: 5)
        if stopInsteadOfRecovering { fixture.model.startMonitoring() }
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 2)
        let newIdentifier = try #require(fixture.notifications.addedRequests.last?.identifier)
        #expect(fixture.notifications.pendingIdentifiers == Set([newIdentifier]))

        fixture.notifications.completeDeferredAdds()
        await drainPostureCallbacks()
        #expect(fixture.notifications.pendingIdentifiers == Set([newIdentifier]))
    }

    @Test("Un solo avviso per episodio, anche dopo la consegna")
    @MainActor
    func continuousBadPostureSchedulesOnlyOneNotification() async throws {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        fixture.sendBadSamples(count: 1)
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.isEmpty)

        fixture.sendBadSamples(count: 1)
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 1)
        fixture.clock.advance(by: 4)
        fixture.sendBadSamples(count: 1)
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 1)

        fixture.clock.advance(by: 1)
        fixture.sendBadSamples(count: 1)
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 1)
        #expect(fixture.notifications.pendingIdentifiers.count == 1)
        let request = try #require(fixture.notifications.addedRequests.first)
        let trigger = try #require(request.trigger as? UNTimeIntervalNotificationTrigger)
        #expect(trigger.timeInterval == 7)
        #expect(!trigger.repeats)

        fixture.notifications.simulateDelivery(of: request.identifier)
        fixture.clock.advance(by: 60)
        fixture.sendBadSamples(count: 10)
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 1)
        #expect(fixture.notifications.pendingIdentifiers.isEmpty)
    }

    @Test("Una registrazione fallita può essere ritentata rispettando il cooldown")
    @MainActor
    func failedNotificationCanRetryAfterCooldown() async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.notifications.additionError = NSError(domain: "PoseGuardTests", code: 20)
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 1)
        #expect(fixture.notifications.pendingIdentifiers.isEmpty)

        fixture.notifications.additionError = nil
        fixture.clock.advance(by: 4)
        fixture.sendBadSamples(count: 1)
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 1)
        fixture.clock.advance(by: 1)
        fixture.sendBadSamples(count: 1)
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 2)
        #expect(fixture.notifications.pendingIdentifiers.count == 1)

        fixture.clock.advance(by: 60)
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 2)
    }

    @Test("Un errore tardivo non riapre né cancella un nuovo episodio", arguments: [false, true])
    @MainActor
    func lateAdditionErrorPreservesNewEpisode(stopInsteadOfRecovering: Bool) async throws {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.notifications.defersAdds = true
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 1)
        fixture.endEpisode(byStopping: stopInsteadOfRecovering)
        await drainPostureCallbacks()

        fixture.notifications.defersAdds = false
        fixture.clock.advance(by: 5)
        if stopInsteadOfRecovering { fixture.model.startMonitoring() }
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        let currentIdentifier = try #require(fixture.notifications.addedRequests.last?.identifier)
        #expect(fixture.notifications.addedRequests.count == 2)
        #expect(fixture.notifications.pendingIdentifiers == Set([currentIdentifier]))

        fixture.notifications.additionError = NSError(domain: "PoseGuardTests", code: 21)
        fixture.notifications.completeDeferredAdds()
        await drainPostureCallbacks()
        fixture.notifications.additionError = nil
        fixture.clock.advance(by: 60)
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 2)
        #expect(fixture.notifications.pendingIdentifiers == Set([currentIdentifier]))
    }

    @Test("Cooldown e postura persistono fra stop e riavvio")
    @MainActor
    func cooldownAndPostureSurviveRestart() async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 1)
        fixture.model.stopMonitoring()
        await drainPostureCallbacks()

        fixture.clock.advance(by: 4)
        fixture.model.startMonitoring()
        fixture.sendBadSamples(count: 1)
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 1)
        fixture.clock.advance(by: 1)
        fixture.sendBadSamples(count: 1)
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 2)
    }

    @Test("La cancellazione posturale preserva una richiesta estranea")
    @MainActor
    func postureCancellationPreservesUnrelatedNotifications() async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        let content = UNMutableNotificationContent()
        content.body = "Richiesta estranea al monitoraggio posturale"
        let unrelatedRequest = UNNotificationRequest(
            identifier: "unrelated-notification",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        )
        fixture.notifications.add(unrelatedRequest, withCompletionHandler: nil)
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        #expect(fixture.notifications.addedRequests.count == 2)
        #expect(fixture.notifications.pendingIdentifiers.count == 2)

        fixture.endEpisode(byStopping: false)
        await drainPostureCallbacks()
        #expect(fixture.notifications.pendingIdentifiers == Set([unrelatedRequest.identifier]))
        fixture.model.stopMonitoring()
        await drainPostureCallbacks()
        #expect(fixture.notifications.pendingIdentifiers == Set([unrelatedRequest.identifier]))
    }

    @Test("Il rilascio in background arresta il monitoraggio sul main executor")
    @MainActor
    func backgroundReleaseStopsMonitoringOnMainActor() async throws {
        let motion = ControlledPostureMotionSource()
        let notifications = ControlledPostureNotificationCenter()
        var model: PostureMonitorModel? = PostureMonitorModel(
            motionManager: motion,
            notificationCenter: notifications,
            now: { Date(timeIntervalSince1970: 0) }
        )
        defer { model?.stopMonitoring() }
        let isModelReleased = { [weak model] in model == nil }
        model?.startMonitoring()
        for _ in 0..<2 { motion.send(PostureMotionSample(pitch: 16, roll: 0)) }
        await drainPostureCallbacks()
        #expect(notifications.pendingIdentifiers.count == 1)

        let (releaseEvents, releaseSignal) = AsyncStream<Void>.makeStream()
        let releaseTask = Task.detached { [model] in
            for await _ in releaseEvents { break }
            withExtendedLifetime(model) {}
        }
        model = nil
        #expect(!isModelReleased())
        releaseSignal.yield(())
        releaseSignal.finish()
        await releaseTask.value
        await drainPostureCallbacks()

        #expect(isModelReleased())
        #expect(motion.stopCount == 1)
        #expect(motion.lastStopWasOnMainThread == true)
        #expect(notifications.pendingIdentifiers.isEmpty)
    }

    @Test("La chiusura del model rimuove anche un avviso aggiunto in ritardo")
    @MainActor
    func deinitializationCancelsDelayedPostureNotification() async {
        let motion = ControlledPostureMotionSource()
        let notifications = ControlledPostureNotificationCenter()
        notifications.defersAdds = true
        var model: PostureMonitorModel? = PostureMonitorModel(
            motionManager: motion,
            notificationCenter: notifications,
            now: { Date(timeIntervalSince1970: 0) }
        )
        let isModelReleased = { [weak model] in model == nil }
        model?.startMonitoring()
        motion.send(PostureMotionSample(pitch: 16, roll: 0))
        motion.send(PostureMotionSample(pitch: 16, roll: 0))
        await drainPostureCallbacks()
        #expect(notifications.addedRequests.count == 1)

        model = nil
        await drainPostureCallbacks()
        #expect(isModelReleased())
        #expect(motion.stopCount >= 1)
        notifications.completeDeferredAdds()
        await drainPostureCallbacks()
        #expect(notifications.pendingIdentifiers.isEmpty)
    }
}

extension PoseGuard__3_0_Tests {
    struct MotionPreflightCase: Sendable {
        let authorization: CMAuthorizationStatus
        let available: Bool
        let expectedFailure: PostureMonitorModel.Failure
    }

    struct MotionErrorCase: Sendable {
        let domain: String
        let code: Int
        let expectedFailure: PostureMonitorModel.Failure
    }

    @Test("Il tracking inizia al primo campione valido e richiede le notifiche una sola volta", arguments: [false, true])
    @MainActor
    func trackingStartsAfterFirstValidSample(notificationPermissionGranted: Bool) async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.motion.authorizationStatus = .notDetermined
        fixture.notifications.authorizationGranted = notificationPermissionGranted
        #expect(fixture.model.state == .idle)
        #expect(fixture.notifications.authorizationRequestCount == 0)
        fixture.model.startMonitoring()
        fixture.model.startMonitoring()
        #expect(fixture.model.state == .starting)
        #expect(fixture.model.isStarting)
        #expect(!fixture.model.isMonitoring)
        #expect(fixture.motion.startCount == 1)
        #expect(fixture.notifications.authorizationRequestCount == 0)
        fixture.model.dismissFailure()
        #expect(fixture.model.state == .starting)

        fixture.motion.send(PostureMotionSample(pitch: 0, roll: 0))
        await drainPostureCallbacks()
        #expect(fixture.model.state == .tracking)
        #expect(fixture.model.isMonitoring)
        #expect(!fixture.model.isStarting)
        #expect(fixture.model.failure == nil)
        #expect(fixture.notifications.authorizationRequestCount == 1)

        fixture.model.startMonitoring()
        fixture.model.dismissFailure()
        fixture.motion.send(PostureMotionSample(pitch: 1, roll: -1))
        await drainPostureCallbacks()
        #expect(fixture.model.state == .tracking)
        #expect(fixture.motion.startCount == 1)
        #expect(fixture.notifications.authorizationRequestCount == 1)
        fixture.model.stopMonitoring()
        fixture.model.startMonitoring()
        #expect(fixture.model.state == .starting)
        #expect(!fixture.model.isMonitoring)
        #expect(fixture.motion.startCount == 2)
        fixture.motion.send(PostureMotionSample(pitch: 0, roll: 0))
        await drainPostureCallbacks()
        #expect(fixture.model.state == .tracking)
        #expect(fixture.notifications.authorizationRequestCount == 1)
    }

    @Test("L'attesa resta annullabile senza dichiarare un tracking inesistente")
    @MainActor
    func prolongedStartingCanBeCancelled() async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        for _ in 0..<3 {
            fixture.clock.advance(by: 3600)
            fixture.motion.send(nil)
            fixture.model.startMonitoring()
            await drainPostureCallbacks()
            #expect(fixture.model.state == .starting)
            #expect(fixture.model.isStarting)
            #expect(!fixture.model.isMonitoring)
            #expect(fixture.model.failure == nil)
            #expect(fixture.motion.startCount == 1)
            #expect(fixture.notifications.authorizationRequestCount == 0)
        }
        fixture.model.stopMonitoring()
        await drainPostureCallbacks()
        #expect(fixture.model.state == .idle)
        #expect(!fixture.model.isStarting)
        #expect(!fixture.model.isMonitoring)
        #expect(fixture.notifications.addedRequests.isEmpty)
    }

    @Test("I controlli preliminari impediscono avvii impossibili", arguments: [
        MotionPreflightCase(authorization: .denied, available: true, expectedFailure: .motionDenied),
        MotionPreflightCase(authorization: .restricted, available: true, expectedFailure: .motionRestricted),
        MotionPreflightCase(authorization: .authorized, available: false, expectedFailure: .unavailable),
        MotionPreflightCase(authorization: .denied, available: false, expectedFailure: .motionDenied),
        MotionPreflightCase(authorization: .restricted, available: false, expectedFailure: .motionRestricted)
    ])
    @MainActor
    func preflightFailuresDoNotStartMotion(_ sample: MotionPreflightCase) async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.motion.authorizationStatus = sample.authorization
        fixture.motion.isDeviceMotionAvailable = sample.available
        fixture.model.startMonitoring()
        #expect(fixture.model.state == .failed(sample.expectedFailure))
        #expect(fixture.model.failure == sample.expectedFailure)
        #expect(!fixture.model.isStarting)
        #expect(!fixture.model.isMonitoring)
        #expect(fixture.motion.startCount == 0)
        #expect(fixture.notifications.authorizationRequestCount == 0)
        #expect(fixture.notifications.addedRequests.isEmpty)
        fixture.model.stopMonitoring()
        #expect(fixture.model.state == .idle)
        #expect(fixture.model.failure == nil)
        fixture.model.startMonitoring()
        #expect(fixture.model.state == .failed(sample.expectedFailure))
        fixture.model.dismissFailure()
        #expect(fixture.model.state == .idle)
        #expect(fixture.model.failure == nil)
    }

    @Test("Gli errori Core Motion producono il motivo di arresto previsto", arguments: [
        MotionErrorCase(domain: CMErrorDomain, code: Int(CMErrorNotAuthorized.rawValue), expectedFailure: .motionDenied),
        MotionErrorCase(domain: CMErrorDomain, code: Int(CMErrorMotionActivityNotAuthorized.rawValue), expectedFailure: .motionDenied),
        MotionErrorCase(domain: CMErrorDomain, code: Int(CMErrorNotAvailable.rawValue), expectedFailure: .unavailable),
        MotionErrorCase(domain: CMErrorDomain, code: Int(CMErrorMotionActivityNotAvailable.rawValue), expectedFailure: .unavailable),
        MotionErrorCase(domain: CMErrorDomain, code: Int(CMErrorNotEntitled.rawValue), expectedFailure: .configuration),
        MotionErrorCase(domain: CMErrorDomain, code: Int(CMErrorMotionActivityNotEntitled.rawValue), expectedFailure: .configuration),
        MotionErrorCase(domain: CMErrorDomain, code: Int(CMErrorUnknown.rawValue), expectedFailure: .trackingFailed),
        MotionErrorCase(domain: "PoseGuardTests", code: Int(CMErrorNotAuthorized.rawValue), expectedFailure: .trackingFailed)
    ])
    @MainActor
    func motionErrorsAreMapped(_ sample: MotionErrorCase) async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        fixture.motion.send(nil, error: NSError(domain: sample.domain, code: sample.code))
        await drainPostureCallbacks()
        #expect(fixture.model.state == .failed(sample.expectedFailure))
        #expect(fixture.model.failure == sample.expectedFailure)
        #expect(!fixture.model.isMonitoring)
        #expect(!fixture.model.isStarting)
        #expect(fixture.motion.stopCount == 1)
        #expect(fixture.notifications.authorizationRequestCount == 0)
        #expect(fixture.notifications.addedRequests.isEmpty)
    }

    @Test("Il consenso Motion attuale prevale sul codice dell'errore", arguments: [CMAuthorizationStatus.denied, .restricted])
    @MainActor
    func currentAuthorizationOverridesError(authorization: CMAuthorizationStatus) async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        fixture.motion.authorizationStatus = authorization
        fixture.motion.send(nil, error: NSError(domain: CMErrorDomain, code: Int(CMErrorNotEntitled.rawValue)))
        await drainPostureCallbacks()
        let expectedFailure: PostureMonitorModel.Failure = authorization == .denied ? .motionDenied : .motionRestricted
        #expect(fixture.model.state == .failed(expectedFailure))
        #expect(fixture.notifications.addedRequests.isEmpty)
    }

    @Test("I campioni non finiti arrestano il monitoraggio", arguments: [
        PostureMotionSample(pitch: .nan, roll: 0),
        PostureMotionSample(pitch: 0, roll: .nan),
        PostureMotionSample(pitch: .infinity, roll: 0),
        PostureMotionSample(pitch: -.infinity, roll: 0),
        PostureMotionSample(pitch: 0, roll: .infinity),
        PostureMotionSample(pitch: 0, roll: -.infinity)
    ])
    @MainActor
    func nonFiniteSamplesFail(_ sample: PostureMotionSample) async {
        for beginWhileTracking in [false, true] {
            let fixture = PostureLifecycleFixture()
            defer { fixture.model.stopMonitoring() }
            fixture.model.startMonitoring()
            if beginWhileTracking {
                fixture.motion.send(PostureMotionSample(pitch: 0, roll: 0))
                await drainPostureCallbacks()
                #expect(fixture.model.state == .tracking)
            }
            fixture.motion.send(sample)
            await drainPostureCallbacks()
            #expect(fixture.model.state == .failed(.trackingFailed))
            #expect(!fixture.model.isMonitoring)
            #expect(!fixture.model.isStarting)
            #expect(fixture.model.pitch.isFinite)
            #expect(fixture.model.roll.isFinite)
            #expect(fixture.motion.stopCount == 1)
            #expect(fixture.notifications.addedRequests.isEmpty)
        }
    }

    @Test("La disconnessione corrente arresta la sessione e annulla gli avvisi", arguments: [false, true])
    @MainActor
    func currentDisconnectionEndsSession(beginWhileTracking: Bool) async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        if beginWhileTracking {
            fixture.sendBadSamples()
            await drainPostureCallbacks()
            #expect(fixture.notifications.pendingIdentifiers.count == 1)
        }
        let previousRequestCount = fixture.notifications.addedRequests.count
        fixture.motion.disconnect()
        await drainPostureCallbacks()
        #expect(fixture.model.state == .failed(.disconnected))
        #expect(!fixture.model.isMonitoring)
        #expect(!fixture.model.isStarting)
        #expect(fixture.notifications.pendingIdentifiers.isEmpty)
        fixture.sendBadSamples(stream: 0)
        fixture.motion.send(nil, error: NSError(domain: "PoseGuardTests", code: 4), stream: 0)
        fixture.motion.disconnect(stream: 0)
        await drainPostureCallbacks()
        #expect(fixture.model.state == .failed(.disconnected))
        #expect(fixture.motion.stopCount == 1)
        #expect(fixture.notifications.addedRequests.count == previousRequestCount)
        #expect(fixture.notifications.pendingIdentifiers.isEmpty)
    }

    @Test("Un errore corrente annulla gli avvisi e invalida i campioni tardivi", arguments: [false, true])
    @MainActor
    func currentErrorCancelsNotificationsAndRejectsLateSamples(deferNotificationAddition: Bool) async {
        let fixture = PostureLifecycleFixture()
        defer { fixture.model.stopMonitoring() }
        fixture.notifications.defersAdds = deferNotificationAddition
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        #expect(fixture.model.state == .tracking)
        #expect(fixture.notifications.addedRequests.count == 1)
        fixture.motion.send(nil, error: NSError(domain: "PoseGuardTests", code: 5))
        await drainPostureCallbacks()
        #expect(fixture.model.state == .failed(.trackingFailed))
        #expect(fixture.notifications.pendingIdentifiers.isEmpty)
        fixture.motion.send(PostureMotionSample(pitch: 0, roll: 0), stream: 0)
        fixture.sendBadSamples(stream: 0)
        fixture.notifications.completeDeferredAdds()
        await drainPostureCallbacks()
        #expect(fixture.model.state == .failed(.trackingFailed))
        #expect(!fixture.model.isMonitoring)
        #expect(fixture.motion.stopCount == 1)
        #expect(fixture.notifications.addedRequests.count == 1)
        #expect(fixture.notifications.pendingIdentifiers.isEmpty)
    }
}

extension PoseGuard__3_0_Tests {
    @Test("L'avvio rimuove solo avvisi posturali riconoscibili di processi precedenti", arguments: [false, true])
    @MainActor
    func startupRemovesPreviousProcessNotifications(hasOwnerPrefix: Bool) async {
        let notifications = ControlledPostureNotificationCenter()
        let previousPrefix = hasOwnerPrefix
            ? "poseguard.posture.previous-process.previous-owner.previous-episode."
            : "poseguard.posture.previous-episode."
        let staleIdentifiers = [previousPrefix + "first", previousPrefix + "second"]
        let preservedIdentifiers = ["unrelated-reminder", "poseguard.posture-other.reminder", "C9BB5CA2-5C3C-4571-BD8D-FB265E9E08D6"]
        for identifier in staleIdentifiers + preservedIdentifiers {
            notifications.add(makePendingPostureRequest(identifier: identifier), withCompletionHandler: nil)
        }

        let fixture = PostureLifecycleFixture(notifications: notifications)
        defer { fixture.model.stopMonitoring() }

        await drainPostureCallbacks()
        #expect(notifications.pendingIdentifiers == Set(preservedIdentifiers))
        #expect(notifications.authorizationRequestCount == 0)
        #expect(fixture.motion.startCount == 0)
        #expect(fixture.model.state == .idle)
    }

    @Test("Una query iniziale tardiva preserva anche un avviso registrato in ritardo", arguments: [false, true])
    @MainActor
    func delayedStartupCleanupPreservesCurrentNotification(defersAddition: Bool) async throws {
        let notifications = ControlledPostureNotificationCenter()
        notifications.add(makePendingPostureRequest(identifier: "poseguard.posture.previous-episode.stale"), withCompletionHandler: nil)
        notifications.defersPendingQueries = true
        let fixture = PostureLifecycleFixture(notifications: notifications)
        defer { fixture.model.stopMonitoring() }
        notifications.defersAdds = defersAddition
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        let currentIdentifier = try #require(notifications.addedRequests.last?.identifier)

        notifications.defersPendingQueries = false
        notifications.completeDeferredPendingQueries()
        notifications.completeDeferredAdds()
        await drainPostureCallbacks()

        #expect(notifications.pendingIdentifiers == Set([currentIdentifier]))
        #expect(fixture.model.isMonitoring)
        #expect(notifications.authorizationRequestCount == 1)
    }

    @Test("La pulizia iniziale tardiva preserva l'episodio successivo", arguments: [false, true])
    @MainActor
    func startupCleanupPreservesLaterEpisode(stopInsteadOfRecovering: Bool) async throws {
        let notifications = ControlledPostureNotificationCenter()
        notifications.add(makePendingPostureRequest(identifier: "poseguard.posture.previous-episode.stale"), withCompletionHandler: nil)
        notifications.defersPendingQueries = true
        let fixture = PostureLifecycleFixture(notifications: notifications)
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        fixture.endEpisode(byStopping: stopInsteadOfRecovering)
        await drainPostureCallbacks()
        fixture.clock.advance(by: 5)
        if stopInsteadOfRecovering { fixture.model.startMonitoring() }
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        let currentIdentifier = try #require(notifications.addedRequests.last?.identifier)

        notifications.defersPendingQueries = false
        notifications.completeDeferredPendingQueries()
        await drainPostureCallbacks()

        #expect(notifications.pendingIdentifiers == Set([currentIdentifier]))
        #expect(fixture.model.isMonitoring)
    }

    @Test("Le query di un altro model preservano gli avvisi del processo corrente", arguments: [false, true])
    @MainActor
    func startupCleanupPreservesOtherInstances(releasesPreviousModel: Bool) async throws {
        let notifications = ControlledPostureNotificationCenter()
        notifications.add(makePendingPostureRequest(identifier: "poseguard.posture.previous-episode.stale"), withCompletionHandler: nil)
        notifications.defersPendingQueries = true
        let previousMotion = ControlledPostureMotionSource()
        var previousModel: PostureMonitorModel? = PostureMonitorModel(
            motionManager: previousMotion,
            notificationCenter: notifications,
            now: { Date(timeIntervalSince1970: 0) }
        )
        let previousModelIsReleased = { [weak previousModel] in previousModel == nil }
        defer { previousModel?.stopMonitoring() }
        previousModel?.startMonitoring()
        for _ in 0..<2 { previousMotion.send(PostureMotionSample(pitch: 16, roll: 0)) }
        await drainPostureCallbacks()
        let previousIdentifier = try #require(notifications.addedRequests.last?.identifier)
        if releasesPreviousModel { previousModel = nil }
        await drainPostureCallbacks()
        #expect(previousModelIsReleased() == releasesPreviousModel)

        let fixture = PostureLifecycleFixture(notifications: notifications)
        defer { fixture.model.stopMonitoring() }
        fixture.model.startMonitoring()
        fixture.sendBadSamples()
        await drainPostureCallbacks()
        let currentIdentifier = try #require(notifications.addedRequests.last?.identifier)
        #expect(currentIdentifier != previousIdentifier)

        notifications.defersPendingQueries = false
        notifications.completeDeferredPendingQueries()
        await drainPostureCallbacks()

        let expected = releasesPreviousModel ? [currentIdentifier] : [previousIdentifier, currentIdentifier]
        #expect(notifications.pendingIdentifiers == Set(expected))
        #expect(fixture.model.isMonitoring)
    }
}

private func makePendingPostureRequest(identifier: String) -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = "PoseGuard"
    content.body = "Bad Posture!"
    return UNNotificationRequest(
        identifier: identifier,
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 7, repeats: false)
    )
}

@MainActor
private struct PostureLifecycleFixture {
    let model: PostureMonitorModel
    let motion: ControlledPostureMotionSource
    let notifications: ControlledPostureNotificationCenter
    let clock: ControlledPostureClock

    init(notifications: ControlledPostureNotificationCenter? = nil) {
        let notifications = notifications ?? ControlledPostureNotificationCenter()
        let motion = ControlledPostureMotionSource()
        let clock = ControlledPostureClock()
        self.motion = motion
        self.notifications = notifications
        self.clock = clock
        self.model = PostureMonitorModel(
            motionManager: motion,
            notificationCenter: notifications,
            now: { clock.date }
        )
    }

    func sendBadSamples(count: Int = 2, stream: Int? = nil) {
        for _ in 0..<count {
            motion.send(PostureMotionSample(pitch: 16, roll: 0), stream: stream)
        }
    }

    func endEpisode(byStopping: Bool) {
        if byStopping { model.stopMonitoring() }
        else { motion.send(PostureMotionSample(pitch: 0, roll: 0)) }
    }
}

private final class ControlledPostureClock {
    private(set) var date = Date(timeIntervalSince1970: 0)

    func advance(by interval: TimeInterval) {
        date.addTimeInterval(interval)
    }
}

private final class ControlledPostureMotionSource: PostureMotionSource {
    var isDeviceMotionAvailable = true
    var authorizationStatus: CMAuthorizationStatus = .authorized
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var lastStopWasOnMainThread: Bool?
    private var handlers: [(PostureMotionSample?, Error?) -> Void] = []
    private var disconnectionHandlers: [() -> Void] = []

    func startUpdates(_ handler: @escaping (PostureMotionSample?, Error?) -> Void, onDisconnect: @escaping () -> Void) {
        startCount += 1
        handlers.append(handler)
        disconnectionHandlers.append(onDisconnect)
    }

    func stopUpdates() {
        stopCount += 1
        lastStopWasOnMainThread = Thread.isMainThread
    }

    func send(_ sample: PostureMotionSample?, error: Error? = nil, stream: Int? = nil) {
        let index = stream ?? handlers.count - 1
        guard handlers.indices.contains(index) else {
            Issue.record("Il model non ha avviato lo stream motion richiesto.")
            return
        }
        handlers[index](sample, error)
    }

    func disconnect(stream: Int? = nil) {
        let index = stream ?? disconnectionHandlers.count - 1
        guard disconnectionHandlers.indices.contains(index) else {
            Issue.record("Il model non ha registrato il callback di disconnessione richiesto.")
            return
        }
        disconnectionHandlers[index]()
    }
}

@MainActor
private final class ControlledPostureNotificationCenter: PostureNotificationCenter {
    var defersAdds = false
    var defersPendingQueries = false
    var authorizationGranted = true
    var additionError: Error?
    private(set) var authorizationRequestCount = 0
    private(set) var addedRequests: [UNNotificationRequest] = []
    var pendingIdentifiers: Set<String> { Set(pendingRequests.keys) }

    private struct DeferredAdd {
        let request: UNNotificationRequest
        let completion: (@Sendable (Error?) -> Void)?
    }

    private var pendingRequests: [String: UNNotificationRequest] = [:]
    private var deferredAdds: [DeferredAdd] = []
    private var deferredQueries: [@Sendable ([UNNotificationRequest]) -> Void] = []

    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping @Sendable (Bool, Error?) -> Void) {
        authorizationRequestCount += 1
        completionHandler(authorizationGranted, nil)
    }

    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?) {
        addedRequests.append(request)
        if defersAdds { deferredAdds.append(DeferredAdd(request: request, completion: completionHandler)) }
        else { completeAdd(request, completion: completionHandler) }
    }

    func getPendingNotificationRequests(completionHandler: @escaping @Sendable ([UNNotificationRequest]) -> Void) {
        if defersPendingQueries { deferredQueries.append(completionHandler) }
        else { completionHandler(Array(pendingRequests.values)) }
    }

    nonisolated func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        Task { @MainActor in
            for identifier in identifiers { pendingRequests.removeValue(forKey: identifier) }
        }
    }

    func completeDeferredAdds() {
        let additions = deferredAdds
        deferredAdds.removeAll()
        for addition in additions { completeAdd(addition.request, completion: addition.completion) }
    }

    func completeDeferredPendingQueries() {
        let queries = deferredQueries
        deferredQueries.removeAll()
        for completion in queries { completion(Array(pendingRequests.values)) }
    }

    func simulateDelivery(of identifier: String) {
        pendingRequests.removeValue(forKey: identifier)
    }

    private func completeAdd(_ request: UNNotificationRequest, completion: (@Sendable (Error?) -> Void)?) {
        if let error = additionError {
            completion?(error)
            return
        }
        pendingRequests[request.identifier] = request
        completion?(nil)
    }
}

@MainActor
private func drainPostureCallbacks() async {
    // Campioni e completion delle notifiche attraversano turni distinti del main thread.
    for _ in 0..<3 {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
