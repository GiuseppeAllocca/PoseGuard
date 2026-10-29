# PoseGuard: stato dei lavori

Ultimo aggiornamento: 2026-10-29. Branch: `codex/poseguard-audit`.
Il registro dettagliato delle patch 1-12 (motivazioni, fonti Apple, verifiche) è nella cronologia Git: `git show f1a4edf:AUDIT.md`.

## Obiettivo

Rendere PoseGuard affidabile per un aggiornamento sull'App Store, conservando aspetto e animazioni. Il restyling grafico è in corso su un altro branch: qui si toccano il meno possibile le view.

## Fatto

- **Monitoraggio** (`Model/PostureMonitorModel.swift`): stati espliciti (`idle`, `starting`, `tracking`, `failed`), un solo motion manager, callback obsolete ignorate, errori Core Motion e consensi distinti.
- **Avvisi**: un solo avviso per episodio di cattiva postura, cancellato al recupero o allo stop; gli avvisi rimasti da processi precedenti vengono rimossi all'avvio.
- **Background** (2026-10-29): `UIBackgroundModes = audio` e `BackgroundAudioKeepAlive`, che durante il monitoraggio riproduce silenzio mescolato alle altre app, così iOS non sospende l'app a schermo bloccato. Riparte dopo un'interruzione (chiamata).
- **Privacy**: `PrivacyInfo.xcprivacy` (UserDefaults, ragione `CA92.1`), testo dell'onboarding corretto.
- **Interfaccia**: accessibilità e Reduce Motion su home e Tips, chiusura di Tips verso l'alto, testo di attesa non più tagliato, onboarding in inglese e italiano.
- **Test**: target collegati e scheme condiviso; 29 unit test (Swift Testing) e 7 UI test.
- **Diagnostica solo Debug**: log `com.giuseppe-allocca.PoseGuardApp`, categoria `Monitoraggio` (campioni, intervalli, lifecycle, avvisi), visibile da Console.app con l'iPhone collegato.

## Da verificare sull'iPhone con gli AirPods

1. Avvio del tracking, schermo bloccato per alcuni minuti, postura scorretta: arriva **un** avviso? Al rientro il tracking è ancora attivo?
2. Musica da un'altra app durante il monitoraggio: continua a suonare?
3. Chiamata durante il monitoraggio: dopo la chiamata il tracking riparte?
4. Rimozione e riconnessione degli AirPods, stop e riavvio.
5. VoiceOver e Reduce Motion su Tips e tracking.

## Aperto

- **Revisione App Store**: Apple accetta `audio` in background per contenuti udibili; un'app che riproduce solo silenzio rischia il rifiuto (linea guida 2.5.4). Da valutare prima della pubblicazione.
- Testi di onboarding e README dicono ancora «background non garantito»: aggiornarli dopo la prova 1.
- Pubblicazione: account e publisher da concordare con gli altri autori. Bundle ID e team attuali (`com.giuseppe-allocca.PoseGuardApp`) sono quelli di sviluppo.
- Privacy policy pubblica da riscrivere (oggi dichiara raccolte di dati che l'app non fa) e da collegare nell'app.
- Report con dati dimostrativi, non collegati a uno storico; calibrazione personale assente (soglia fissa ±15°).
- Consumo di batteria del monitoraggio in background da misurare.

## Come si verifica

```bash
xcodebuild test -project PoseGuard.xcodeproj -scheme PoseGuard -destination 'platform=iOS Simulator,name=iPhone 17'
```
