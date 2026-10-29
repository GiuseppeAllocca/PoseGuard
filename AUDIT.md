# PoseGuard: stato dei lavori

Ultimo aggiornamento: 2026-10-29. Branch: `codex/poseguard-audit`.
Il registro dettagliato delle patch 1-12 (motivazioni, fonti Apple, verifiche) è nella cronologia Git: `git show f1a4edf:AUDIT.md`.

## Obiettivo

Rendere PoseGuard affidabile per un aggiornamento sull'App Store. Il 2026-10-29 è stato unito il restyling di Stefano Acri (`feature/ui-restyling` su `AcriStefano/PoseGuard`): grafica, report e view vengono da lì, model e background da questo branch.

## Fatto

- **Monitoraggio** (`Model/PostureMonitorModel.swift`): stati espliciti (`idle`, `starting`, `tracking`, `failed`), un solo motion manager, callback obsolete ignorate, errori Core Motion e consensi distinti.
- **Avvisi**: un solo avviso per episodio di cattiva postura, cancellato al recupero o allo stop; gli avvisi rimasti da processi precedenti vengono rimossi all'avvio.
- **Background** (2026-10-29): `UIBackgroundModes = audio` e `BackgroundAudioKeepAlive`, che durante il monitoraggio riproduce silenzio mescolato alle altre app, così iOS non sospende l'app a schermo bloccato. Riparte dopo un'interruzione (chiamata).
- **Privacy**: `PrivacyInfo.xcprivacy` (UserDefaults, ragione `CA92.1`), policy dentro l'app (`PrivacyPolicyView`) e `PRIVACY.md` da pubblicare.
- **Interfaccia** (restyling): home con pulsante centrale, Tips e report come sheet, sessioni reali salvate sul dispositivo da `SessionStore`, Dynamic Type, VoiceOver, Reduce Motion. App solo in inglese.
- **Collegamento restyling-model**: `TrackingView` usa lo stato del model (`starting`, `tracking`, `failed`) invece di un secondo motion manager; la sessione inizia col primo campione e si salva allo stop o a un errore, che compare in un alert.
- **Test**: target collegati e scheme condiviso; 32 unit test (Swift Testing, compresi `SessionTests`) e 5 UI test.
- **Diagnostica solo Debug**: log `com.giuseppe-allocca.PoseGuardApp`, categoria `Monitoraggio` (campioni, intervalli, lifecycle, avvisi), visibile da Console.app con l'iPhone collegato.

## Prove sull'iPhone con gli AirPods

Riuscite secondo Giuseppe il 2026-10-29:

1. Avvio del tracking, schermo bloccato per alcuni minuti, postura scorretta: arriva un solo avviso e al rientro il tracking è ancora attivo.
2. Musica da un'altra app durante il monitoraggio: continua a suonare.
3. Chiamata durante il monitoraggio: dopo la chiamata il tracking riparte.

Ancora da fare:

4. Rimozione e riconnessione degli AirPods, stop e riavvio.
5. VoiceOver e Reduce Motion su Tips e tracking.
6. Dopo il merge del restyling: ripetere le prove 1-3 e controllare che il report mostri le sessioni.

## Aperto

- **Revisione App Store**: Apple accetta `audio` in background per contenuti udibili; un'app che riproduce solo silenzio rischia il rifiuto (linea guida 2.5.4). Da valutare prima della pubblicazione.
- Pubblicazione: account e publisher da concordare con gli altri autori. Bundle ID e team attuali (`com.giuseppe-allocca.PoseGuardApp`) sono quelli di sviluppo.
- Privacy policy pubblica: sostituire quella attuale (dichiara raccolte di dati che l'app non fa) con `PRIVACY.md`, ospitata a un URL per App Store Connect.
- Calibrazione personale assente (soglia fissa ±15°).
- Consumo di batteria del monitoraggio in background da misurare.

## Come si verifica

```bash
xcodebuild test -project PoseGuard.xcodeproj -scheme PoseGuard -destination 'platform=iOS Simulator,name=iPhone 17'
```
