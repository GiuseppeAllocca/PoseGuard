# PoseGuard: audit e registro delle modifiche

Ultimo aggiornamento: 2026-10-25.

## Obiettivo e stato

Riprendere PoseGuard e preparare un aggiornamento affidabile per l'App Store, preservando l'animazione ordinaria, la schermata principale e l'impostazione dell'onboarding. Prima si verificano il comportamento attuale e i difetti; poi si concordano correzioni puntuali, misurate e accompagnate da test.

Stato corrente: audit statico e undici patch del checkpoint completati, seguiti dalla patch di stabilizzazione hardware approvata sui sei file. La build del 2026-10-25 sul Simulator iPhone 17 con iOS 27.0 è riuscita e la suite completa contiene ottantacinque esecuzioni riuscite, zero fallimenti e zero test saltati. L’undicesima patch sostituisce nell’onboarding il report non disponibile con i suggerimenti, localizza le tre istruzioni in inglese e italiano e riallinea il README alla soglia fissa e all’assenza di calibrazione personale. La nona patch corregge layout del testo di attesa, posizione della maniglia di Tips e accumulo degli avvisi nello stesso episodio. Su successiva indicazione di Giuseppe, la decima patch porta gesto e animazione di chiusura di Tips verso l’alto, conservando la maniglia in basso. Il gesto aggiornato è verificato dagli UI test e confermato da Giuseppe sull’iPhone; il testo di attesa e la presentazione delle notifiche a schermo bloccato richiedono ancora conferma sulla patch successiva al checkpoint. L’ottava patch aggiunge la chiusura dei suggerimenti, etichette esplicite, gestione del focus e adattamento a Reduce Motion in home e Tips. Il test UI verifica tappabilità e flusso di apertura, chiusura e riapertura; VoiceOver attivo e movimento durante il tracking reale restano da verificare. Le tre deprecazioni affrontate nella settima patch non compaiono; rimane il warning della sessione debug: l’analisi successiva lo colloca nelle chiusure esplicite degli UI test, senza una dimostrazione definitiva della causa. Il model supera il controllo completo di concorrenza del compilatore in Swift 5 senza diagnostiche ed è isolato sul MainActor, compreso il rilascio. Il manifest è incluso nel bundle; la pulizia degli avvisi riconoscibili preserva il processo corrente. L’app non è ancora pronta per un aggiornamento affidabile sull’App Store: restano policy pubblica e link, limiti delle notifiche dopo terminazione, background e prove con hardware reale, funzioni dimostrative, accessibilità e configurazione di pubblicazione da chiarire.

Aggiornamento dopo il checkpoint: Giuseppe conferma Tips funzionante. Il testo di attesa rimane tagliato nella parte inferiore soltanto durante l'avvio del tracking. Dopo il blocco dello schermo, con app avviata dall'icona, gli AirPods restano indossati e connessi via Bluetooth ma PoseGuard mostra «AirPods non collegate» e l'avviso non arriva. La patch approvata sui sei file stabilizza la geometria del tracking, corregge il messaggio relativo al canale Motion e aggiunge diagnostica Debug. La suite da ottantacinque esecuzioni verifica questa patch sul Simulator; la causa dell’interruzione a schermo bloccato e il taglio transitorio sull’iPhone restano da verificare.

Il branch di lavoro è `codex/poseguard-audit`, creato da `main`. Il commit iniziale è `f055feff7e8e77232fab1e3537efb9fb2828e1ef`. Il riferimento locale `origin/main` coincideva con quel commit; non è stato eseguito un fetch, quindi non è dimostrato l'allineamento attuale con GitHub.

Prima prova su hardware riferita da Giuseppe: testo di attesa tagliato, maniglia e trascinamento di Tips da correggere, due notifiche identiche contemporanee a schermo bloccato. Dopo la nona patch Giuseppe ha riferito che Tips scorre verso il basso, precisando che la chiusura desiderata è invece verso l’alto. La correzione di direzione, approvata sui tre file, è applicata nella decima patch e la suite completa ha nuovamente superato ottanta esecuzioni. Alla fine della decima patch, chiusura aggiornata, testo di attesa e avvisi richiedevano conferma sulla build fisica; gli esiti successivi sono riportati nella ripresa hardware.

## Checkpoint di ripresa del 2026-10-24

Sezione **nuova**, richiesta da Giuseppe per salvare il lavoro e pubblicare il branch. Questa revisione riunisce gli undici interventi approvati: monitoraggio e lifecycle, cancellazione e identificazione delle notifiche, un solo avviso per episodio continuo, retry e callback obsolete, manifest privacy, deprecazioni, accessibilità e Reduce Motion di home e Tips, testo di attesa, chiusura di Tips verso l’alto, istruzioni bilingui dell’onboarding e README coerente con la soglia fissa. Non costituisce il completamento dell’obiettivo App Store.

Repository locale: `/Users/giuseppeallocca/Documents/GitHub/PoseGuard`. Branch: `codex/poseguard-audit`. Destinazione di pubblicazione: `origin`, `https://github.com/GiuseppeAllocca/PoseGuard.git`. I sorgenti coincidono con quelli della suite dell’undicesima patch: **ottantuno esecuzioni riuscite, settantacinque unit e sei UI, zero fallimenti, zero test saltati e zero errori**, sul Simulator iPhone 17 con iOS 27.0. Prima del salvataggio è stato verificato l’hash di tutti i quaranta file della baseline. In questa fase cambia soltanto `AUDIT.md`; non è necessaria una nuova esecuzione della suite per il solo aggiornamento documentale.

Il 2026-10-24 Giuseppe ha segnalato che l’app non si avviava sull’iPhone perché il Developer App Certificate non era attendibile. È stata indicata la procedura Apple da Impostazioni → Generali → VPN e gestione dispositivi, relativa all’account che firma la build. Giuseppe ha poi confermato «perfetto ora va». Questo prova il recupero dell’avvio secondo il suo resoconto; non certifica ancora le tre prove funzionali seguenti. Il dispositivo è l’iPhone 17 dell’Academy; iOS 27.1 e AirPods 4 sono informazioni riferite da Giuseppe. Installazione e uso del telefono restano a suo carico.

Primo passo della ripresa: raccogliere un esito distinto per il testo di attesa delle cuffie interamente leggibile, la chiusura di Tips verso l’alto con riapertura e la ricezione di un solo avviso durante un episodio continuo di Bad Posture a schermo bloccato. Se un caso fallisce, ottenere i passaggi di riproduzione prima di cambiare codice. Se i casi riescono, proseguire con consensi negati e riabilitati, stop, rimozione e riconnessione delle cuffie e comportamento in background. La continuità richiede timestamp o altra evidenza dello stream: la sola consegna di una notifica già programmata non la dimostra.

Il warning `Debug session ended with code 9: killed` è stato approfondito in sola lettura nel result bundle `onboarding-final.xcresult`. Il log dell’azione contiene sei sessioni dell’app con questo avviso; i processi corrispondono esattamente a quelli terminati dai sei UI test. La fine di ciascuna sessione cade nell’intervallo dell’attività esplicita `Terminate`, fra centodiciotto e centotrentaquattro millisecondi dopo la sua richiesta. Tutti i sei UI test riescono; il log di build non contiene warning. Questi dati sono compatibili con la chiusura richiesta dai test, ma non sono una prova definitiva della causa o della stabilità sull’hardware. Non è stata rimossa la chiusura dei test per nascondere l’avviso e non è stato avviato un esperimento aggiuntivo. Il log console separato non è disponibile nel bundle; l’analisi usa il log dell’azione e le attività dei test.

Le decisioni ancora aperte restano quelle del registro: publisher e account da concordare con gli altri autori; privacy policy pubblica, gestore, contatto e collegamento nell’app; comportamento reale in background, energia e attendibilità delle soglie; VoiceOver, Dynamic Type, contrasto e localizzazioni residue. I report rimangono dimostrativi e non accessibili dalla home, senza storico reale; la calibrazione personale non è implementata. Prima di nuove funzionalità servono priorità concordate e verifiche della base esistente.

La configurazione Xcode da salvare include il Team di sviluppo personale già presente e il bundle identifier `com.giuseppe-allocca.PoseGuardApp`. È la configurazione della copia di sviluppo, non una decisione sul publisher o sull’identità dell’aggiornamento App Store. Non viene ripristinata né modificata in questo salvataggio.

Il commit previsto comprende soltanto i quindici file già approvati: `Model/PostureMonitorModel.swift`; `PoseGuard (3.0)/Localizable.xcstrings`, `PoseGuard__3_0_App.swift` e `PrivacyInfo.xcprivacy`; le view `MyTipsView.swift`, `Myreportview.swift`, `Onboarding.swift` e `TrackingView.swift`; il file unit test e i due file UI test; `PoseGuard.xcodeproj/project.pbxproj` e `xcshareddata/xcschemes/PoseGuard.xcscheme`; `README.md` e `AUDIT.md`. Sono **nuovi in Git** il manifest, lo scheme condiviso e questo registro. Nessun altro sorgente viene modificato. Il push è destinato soltanto a `codex/poseguard-audit`, senza forzature o merge su `main`.

Artefatto **nuovo**: `build/poseguard-audit/checkpoint-2026-10-24-summary.json`, con baseline, hash correnti, riferimento alla suite precedente ed esito della pubblicazione, completato dopo la verifica del commit remoto. Log, screenshot, result bundle e riepiloghi locali restano nella cartella già ignorata e non vengono inclusi nel commit. Gli hash del precedente riepilogo differiranno soltanto per `AUDIT.md`, aggiornato qui; le evidenze storiche non vengono sovrascritte.

Per riprendere in una nuova chat, usare questa repository e questo branch, leggere prima questa sezione e poi soltanto i rilievi pertinenti. L’obiettivo complessivo rimane rendere PoseGuard affidabile per l’App Store preservando identità e animazioni ordinarie; il prossimo Goal deve delimitare la fase e le evidenze necessarie. Restano le istruzioni di Giuseppe: italiano chiaro, piano dei file e approvazione prima delle modifiche, interventi puntuali, niente cancellazioni senza consenso specifico, terminale prima dell’interfaccia grafica e subagenti soltanto con autorizzazione e quota sufficiente. Wiki, profilo personale, policy esterna e pubblicazione su App Store richiedono interventi separati.

Fonti per il blocco di avvio: [sample Apple con istruzioni per il Personal Team](https://developer.apple.com/documentation/appclip/fruta-building-a-feature-rich-app-with-swiftui) e [supporto Apple sulla verifica del certificato e connessione Internet](https://support.apple.com/it-it/118254). Le precedenti frasi «nessun commit o push» nei registri delle singole patch descrivono lo stato storico di quelle fasi, precedente a questo salvataggio.

## Ripresa su hardware dopo il checkpoint

Sezione **nuova**. Il resoconto di Giuseppe distingue ora i tre casi: Tips riuscito; testo tagliato soltanto durante l'avvio, con la parte inferiore delle lettere mancante; prova di un solo avviso a schermo bloccato non superata, perché nessun avviso arriva e al rientro compare l'errore di connessione. Giuseppe chiarisce che blocca soltanto lo schermo, apre l'app dall'icona e mantiene gli AirPods indossati e connessi via Bluetooth. Sono osservazioni riferite dall'utente, non misure dirette dell'assistente.

Nel codice, l'alone da centosettanta punti entra nello stesso ZStack del pulsante da centocinquanta punti soltanto durante il tracking. Il test mirato prima della correzione ha misurato uno spostamento verticale di dieci punti tra attesa e tracking: l’ingombro ridistribuiva gli spazi della VStack. Il testo cambiava inoltre contenuto e altezza dentro una transazione animata. La patch assegna al pulsante un ingombro stabile di centocinquanta punti e separa la dimensione del messaggio dalla geometria verticale, mantenendo una transizione di opacità. Il taglio transitorio riferito sull’iPhone non è ancora riprodotto direttamente dall’assistente. Il messaggio di cuffie scollegate proviene dal callback di disconnessione del manager Motion; non misura autonomamente la connessione Bluetooth. Il gestore arresta la sessione e cancella gli avvisi pendenti. Senza timestamp non si può stabilire se la cancellazione preceda la scadenza dell'avviso né perché il canale Motion sia stato interrotto.

Piano approvato da Giuseppe: modifica puntuale di `TrackingView.swift`, `PostureMonitorModel.swift`, `Localizable.xcstrings`, file unit test, file UI test e questo registro. Geometria stabile del pulsante e verifica del testo durante l'avvio; messaggio coerente con l'interruzione Motion; diagnostica **nuova** soltanto in Debug, con timestamp, conteggi e intervalli fra campioni, lifecycle e operazioni sulle notifiche; sequenza controllata **nuova** soltanto in Debug sul Simulator, attivata dagli UI test. Nessuna modifica a onboarding, Tips, report dimostrativi, soglie, firma, publisher o modalità background.

La diagnostica non registra pitch o roll, non invia dati e non crea uno storico di postura. I riepiloghi cumulativi vengono emessi al primo campione, al massimo una volta ogni cinque secondi durante lo stream e agli eventi di lifecycle, stop, errore e notifiche. L'assenza di log da sola non dimostra una causa di sospensione; i timestamp del sensore e quelli di elaborazione vanno confrontati insieme agli eventi. La raccolta su dispositivo avverrà in una prova concordata dopo la verifica sul Simulator, avviando l'app dall'icona.

Verifiche preliminari. La baseline **nuova** `build/poseguard-audit/hardware-stabilization-before.json` conserva gli hash dei quaranta file tracciati. Il primo tentativo da Xcode è rimasto sulla destinazione fisica e si è fermato alla firma dei test, prima dell'esecuzione; nessuna installazione sul telefono e nessuna modifica alla firma. Dopo aver verificato la selezione di iPhone 17 Simulator, la compilazione ha individuato una cattura non valida dell'autoclosure nel logger. Il risultato **nuovo** `hardware-stabilization-build-first.xcresult` e il JSON associato conservano l'errore. La closure viene ora valutata prima dell'interpolazione OSLog; l'emissione del modulo Debug con controllo completo di concorrenza riesce. Questi controlli preliminari non sostituiscono i test applicativi.

Verifica completa del 2026-10-25: build riuscita senza warning di compilazione; ottantacinque esecuzioni riuscite, zero fallimenti, zero test saltati. Il risultato **nuovo** `build/poseguard-audit/hardware-stabilization-verified.xcresult` e i JSON associati conservano l’esito. Rimane soltanto «Debug session ended with code 9: killed» nell’esecuzione dei test; le chiusure esplicite dell’app sono conservate. I tre test diagnostici aggiunti verificano separatamente intervalli del sensore ed elaborazione, timestamp assenti/non finiti e callback obsolete dopo stop o riavvio. Il nuovo UI test verifica inglese e italiano nei quattro stati: centro verticale invariato a 327,5 punti, contro lo spostamento di dieci punti misurato prima della correzione. Gli screenshot **nuovi** mostrano il testo italiano completo su due righe. Il test misura anche i frame durante la transizione: non sostituisce l’ispezione dei pixel né la prova sul dispositivo.

Il model emette correttamente i moduli Debug per Simulator e dispositivo, e il modulo senza `DEBUG`, con controllo completo di concorrenza Swift 5 e senza diagnostiche. L’ispezione dei simboli conferma che la sorgente di movimento simulato è presente soltanto nel modulo Debug del Simulator; la struttura diagnostica è assente dal modulo senza `DEBUG`. Queste verifiche non equivalgono a una build Release completa o a un’esecuzione sull’iPhone. Il catalogo delle traduzioni è valido: contiene soltanto le due chiavi aggiunte, con inglese e italiano, senza variazioni alle chiavi precedenti.

Resta da concordare una prova sull’iPhone con la nuova build Debug, avvio dall’icona e raccolta dei messaggi del sottosistema `com.giuseppe-allocca.PoseGuardApp`, categoria `Monitoraggio`. [Apple documenta la raccolta dei messaggi da un iPhone collegato tramite Console](https://support.apple.com/en-ca/guide/console/cnsl1012/mac) e la [persistenza dei messaggi di livello notice entro i limiti di conservazione](https://developer.apple.com/documentation/os/generating-log-messages-from-your-code). L’obiettivo è confrontare lifecycle, conteggi, intervalli e programmazione/cancellazione degli avvisi durante il blocco dello schermo. Nessuna prova di consensi, stop, riconnessione o continuità in background è dichiarata superata sulla base dei test simulati. Tips, già confermato dall’utente, non richiede una nuova prova ordinaria.

## Punto di ripresa salvato su richiesta di Giuseppe

**Stato operativo al 2026-10-22: lavoro sospeso su richiesta di Giuseppe, che ha quasi esaurito la quota disponibile e vuole riprendere nella prossima sessione.** L'obiettivo complessivo non è completato. Questa sezione, **nuova** al momento del salvataggio, integra il registro dettagliato. Il salvataggio del 2026-10-22 modificava soltanto questo documento. Giuseppe ha poi richiesto la ripresa il 2026-10-23 e approvato esplicitamente la patch privacy sui cinque file elencati, privilegiando modifiche dirette e terminale rispetto all’interfaccia grafica.

### Passaggio a Giuseppe delle prove su dispositivo

Sezione **nuova**, aggiornata il 2026-10-23 su richiesta di Giuseppe. Giuseppe installerà e proverà personalmente la build locale sul dispositivo che identifica come **«il mio iPhone 17 dell’Academy»**, con gli AirPods 4 già dichiarati. L’assistente aggiorna il registro; l’installazione e le interazioni sul telefono restano affidate a Giuseppe. Questa conferma non dimostra che una prova sia già stata eseguita e non autorizza ulteriori modifiche ai sorgenti senza il relativo piano.

Il punto di partenza è il branch locale `codex/poseguard-audit` nella repository `/Users/giuseppeallocca/Documents/GitHub/PoseGuard`. Prima di questo aggiornamento documentale, tutti gli hash del checkpoint `accessibility-final-summary.json` coincidevano con i file presenti. L’ultima suite sul Simulator contiene settantasei esecuzioni riuscite; non viene ripetuta per un cambiamento soltanto documentale.

Giuseppe aveva indicato iOS 27.1; la destinazione fisica elencata da Xcode riportava iOS 27.0.1. Nel successivo resoconto della prova Giuseppe ha confermato iOS 27.1; è una versione riferita dall’utente, non letta direttamente dall’assistente sul telefono. Non è stata dedotta una corrispondenza dalla sola etichetta di Xcode e non sono state modificate firma, bundle identifier o destinazione di esecuzione. L’elenco da terminale non è stato recuperato: CoreDeviceService non ha completato l’inizializzazione; questo non dimostra che il telefono sia scollegato.

Campi **nuovi** del resoconto manuale, da compilare con le osservazioni: data della prova, versione iOS effettiva, lingua dell’app, modello di AirPods, stato dei consensi Motion e notifiche, prova eseguita, risultato atteso, risultato osservato ed eventuali passaggi per riprodurre il problema. Per ogni riga usare «riuscita», «fallita» o «non eseguita»; non trasformare l’assenza di un problema osservato in una verifica completa.

| Prova manuale | Che cosa controllare | Stato attuale |
| --- | --- | --- |
| Installazione e avvio | Apertura della build locale; eventuali errori di firma o installazione da riportare prima di cambiare configurazione | Giuseppe conferma il 2026-10-24 che ora funziona dopo la procedura di attendibilità del certificato; non è un resoconto puntuale degli altri test |
| Onboarding e lingua | Riaprire l’onboarding dalla home, completarlo e tornare alla home; verificare leggibilità e nuove etichette nella lingua usata | Da eseguire da Giuseppe |
| Tips e chiusura | Aprire i suggerimenti, chiudere con la croce e riaprire; provare anche trascinamento e tap sullo sfondo; il pannello nascosto non deve bloccare la home | Giuseppe segnala X funzionante, swipe verso il basso non funzionante e maniglia troppo alta; altri passaggi non verificati puntualmente |
| Avvio e stop con AirPods | Indossare gli AirPods, avviare il monitoraggio, osservare attesa e arrivo dello stato attivo; arrestare e ripetere. Il solo avvio non dimostra uno stream continuo di campioni validi | Giuseppe riferisce testo di attesa tagliato e raggiungimento di Bad Posture; stop e ripetizioni ancora da verificare |
| Disconnessione e ripresa | Osservare rimozione, disconnessione e riconnessione delle cuffie; annotare messaggio, stato del pulsante e modalità di riavvio, senza equiparare automaticamente rimozione e disconnessione | Da eseguire da Giuseppe |
| Consensi e notifiche | Annotare i consensi già presenti; osservare gli eventuali prompt e il comportamento dopo una scelta. Segnare come non verificati i rami che non si sono presentati, senza azzerare dati o reinstallare per ottenerli | Da eseguire da Giuseppe |
| Avvisi dopo recupero o stop | Quando si riesce a osservare un episodio fuori soglia, recuperare o arrestare prima dell’avviso e annotare tempi e stato dell’app. La sola mancata comparsa di un banner non prova la cancellazione dei pendenti | Da eseguire da Giuseppe |
| VoiceOver | Aprire Tips, verificare focus su Chiudi, esplorazione limitata al pannello, chiusura tramite pulsante ed escape e ritorno del focus a Tips. Gli UI test non sostituiscono questa prova | Da eseguire da Giuseppe |
| Reduce Motion | Attivare la preferenza e osservare Tips e tracking: niente spostamento automatico del pannello, onde, pulsazione o rotazione; il drag segue ancora il dito. Cambiare la preferenza durante il tracking e confrontare con le animazioni ordinarie | Da eseguire da Giuseppe |
| Rientro dal background | Uscire dall’app, bloccare lo schermo e rientrare, annotando durata, stato e avvisi. Un avviso ricevuto non dimostra monitoraggio continuo in background | Da eseguire da Giuseppe |

Le misure avanzate già elencate nella sezione hardware, come timestamp dei campioni, angoli e pendenti del centro notifiche, richiedono evidenze ulteriori rispetto alla sola osservazione della schermata. Non vengono dichiarate disponibili né superate da questa checklist. I risultati forniti da Giuseppe andranno distinti da eventuali verifiche osservate direttamente dall’assistente.

Il solo passaggio documentale delle prove a Giuseppe modificava **soltanto `AUDIT.md`**: in quel momento gli altri file coincidevano ancora con `accessibility-final-summary.json` e non erano stati rigenerati result bundle. La successiva nona patch modifica i sei file approvati e dispone del proprio riepilogo storico `device-bugs-final-summary.json`. Il riepilogo della decima patch è conservato in `tips-up-final-summary.json`. La suite dell’undicesima patch è conservata in `onboarding-final-summary.json`. Il checkpoint documentale e l’esito della pubblicazione del branch sono registrati in `checkpoint-2026-10-24-summary.json`. Nessuna prova fisica della nuova build viene marcata come riuscita senza il relativo resoconto di Giuseppe.

### Prima prova reale: anomalie riferite da Giuseppe

Resoconto **nuovo** ricevuto il 2026-10-23. Giuseppe conferma di avere usato il proprio iPhone 17 dell’Academy con **iOS 27.1** e riferisce tre problemi. L’assistente non ha osservato direttamente il telefono né identificato il binario installato; il resoconto viene distinto dalla verifica del codice locale e dai risultati del Simulator.

| Osservazione riferita | Riscontro nel codice attuale | Stato |
| --- | --- | --- |
| Dopo Tap To Track il testo di attesa delle cuffie appare tagliato | La risorsa attuale è `Waiting for headphone motion…`; il Text usa dimensione fissa e non riserva esplicitamente l’altezza necessaria al testo su più righe. La causa precisa del clipping non è ancora misurata sul dispositivo | Correzione da approvare e verificare |
| La maniglia di Tips è troppo in alto; lo swipe verso il basso non chiude il pannello, mentre la X funziona | Il pannello sottrae cento punti all’altezza disponibile; la gesture accetta solo traslazioni e velocità negative, quindi verso l’alto. Giuseppe chiede esplicitamente la chiusura verso il basso | Correzione da approvare e verificare |
| Due avvisi identici di postura sono arrivati insieme a schermo bloccato, durante Bad Posture | Il model può programmare richieste distinte ogni cinque secondi, ciascuna con trigger dopo sette. Due richieste possono quindi rimanere pendenti contemporaneamente. Il test `notificationCadenceIsPreserved` si aspetta esplicitamente due pendenti | Difetto di accumulo verificato nel codice; causa della singola consegna simultanea non tracciata |

Giuseppe riferisce che per il resto l’app funziona. Questo giudizio generale non viene trasformato in un esito positivo dei test non descritti: VoiceOver, Reduce Motion, tutti i rami di consenso, stop, riconnessione e continuità in background restano da verificare puntualmente. L’arrivo di notifiche a schermo bloccato non dimostra elaborazione continua del movimento mentre l’app è sospesa.

Intervento successivamente **approvato e applicato**, limitato a sei file esistenti; la verifica è registrata nella nona patch sotto:

- `PoseGuard (3.0)/View/TrackingView.swift`: rendere il testo di stato leggibile su più righe, con spazio verticale e margini adeguati, senza cambiare il messaggio o il comportamento del monitoraggio.
- `PoseGuard (3.0)/View/MyTipsView.swift`: correggere altezza e safe area per portare la maniglia al fondo del pannello, darle un’area di trascinamento adeguata e supportare la chiusura verso il basso da maniglia e intestazione, mantenendo lo scroll dei suggerimenti, la X, escape e Reduce Motion.
- `Model/PostureMonitorModel.swift`: proporre un solo avviso per episodio continuo fuori soglia, conservando il ritardo iniziale di sette secondi e la cancellazione al recupero o allo stop. Nuovo episodio o nuova sessione possono generare un altro avviso, rispettando il cooldown esistente; un errore di registrazione non deve impedire definitivamente il retry.
- `PoseGuard (3.0)Tests/PoseGuard__3_0_Tests.swift`: sostituire l’aspettativa dei due pendenti con test della politica approvata; proteggere ritardo, recupero, riavvio, errori e callback tardive con clock e servizi controllati.
- `PoseGuard (3.0)UITests/PoseGuard__3_0_UITests.swift`: verificare trascinamento e riapertura di Tips, oltre alla chiusura esistente. È previsto un identificatore tecnico **nuovo** per la maniglia, destinato ai test, senza una nuova etichetta visibile.
- `AUDIT.md`: aggiornare registro, risultati e limiti; nuovi artefatti di verifica soltanto nella cartella `build/poseguard-audit` già ignorata.

La proposta sugli avvisi è un cambiamento funzionale deliberato: elimina i promemoria ripetuti durante lo stesso episodio, invece di conservare la precedente frequenza. Giuseppe ha approvato esplicitamente questa politica prima della modifica di model e test. Usare soltanto un identificatore fisso e rischedularlo ogni cinque secondi non sarebbe sufficiente: Apple documenta che una nuova richiesta con lo stesso identificatore sostituisce quella pendente, spostandone quindi il trigger. Fonte: [UNNotificationRequest.identifier](https://developer.apple.com/documentation/usernotifications/unnotificationrequest/identifier).

Per ora non vengono richiesti altri test esplorativi a Giuseppe. Dopo la correzione occorrerà ripetere prima i tre casi segnalati e poi le verifiche di accessibilità già pianificate. Al momento del resoconto gli hash dei sorgenti coincidevano ancora con la suite da settantasei esecuzioni e l’aggiornamento riguardava soltanto il registro. La nona patch successiva introduce la riparazione approvata e deve essere verificata separatamente.

### Che cosa è già salvato

La repository da riaprire è `/Users/giuseppeallocca/Documents/GitHub/PoseGuard`, sul branch `codex/poseguard-audit`. Le modifiche sono nei file locali, senza commit, push o PR. Non creare un worktree: Giuseppe ha chiesto di lavorare su un branch nella repository esistente. Non eseguire reset, checkout distruttivi o pulizie della cartella `build/`.

| File locale | Stato da conservare |
| --- | --- |
| `Model/PostureMonitorModel.swift` | Confronto della soglia verificabile, servizi sostituibili nei test, cancellazione selettiva degli avvisi pendenti, protezione dalle callback obsolete e unico proprietario del motion manager |
| `PoseGuard (3.0)/View/TrackingView.swift` | Stato visibile derivato dal model, attesa annullabile, errori distinti, azioni accessibili e animazioni legate al tracking effettivo |
| `PoseGuard (3.0)/Localizable.xcstrings` | Quindici risorse aggiunte in inglese e italiano; chiave dinamica esistente conservata con estrazione manuale |
| `PoseGuard (3.0)Tests/PoseGuard__3_0_Tests.swift` | Unit test deterministici su soglie, notifiche, callback, autorizzazioni e stati del monitoraggio |
| `PoseGuard (3.0)UITests/PoseGuard__3_0_UITests.swift` | Verifiche di onboarding, Tips e ritorno allo stato inattivo quando non arrivano dati Motion |
| `PoseGuard (3.0)UITests/PoseGuard__3_0_UITestsLaunchTests.swift` | Verifica della home al lancio e screenshot allegato |
| `PoseGuard.xcodeproj/project.pbxproj` | Associazione dei sorgenti test ai target e correzione del target applicativo degli UI test; contiene anche impostazioni di signing osservate successivamente, non introdotte dalla terza patch |
| `PoseGuard.xcodeproj/xcshareddata/xcschemes/PoseGuard.xcscheme`, file **nuovo** già creato nella prima patch | Scheme condiviso che abilita entrambi i target test; ancora non tracciato da Git |
| `AUDIT.md`, file **nuovo** già creato all'inizio dell'audit | Registro delle modifiche, evidenze e lavoro residuo; ancora non tracciato da Git |

La verifica del salvataggio aveva rilevato otto file di lavoro oltre a questo registro. Il confronto delle impronte temporanee era stato interrotto: alla ripresa del 2026-10-23 sono stati invece confrontati con il riepilogo finale gli hash dei cinque sorgenti verificati dalla terza patch e del progetto, tutti coincidenti. La quarta patch conserva inoltre una baseline dei file per verificare il proprio perimetro. Il progetto aveva già cambiamenti di bundle identifier e team rispetto alla prima patch: conservarli e chiarirne l'origine con Giuseppe prima di pubblicare. L'hash del progetto preservato nella verifica finale della terza patch è `cee32bfa279310638a60ae9474a8afae66046aa6e2078868b4a4ef00c29e61b1`.

### Verifica applicativa disponibile al checkpoint

La suite disponibile al checkpoint del 2026-10-22, descritta nella terza patch, contiene **sessantasette esecuzioni riuscite, zero fallimenti e zero test saltati** sul Simulator iPhone 17 con iOS 27.0: diciannove casi sulle soglie, sedici su notifiche e callback, ventotto sugli stati del monitoraggio e quattro UI test. Il salvataggio documentale non costituisce una nuova esecuzione della suite. Le verifiche successive sono registrate nelle patch dalla quarta all’undicesima. `build/poseguard-audit/onboarding-final-summary.json` conserva l’ultima suite completa e gli hash della versione provata; `build/poseguard-audit/checkpoint-2026-10-24-summary.json` conserva gli hash del salvataggio successivo, che aggiorna soltanto questo registro, e l’esito effettivo della pubblicazione. I riepiloghi delle patch precedenti restano evidenze storiche delle rispettive versioni.

Sono stati ricontrollati e risultano presenti questi artefatti nella cartella già ignorata `build/poseguard-audit/`:

- `lifecycle-final.xcresult`: result bundle finale, autorità per gli esiti dei test.
- `lifecycle-final-summary.json`: riepilogo degli esiti e hash dei sorgenti verificati; i file `lifecycle-final-object.json` e `lifecycle-final-details.json` conservano l'estrazione originale.
- `lifecycle-final-localizations.json`: controllo delle risorse effettive in inglese e italiano nel bundle compilato.
- `home-after-lifecycle-patch.png`: screenshot della home inattiva, ispezionato visivamente.

Gli artefatti della prima e della seconda patch, i tentativi falliti e i rispettivi limiti sono descritti nel registro sotto. Essendo ignorati da Git, non verranno inclusi automaticamente in un futuro commit: conservarli localmente se occorre mantenere le evidenze. I sorgenti e lo scheme nuovi richiederanno invece una scelta esplicita di tracciamento quando Giuseppe autorizzerà un commit.

Per ripetere la verifica usare Xcode con lo scheme `PoseGuard`, confermando nella toolbar **iPhone 17 Simulator**, non la destinazione fisica, prima dell'azione Test. Un precedente clic sulla riga del menu non aveva confermato il cambio: la selezione da tastiera e il controllo della destinazione attiva hanno risolto. Le build da terminale avevano incontrato limiti di sandbox/CoreSimulator; non aggirarli. Non azzerare dati o permessi per ottenere un test verde. Rimane il warning `Debug session ended with code 9: killed`, la cui causa non è stata isolata.

### Ricerca privacy completata dopo la terza patch

Al checkpoint del 2026-10-22 la quarta patch era **soltanto proposta e non approvata né applicata**, il manifest non esisteva e onboarding e README erano ancora invariati. La patch è stata approvata e applicata alla ripresa del 2026-10-23; il registro della quarta patch sotto riporta lo stato aggiornato.

Nel codice esaminato la preferenza `hasCompletedOnboarding` usa `@AppStorage`, quindi UserDefaults. Non sono emersi import di SDK esterni o chiamate di rete nelle ricerche svolte; questo non certifica l'intera cronologia o il binario pubblicato. Apple richiede la motivazione dell'uso delle API UserDefaults interessate: per una preferenza accessibile soltanto all'app è prevista la ragione `CA92.1`. Apple distingue inoltre l'elaborazione esclusivamente sul dispositivo dalla raccolta ai fini dell'etichetta privacy: ciò non elimina il requisito del manifest.

Il paragrafo nell'onboarding promette un funzionamento continuo in background non dimostrato e rinvia a un manuale non raggiungibile; il relativo pulsante è commentato. Non basta riattivare il collegamento esistente senza controllarne il contenuto.

La policy effettivamente collegata alla scheda Store è stata recuperata tramite browser dopo il fallimento del tool di consultazione web: [Privacy Policy for PoseGuard](https://www.freeprivacypolicy.com/live/7d44c828-95ce-4c13-adda-6f75a48b7f3d), con data dichiarata 2025-03-18. Il testo dichiara raccolta automatica di IP, identificatori e dati d'uso, finalità di marketing e possibile condivisione con partner. Tali trattamenti non risultano nel codice esaminato e non coincidono con la dichiarazione di mancata raccolta della scheda Store. La policy contiene il contatto pubblico di Matteo Cotena; non riutilizzarlo per una diversa pubblicazione senza concordarlo. La presenza di un testo generato da un template non dimostra il trattamento effettivo dell'app.

Giuseppe ha risposto che aggiornare la scheda esistente oppure pubblicare dal proprio account è **da decidere con gli altri autori**. Anche policy, responsabile della sua gestione e contatto pubblico sono **da definire**. Non pubblicare, modificare servizi esterni o scrivere agli altri autori sulla base di queste risposte.

Fonti aggiuntive consultate per questa fase:

- [Ragioni ammesse per le API interessate](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons).
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/): definizione di raccolta e trattamento soltanto sul dispositivo.
- [Configurazione dell'esecuzione in background](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes): iOS può sospendere le app; una dichiarazione di funzionamento continuo richiede un meccanismo appropriato e prove reali.
- [Scelta delle strategie background](https://developer.apple.com/documentation/BackgroundTasks/choosing-background-strategies-for-your-app).

### Piano privacy approvato alla ripresa

Il messaggio di sospensione autorizzava soltanto il salvataggio. Il 2026-10-23 Giuseppe ha poi confermato esplicitamente il piano seguente, limitato a questi cinque file e alle verifiche indicate. Non occorre richiederne nuovamente l’approvazione.

| File approvato | Contenuto del piano confermato |
| --- | --- |
| `PoseGuard (3.0)/PrivacyInfo.xcprivacy`, **nuovo** | Manifest per la preferenza UserDefaults, con motivazione propria dell'app; nessun tracking o dato raccolto dichiarato, da verificare rispetto al codice corrente |
| `PoseGuard (3.0)/View/Onboarding.swift` | Sostituire soltanto il paragrafo privacy, eliminando la garanzia di background continuo e il rinvio al manuale inesistente; preservare struttura e animazioni |
| `PoseGuard (3.0)/Localizable.xcstrings` | Aggiornare quel testo in inglese e italiano |
| `README.md` | Precisare i limiti attuali di privacy e background, conservando lingua inglese e crediti |
| `AUDIT.md` | Registrare trattamento dei dati, bozza tecnica della futura policy, modifiche e verifiche; mantenere esplicite le decisioni editoriali e di pubblicazione ancora aperte |

Testo italiano **nuovo**, approvato e inserito nell’onboarding nella quarta patch:

> I dati di movimento sono elaborati sul dispositivo. PoseGuard salva la preferenza dell'onboarding e usa notifiche locali. Il monitoraggio continuo in background non è garantito.

Il piano comprende build e suite esistente da Xcode sul Simulator, controllo del manifest nel bundle compilato e artefatti **nuovi** nella cartella ignorata già esistente. Non comprende la pubblicazione di una policy, un nuovo link nell'app o cambiamenti di signing. Se servono ulteriori file, presentarli prima della modifica. L'approvazione App Store e l'inclusione nel futuro archive restano verifiche successive.

### Lavoro restante e regole di ripresa

Prima di modificare altro, controllare branch e diff correnti e confrontare i sorgenti con gli hash del riepilogo finale: il contenuto della repository può cambiare fra le sessioni. Leggere questa sezione e le parti pertinenti del registro; evitare di ripetere l'intero audit e i test soltanto perché cambia la sessione. Non confondere il successo della suite con la completezza del progetto.

Dopo la privacy restano almeno: residui di notifiche dopo terminazione forzata del processo; continuità e comportamento al ritorno dal background; prove con AirPods 4 e iPhone di Giuseppe; permessi reali e firma dei target test; report attualmente dimostrativi e non collegati a uno storico reale; accessibilità, Reduce Motion e localizzazioni residue; misure di performance ed energia; attendibilità della classificazione posturale e delle promesse nella descrizione Store; provenienza della versione pubblicata, diritti e account di pubblicazione; valutazione delle funzionalità utili dopo la stabilizzazione. Le sezioni sotto descrivono già i rilievi e non vanno considerate risolte dalla patch sul monitoraggio.

Giuseppe richiede italiano chiaro e formale, spiegazioni brevi prima dei dettagli, nessun caveman visibile, cambiamenti puntuali con piano e approvazione preventiva, nessuna cancellazione senza consenso specifico. Le revisioni indipendenti erano autorizzate se la quota lo permette; prima di avviarne altre ricontrollare disponibilità e costo, dato il motivo della sospensione. Non creare altre chat o automazioni per proseguire da soli. La wiki, il profilo, la policy esterna e App Store Connect non sono stati aggiornati: richiedono interventi separati concordati con Giuseppe.

## Modifiche effettuate e motivazioni

| Elemento | Modifica effettuata | Motivo | Effetto sull'app |
| --- | --- | --- | --- |
| Branch Git | Creato `codex/poseguard-audit` | Separare il lavoro di verifica da `main`, nella stessa repository come richiesto da Giuseppe | Nessuno |
| `AUDIT.md`, nuovo | Aggiunto questo registro | Conservare evidenze, limiti, motivazioni e interventi ancora da approvare | Nessuno |
| `build/poseguard-audit/`, nuova | Raccolti log e risultati generati dalla build | Rendere ispezionabile la verifica senza aggiungere artefatti generati al controllo versione | Nessuno; la cartella `build/` è già esclusa dal `.gitignore` esistente |
| Xcode e Device Hub | Aperto il progetto, compilato, avviata l'app sul Simulator ed eseguite verifiche manuali; tentata l'esecuzione dei test automatici | Verificare build e flussi visibili al di fuori dei limiti del terminale controllato | Nell'app simulata è stato completato l'onboarding e negato il consenso alle notifiche; nessuna modifica ai sorgenti o alle impostazioni condivise |

La tabella precedente descrive la fase iniziale dell'audit. Non sono stati eseguiti commit, push, installazioni sul dispositivo fisico o pubblicazioni. La patch approvata successivamente modifica il model, i test e la configurazione elencati qui sotto. Xcode conserva inoltre log e dati generati nelle sue normali directory di servizio, oltre agli artefatti raccolti nella repository.

### Prima patch approvata: rendere effettiva la verifica

Giuseppe ha approvato il piano del primo intervento. I tre template dei test sono stati sostituiti con verifiche di comportamento; negli altri file sono state applicate modifiche puntuali.

| File | Modifica applicata | Motivo |
| --- | --- | --- |
| `Model/PostureMonitorModel.swift` | Estratto `isPostureWithinThreshold(pitch:roll:)`, funzione interna statica **nuova**, e centralizzata la costante immutabile della soglia | Verificare il confronto senza istanziare un motion manager. La negazione del confronto originale preserva esattamente il risultato, compresa la soglia inclusiva a quindici gradi |
| `PoseGuard.xcodeproj/project.pbxproj` | Aggiunti i due gruppi sincronizzati delle cartelle test, assegnati ai rispettivi target; corretto `TEST_TARGET_NAME` in Debug e Release | Compilare i sorgenti dei test e permettere agli UI test di individuare `PoseGuard` |
| `PoseGuard (3.0)Tests/PoseGuard__3_0_Tests.swift` | Corretto l'import al modulo `PoseGuard`; aggiunto un test parametrizzato con diciannove campioni espliciti | Verificare posizione neutra, segni, soglia esatta, valori immediatamente esterni e combinazioni dei due assi, senza hardware |
| `PoseGuard (3.0)UITests/PoseGuard__3_0_UITests.swift` | Aggiunti tre test su onboarding, apertura dei Tips e avviso senza cuffie; helper interni per l'avvio in inglese e lo stato iniziale | Verificare flussi osservabili con assert e attese sulle condizioni, senza disinstallare l'app o azzerare dati |
| `PoseGuard (3.0)UITests/PoseGuard__3_0_UITestsLaunchTests.swift` | Aggiunti assert sulla home e screenshot allegato; tolte le ripetizioni automatiche del template | Dimostrare che il lancio raggiunge una schermata utilizzabile, conservando un'immagine del risultato |
| `PoseGuard.xcodeproj/xcshareddata/xcschemes/PoseGuard.xcscheme`, **nuovo** | Condiviso lo scheme con entrambi i target test abilitati | Rendere riproducibile la selezione dei target da un altro checkout |
| `AUDIT.md` | Aggiornati stato, registro, motivazioni e limiti | Distinguere la baseline senza test dalla suite introdotta e dalle correzioni funzionali ancora da fare |

Non sono cambiati bundle identifier, signing, deployment target, dipendenze, risorse grafiche o catalogo delle traduzioni. Il confronto dei gruppi/prodotti con lo scheme, la sintassi del progetto e il formato XML sono stati verificati con strumenti. Una revisione indipendente non ha trovato differenze semantiche nell'estrazione del confronto né incoerenze dei riferimenti test.

I test UI usano l'inglese per rendere deterministici i selettori già presenti. Gli helper cercano i dialoghi Motion e Notifications di PoseGuard sul Simulator e selezionano il rifiuto. I selettori dei dialoghi di sistema richiedono SpringBoard in inglese: la lingua forzata dell'app, da sola, non lo garantisce. Il test senza cuffie viene esplicitamente saltato sul dispositivo fisico, dove la disponibilità dell'hardware non è controllata.

Durante la prima esecuzione XCTest ha accettato automaticamente Motion sul Simulator. Dopo questa osservazione gli helper sono stati corretti e l'intera suite è stata ripetuta; non sono stati azzerati dati o permessi. Un consenso già memorizzato non viene revocato e l'assenza del dialogo non dimostra il ramo di rifiuto: primo consenso, Motion negato ed effettiva attivazione dell'interruption monitor restano da verificare in una prova dedicata. La protezione dei prompt è limitata al Simulator; prima di eseguire questi test sull'iPhone occorre definire la gestione dei suoi permessi.

Esito finale letto dal result bundle completato: **ventitré esecuzioni riuscite, zero fallimenti e zero test saltati**. Sono diciannove campioni del test parametrizzato e quattro test UI: riapertura e completamento dell'onboarding, apertura dei Tips, avviso senza cuffie e lancio fino alla home. Il numero non rappresenta ventitré funzioni di test distinte né copertura completa dell'app.

Le evidenze locali sono raccolte in `build/poseguard-audit/`, cartella esclusa dal controllo versione:

- `tests-final.xcresult`: result bundle finale copiato dalla directory di Xcode.
- `tests-final-summary.json`: conteggi ed elenco degli esiti estratti dal bundle; `tests-final-object.json` e `tests-final-details.json` conservano i dati sorgente dell'estrazione.
- `home-after-patch.png`: screenshot allegato al launch test, esportato e ispezionato visivamente; la home mantiene l'aspetto osservato nella baseline. Non è una misura delle animazioni o dell'accessibilità.

Il bundle finale riporta il warning `Debug session ended with code 9: killed`, senza errori di build o test falliti. La causa di questo warning non è stata isolata; la suite riuscita non dimostra l'assenza di crash nell'uso reale. Restano inoltre gli avvisi di deprecazione già osservati nella build iniziale.

### Seconda patch approvata: avvisi pendenti e sessioni del model

Giuseppe ha approvato il piano su model, file unit test, registro ed evidenze generate. L'intervento preserva la regola esistente: un campione fuori soglia può programmare l'avviso se anche lo stato precedente era scorretto. Partendo dallo stato iniziale corretto, il primo avviso richiede quindi due campioni scorretti; dopo uno stop con postura scorretta può bastare il primo campione del riavvio, come nella baseline. Restano l'intervallo minimo di cinque secondi fra programmazioni e il ritardo di sette secondi. Non introduce una diversa durata minima della postura scorretta né azzera postura e cooldown fra sessioni.

| File | Intervento e stato | Motivo |
| --- | --- | --- |
| `Model/PostureMonitorModel.swift` | Applicati due protocol interni e un campione in gradi, **nuovi**, con adapter delle API native e clock sostituibile; aggiunti identificatore della sessione e prefisso delle richieste posturali, **nuovi** | Verificare senza hardware o prompt; distinguere sessioni ed episodi senza conservare un elenco crescente di richieste nel model |
| `PoseGuard (3.0)Tests/PoseGuard__3_0_Tests.swift` | Aggiunte dieci funzioni di test **nuove**, con sedici esecuzioni deterministiche su recupero, stop, riavvio e completamenti tardivi | Verificare le sequenze asincrone senza attendere secondi reali o usare i permessi del Simulator |
| `AUDIT.md` | Aggiornati stato, motivazioni, evidenze ed esiti | Conservare il limite fra comportamento verificato e lavoro ancora aperto |

Ogni avviso mantiene un identificatore distinto: riutilizzarne uno ogni cinque secondi sostituirebbe la richiesta ancora in attesa dei sette secondi e potrebbe rinviarne continuamente la consegna. Recupero e stop invalidano il prefisso dell'episodio e richiedono la cancellazione selettiva delle relative richieste pendenti. Se `add` termina dopo l'invalidazione, la completion richiede nuovamente la rimozione del proprio identificatore. Una sessione successiva usa un identificatore diverso; i campioni e gli errori accodati della sessione precedente vengono ignorati prima di aggiornare lo stato. Il model ignora un ulteriore comando di avvio mentre risulta già in monitoraggio; questo non risolve ancora le verifiche concorrenti nella view.

Nella seconda patch le notifiche di errore erano rimaste separate. La terza le sostituisce con gli alert descritti nel registro seguente. La cancellazione di User Notifications è asincrona e non ritira una notifica il cui trigger è già scattato: non garantisce la rimozione di avvisi già consegnati. Al termine della seconda patch il prefisso apparteneva alla vita del model: una terminazione senza `deinit` poteva lasciare richieste non riconosciute dal model successivo. La quinta patch introduce la pulizia dei residui riconoscibili dei processi precedenti, con i limiti registrati sotto. Al termine della seconda patch rimanevano i manager concorrenti della view e lo stato visibile dopo un errore, affrontati nella terza. La continuità reale dei sensori in background richiede ancora prove con AirPods.

Verifica finale: build e azione Test riuscite da Xcode; il result bundle completato contiene **trentanove esiti riusciti, zero fallimenti e zero test saltati**. Sono diciannove campioni sulle soglie, sedici sequenze del model e quattro test UI esistenti. Il conteggio delle esecuzioni comprende le diverse combinazioni dei test parametrizzati, non trentanove funzioni distinte.

| Sequenza nuova verificata | Esecuzioni |
| --- | --- |
| Recupero oppure stop con avviso già pendente | Due |
| Registrazione dell'avviso completata dopo recupero oppure stop | Due |
| Campioni ed errori di una sessione conclusa, anche dopo riavvio | Due |
| Campioni ed errori già accodati prima dello stop, anche dopo riavvio | Due |
| Vecchia query di cancellazione completata dopo un nuovo avviso valido | Due |
| Vecchia registrazione completata dopo un nuovo avviso valido | Due |
| Primo avviso, cooldown di cinque secondi, trigger di sette secondi e identificatori distinti | Una |
| Conservazione di postura e cooldown fra stop e riavvio | Una |
| Cancellazione selettiva che preserva gli avvisi di errore | Una |
| Rilascio del model con registrazione ancora pendente | Una |

Le evidenze **nuove**, sempre nella cartella ignorata `build/poseguard-audit/`, sono `notifications-tests-final.xcresult`, `notifications-tests-final-object.json`, `notifications-tests-final-details.json` e `notifications-tests-final-summary.json`. Il riepilogo registra anche gli hash dei due sorgenti verificati. `home-after-notifications-patch.png` è lo screenshot del launch test, esportato e ispezionato: la home conserva l'aspetto della baseline. Gli artefatti precedenti, inclusi `notifications-tests.xcresult` e il suo riepilogo, sono conservati senza sovrascrittura.

La prima esecuzione della seconda patch aveva già superato trentanove casi, ma segnalava un warning nel test sul rilascio del model. Il riferimento debole è stato espresso tramite una closure con weak capture e la suite completa è stata ripetuta: quel warning non compare nel risultato finale. Resta `Debug session ended with code 9: killed`, già presente nella prima patch, la cui causa non è stata isolata; il risultato finale non riporta errori di build o test falliti. Gli avvisi di deprecazione della build iniziale restano registrati nella baseline.

Una revisione indipendente ha verificato model, test e ordine delle completion senza trovare difetti certi o falsi verdi nei percorsi esaminati. I fake controllano gli ordini delle callback, non l'esecuzione simultanea su thread differenti o la sospensione dell'app; rimuovono subito le richieste cancellate. Dimostrano quindi quali richieste il model chiede di annullare, non la latenza reale di User Notifications o l'assenza di consegne già iniziate. La continuità dei sensori, i permessi da zero e l'uso con AirPods reali restano da verificare.

### Terza patch approvata: un solo proprietario del monitoraggio

Giuseppe ha approvato modifiche puntuali a model, view, unit test, catalogo e registro; ha poi autorizzato anche l'aggiornamento dell'assert nel test UI dell'avviso senza cuffie. Non sono stati creati nuovi file sorgente né aggiunte dipendenze.

| File | Modifica applicata | Motivo |
| --- | --- | --- |
| `Model/PostureMonitorModel.swift` | Introdotti wrapper nativo e delegate di sessione **nuovi**, proprietari dell'unico `CMHeadphoneMotionManager`; aggiunto stato **nuovo** con inattività, avvio, tracking ed errore | Evitare manager concorrenti e dichiarare il tracking soltanto dopo un campione finito e senza errore |
| `PoseGuard (3.0)/View/TrackingView.swift` | Eliminati manager e probe duplicati, stato di tracking locale e timeout di un secondo; pulsante, messaggio e animazioni derivati dal model | Impedire avvii sovrapposti e falsi errori mentre l'utente risponde al consenso; consentire l'annullamento dell'attesa |
| `PoseGuard (3.0)Tests/PoseGuard__3_0_Tests.swift` | Adeguati contratto e fake; aggiunte otto funzioni di test **nuove**, con ventotto combinazioni | Verificare primo campione, autorizzazioni, avvio ripetuto, errori, disconnessione, dati non finiti e invalidazione delle callback |
| `PoseGuard (3.0)/Localizable.xcstrings` | Aggiunte quindici risorse **nuove** in inglese e italiano, con estrazione manuale; mantenuta manualmente anche la chiave dinamica esistente `AirPods not connected` | Rendere comprensibili stato di attesa, cause dell'arresto e azioni disponibili; preservare tutti i testi preesistenti ed evitare che l'estrazione automatica consideri obsoleta una chiave ancora usata |
| `PoseGuard (3.0)UITests/PoseGuard__3_0_UITests.swift` | Adeguato il test dell'avvio senza dati ai motivi preliminari possibili e all'attesa annullabile; aggiunta la verifica finale di assenza di alert e disponibilità dell'avvio | Non presumere il consenso del Simulator; verificare un ritorno utilizzabile allo stato inattivo |
| `AUDIT.md` | Aggiornati stato e registro | Conservare esiti, motivazioni e limiti della fase corrente |

Il pulsante ha etichette accessibili **nuove** per avvio, annullamento e stop. L'accessibility identifier **nuovo** conserva il selettore `Airpods Pro` già usato dai test, separandolo dal testo pronunciato da VoiceOver. Layout, risorse grafiche e parametri delle animazioni ordinarie restano quelli esistenti; il loro avvio e arresto dipendono ora dallo stato effettivo del model. `onDisappear` arresta il model quando la view viene rimossa, per esempio riaprendo l'onboarding; non è stata aggiunta una politica di stop su `scenePhase` o una modalità background.

La richiesta Notifications è stata rimossa dall'inizializzazione e dalla view: avviene una sola volta per model, dopo il primo campione valido. Il rifiuto delle notifiche non impedisce il tracking. Consenso Motion negato o limitato, indisponibilità, errori di configurazione, disconnessione ed errore generico producono motivi distinti e arrestano lo stream prima che campioni tardivi possano ripristinare il tracking. Gli errori sono presentati nell'app; le vecchie notifiche di errore ritardate non vengono più programmate. Postura e cooldown persistono fra sessioni come prima; soglie e tempi degli avvisi posturali non sono cambiati.

L'attesa senza campioni è visibile e annullabile, senza un timeout che possa scadere durante il prompt Motion. Se il framework non produce né dati né errori né eventi di disconnessione, l'attesa può continuare indefinitamente: questo limite è esplicito e richiede prova sull'iPhone. Non è stata dimostrata la continuità in background o la tempestività reale dei delegate.

Verifica finale: build e azione Test riuscite sul Simulator iPhone 17 con iOS 27.0; **sessantasette esiti riusciti, zero fallimenti e zero test saltati**. Sono diciannove casi sulle soglie, sedici su notifiche e callback adeguati al nuovo contratto, ventotto combinazioni nuove sugli stati del monitoraggio e quattro test UI. Non sono sessantasette funzioni distinte. Il bundle finale riporta soltanto il warning della sessione di debug `Debug session ended with code 9: killed`, già presente nelle fasi precedenti e la cui causa non è stata isolata; gli avvisi di deprecazione della baseline restano da modernizzare separatamente.

Il primo tentativo di Test era rimasto sulla destinazione fisica e si è fermato per team di firma assente nei target test, prima di eseguire casi. Dopo la conferma esplicita della destinazione iPhone 17 Simulator, la prima suite ha eseguito sessantasette casi: sessantasei riusciti e un test UI fallito. L'allegato della gerarchia UI mostra `Motion access denied` con `Open Settings`; il test si aspettava erroneamente sempre l'indisponibilità del servizio, ignorando il consenso negato del Simulator. Il test è stato corretto per i motivi preliminari previsti, escludendo errori generici e tracking prematuro, e rafforzato per richiedere l'assenza di alert dopo chiusura o annullamento. La successiva estrazione automatica di Xcode ha marcato una chiave dinamica ancora usata come `stale`: è stata mantenuta con estrazione manuale, senza modificare la traduzione, prima della verifica finale.

Le evidenze **nuove** sono raccolte nella cartella ignorata `build/poseguard-audit/`: `lifecycle-final.xcresult`, `lifecycle-final-object.json`, `lifecycle-final-details.json` e `lifecycle-final-summary.json`. Il riepilogo contiene gli hash dei cinque sorgenti verificati e del progetto preservato. `lifecycle-final-localizations.json` registra il controllo dei sedici valori effettivi per lingua nel bundle compilato: quindici nuovi e la chiave dinamica esistente, tutti presenti sia in inglese sia in italiano. Tutte le traduzioni preesistenti sono rimaste identiche; l'unica variazione di metadata su una chiave esistente è l'estrazione manuale descritta sopra. `home-after-lifecycle-patch.png` è lo screenshot del launch test, esportato e ispezionato: l'aspetto della home inattiva è conservato. Non dimostra la fluidità dell'animazione durante l'uso dei sensori.

Sono conservati anche `lifecycle-signing-attempt.xcresult`, `lifecycle-first-pass.xcresult` e `lifecycle-first-pass-failure-hierarchy.txt` per distinguere gli ostacoli di verifica dai risultati finali. Non sono stati azzerati i permessi, cambiati team o bundle identifier, installati nuovi SDK, eseguiti commit o push. I target test sul dispositivo fisico richiedono ancora la configurazione della firma prima di poterli eseguire su hardware.

Una revisione indipendente di produzione e test non ha rilevato bug concreti nei percorsi esaminati. Il test dell'attesa usa callback senza dati e ripetuti comandi di avvio; variare il clock posturale non simula ore di funzionamento o un timeout reale. Ogni esecuzione UI attraversa il ramo incontrato nella configurazione corrente: la classificazione dei singoli motivi è verificata separatamente dagli unit test. Prompt Motion, delegate nativo, rimozione degli auricolari e background richiedono ancora hardware reale.

Nella configurazione già presente all'inizio della verifica da Xcode sono stati osservati bundle identifier e team di firma diversi da quelli registrati nella prima patch. La terza patch non li modifica; l'hash del progetto è stato controllato per verificarne la conservazione. La build applicativa iniziale era sulla destinazione fisica. I test della patch vengono verificati sul Simulator iPhone 17, dopo il tentativo di firma descritto sopra. L'equivalenza con l'app distribuita deve essere chiarita prima di preparare un archive o pubblicare.

### Quarta patch approvata: manifest e chiarezza del trattamento dei dati

Registro **nuovo** del 2026-10-23. Giuseppe ha autorizzato esattamente i cinque file del piano e ha chiesto di contenere il consumo evitando l’interfaccia grafica quando non necessaria. Nessuna revisione parallela aggiuntiva è stata avviata.

| File | Modifica e motivo |
| --- | --- |
| `PoseGuard (3.0)/PrivacyInfo.xcprivacy`, **nuovo** | Dichiarato l’uso di UserDefaults per la preferenza propria dell’app, con ragione `CA92.1`; tracking pubblicitario disabilitato, nessun dominio di tracking e nessun dato raccolto dichiarato. Il tracking posturale è una funzionalità distinta dal tracking pubblicitario del manifest |
| `PoseGuard (3.0)/View/Onboarding.swift` | Sostituito soltanto il paragrafo privacy con informazioni su elaborazione sul dispositivo, preferenza salvata, notifiche locali e assenza di garanzia di monitoraggio continuo in background |
| `PoseGuard (3.0)/Localizable.xcstrings` | Sostituita la corrispondente chiave inglese e la traduzione italiana; tutte le altre risorse preservate |
| `README.md` | Precisate notifiche locali, limiti del background, preferenza salvata e documentazione privacy ancora da allineare; corretta la descrizione del contributo sugli avvisi conservando lingua e crediti |
| `AUDIT.md` | Aggiornati checkpoint, stato, inventario dati, bozza tecnica e verifiche |

Non è stata modificata la configurazione del progetto: il gruppo sincronizzato della cartella applicativa appartiene già al target e deve includere il manifest come risorsa. La presenza nel bundle viene verificata sul prodotto compilato, senza dedurla soltanto dalla struttura della repository. Non sono cambiati altri testi dell’onboarding, layout, modificatori visivi, animazioni, algoritmi, soglie o tempi. Non è stato riattivato il link a una policy incoerente né modificato alcun servizio esterno.

#### Inventario e bozza tecnica della policy, nuovi

Questa è una **bozza tecnica nuova da completare**, non una policy pubblicata o una verifica legale. Descrive il sorgente locale esaminato; publisher, responsabile della gestione, contatto pubblico, URL e data di efficacia restano da concordare con gli autori.

- Movimento: campioni delle cuffie elaborati sul dispositivo per classificare la postura e decidere gli avvisi; non è implementata la persistenza di uno storico posturale reale. Il report dimostrativo non prova la registrazione di sessioni dell’utente.
- Preferenza: `hasCompletedOnboarding` è un valore booleano persistito tramite `@AppStorage`/UserDefaults per scegliere la schermata iniziale.
- Avvisi: notifiche locali gestite da iOS. Il model richiede la rimozione delle richieste posturali pendenti al recupero, allo stop o all’errore; l’operazione è asincrona e non ritira necessariamente avvisi già consegnati. La quinta patch aggiunge la rimozione dei residui riconoscibili al riavvio del monitor; restano esclusi gli avvisi già consegnati e quelli delle versioni con identificatori non riconoscibili.
- Trasmissione: nel sorgente esaminato non risultano backend, analytics, advertising SDK o chiamate di rete. Questo non certifica l’app già distribuita né descrive i trattamenti autonomi di Apple o del sito che ospiterà la policy.
- Controllo: l’utente può arrestare il monitoraggio nell’app e gestire i permessi Motion e Notifications nelle impostazioni iOS. Il rifiuto delle notifiche non impedisce il monitoraggio.

Formulazione di partenza da sottoporre agli autori:

> PoseGuard elabora sul dispositivo i dati di movimento delle cuffie per fornire indicazioni posturali. La versione esaminata non li invia a un server e non conserva uno storico posturale reale. L’app salva la preferenza di completamento dell’onboarding e può programmare notifiche locali tramite iOS. Puoi arrestare il monitoraggio nell’app e gestire i permessi nelle impostazioni di sistema. Il monitoraggio continuo in background non è garantito.

Prima della pubblicazione completare identità e contatti, modalità e tempi effettivi di conservazione dei dati locali e degli avvisi, indicazioni di rimozione coerenti con iOS, trattamento dell’eventuale assistenza e del sito di pubblicazione. Verificare nuovamente tutte le affermazioni contro la build candidata alla distribuzione. La policy esterna attuale non è stata sostituita.

#### Verifiche della quarta patch

Il manifest supera `plutil -lint`; il catalogo aggiornato compila con `xcstringstool` per inglese e italiano. La ricostruzione delle due versioni precedenti conferma tramite hash che negli originali onboarding e catalogo sono cambiati soltanto il paragrafo e la relativa voce. Gli altri sorgenti e il progetto coincidono con la baseline precedente alla patch. Build e azione Test sono riuscite sul Simulator iPhone 17 con iOS 27.0. Il result bundle nuovo contiene **sessantasette esecuzioni riuscite, zero fallimenti e zero test saltati**; nessun test è stato aggiunto o modificato in questa patch. Il manifest incluso in `PoseGuard.app` è identico al sorgente. La risorsa italiana compilata contiene il testo aggiornato; in inglese il valore corretto viene risolto tramite il normale fallback alla chiave sorgente, senza una voce inglese duplicata. Questa verifica riguarda le risorse e la navigazione già coperta dalla suite, non una nuova ispezione visiva completa nelle due lingue.

Gli artefatti **nuovi**, nella cartella già ignorata `build/poseguard-audit/`, sono `privacy-source-before.json`, `privacy-localizations/`, `privacy-bundle-check.json`, `privacy-final.xcresult`, `privacy-final-object.json`, `privacy-final-details.json` e `privacy-final-summary.json`. Quest’ultimo registra esiti, warning e impronte dei cinque file approvati. La suite è stata avviata mediante il solo comando Test di Xcode dopo conferma del Simulator: non è stata ripetuta la build da terminale già bloccata dalla sandbox. Estrazione dei risultati, controllo del bundle, modifiche e verifiche statiche sono stati eseguiti da terminale. Il result bundle riporta quattro warning: tre riguardano la sendability delle completion di `requestAuthorization`, `add` e `getPendingNotificationRequests` nella conformità di `UNUserNotificationCenter` a `PostureNotificationCenter`; il quarto è `Debug session ended with code 9: killed`. I tre warning di concorrenza sono emersi in questa build nel model invariato rispetto alla terza patch: non sono stati corretti, perché il model e i relativi test non appartengono ai cinque file approvati. Xcode li segnala come errori nel language mode Swift 6; il progetto corrente resta in Swift 5. Occorre un intervento separato sul contratto delle callback, con test, prima di una migrazione. Gli avvisi di deprecazione della baseline restano aperti anche se questa build incrementale non li ripete. La causa del warning di debug resta da isolare.

Non sono stati creati altri file destinati al controllo versione oltre al manifest approvato. Restano separati il link privacy nell’app, la policy pubblica, l’archive, le prove con hardware e le altre criticità dell’audit. Il README conserva inoltre affermazioni preesistenti su altre funzionalità, per esempio la calibrazione, che questa patch non ha verificato né implementato.

### Quinta patch approvata: residui riconoscibili delle notifiche

Registro **nuovo** del 2026-10-23. Giuseppe ha approvato la correzione su model, unit test e questo documento, con artefatti di verifica nella cartella ignorata esistente. Non sono stati creati nuovi file sorgente o aggiunte dipendenze.

| File | Modifica e motivo |
| --- | --- |
| `Model/PostureMonitorModel.swift` | Aggiunti namespace esplicito e prefissi **nuovi** di processo e istanza. Alla costruzione del model viene interrogato il centro notifiche e richiesta la rimozione dei soli identificatori posturali appartenenti a processi precedenti |
| `PoseGuard (3.0)Tests/PoseGuard__3_0_Tests.swift` | Quattro funzioni **nuove**, ciascuna con due casi; la fixture accetta un centro controllato per predisporre richieste e query tardive. Helper **nuovo** per creare richieste riconoscibili e non riconoscibili con lo stesso contenuto |
| `AUDIT.md` | Aggiornati stato, registro, limiti ed evidenze |

Il namespace `poseguard.posture.` riconosce anche gli identificatori introdotti nella seconda patch. Le nuove richieste contengono, dopo il namespace, identificatori distinti per processo, istanza, episodio e richiesta. Il prefisso del processo viene generato una volta con UUID e condiviso fra le istanze; non è un identificatore del dispositivo e non è trasmesso. Ogni episodio e ogni richiesta continuano a essere distinti: non viene riprogrammata continuamente la stessa richiesta rinviandone la consegna.

La query iniziale cattura soltanto il centro e i prefissi immutabili; non trattiene il model. Il filtro esclude tutto il processo corrente, perché una query avviata da un model precedente può concludersi quando un’altra istanza ha già creato avvisi validi. La cancellazione ordinaria a recupero, stop ed errore resta invece specifica dell’episodio, così una vecchia cancellazione non rimuove gli avvisi di altre istanze o episodi. La query iniziale non avvia i sensori, non chiama `requestAuthorization` e non blocca il comando di avvio. Soglia, cooldown di cinque secondi, trigger di sette secondi e conservazione dello stato posturale sono invariati.

| Verifica nuova | Casi |
| --- | --- |
| Rimozione di residui riconoscibili nei due formati, preservando richieste estranee e UUID senza namespace anche con lo stesso contenuto | Due |
| Query iniziale completata dopo l’avviso corrente, con registrazione immediata oppure ritardata | Due |
| Query iniziale completata dopo recupero oppure stop e dopo la creazione dell’episodio successivo | Due |
| Query di un’altra istanza con model precedente ancora vivo oppure già rilasciato; nessuna rimozione di avvisi validi del processo corrente | Due |

La costruzione del model è verificata anche per stato inattivo, assenza di avvio dello stream e assenza di richieste di autorizzazione. I test riutilizzano il clock controllato e completano le query differite prima del teardown. Queste sequenze simulano richieste preesistenti e ordinamenti avversi delle callback: non equivalgono a una prova fisica di terminazione e rilancio del processo.

Limiti da mantenere espliciti:

- La pulizia scatta alla costruzione di un nuovo model. Se il processo è terminato, l’app non può eseguire codice per impedire la consegna di una richiesta già programmata prima del successivo avvio.
- Le richieste già consegnate non vengono ritirate. Le API di rimozione dei pendenti sono asincrone: una consegna già partita può precedere la rimozione.
- La versione iniziale del sorgente usava UUID senza namespace anche per notifiche di errore. Queste richieste non vengono cancellate per somiglianza del testo: non c’è un identificatore certo del tipo. La migrazione della build pubblicata resta da definire dopo averne identificato il sorgente e deciso l’account di distribuzione.
- Le richieste del processo corrente vengono preservate dalla pulizia iniziale; il loro annullamento rimane responsabilità delle cancellazioni di episodio già verificate. Non viene introdotto un coordinatore globale mutabile fra model.

Build e azione Test riuscite sul Simulator iPhone 17 con iOS 27.0: **settantacinque esecuzioni riuscite, zero fallimenti e zero test saltati**. Sono sessantasette esecuzioni già presenti e otto casi nuovi, tutti individuati nel result bundle. Il risultato include settantuno esecuzioni unit e quattro UI; non sono settantacinque funzioni distinte. Le sequenze su cadenza, recupero, stop, errori, deinit e callback tardive della suite precedente restano superate.

Le evidenze **nuove**, nella cartella ignorata `build/poseguard-audit/`, sono `restart-source-before.json`, `restart-final.xcresult`, `restart-final-object.json`, `restart-final-details.json` e `restart-final-summary.json`. Il riepilogo corrente contiene esiti, elenco degli otto casi aggiunti, warning e hash dei tre file modificati e di quelli preservati. Il confronto con la baseline e `git diff --check` verificano il perimetro della patch. Manifest, catalogo, view, README, progetto e scheme non sono cambiati in questa fase.

Il result bundle riporta gli stessi quattro warning della quarta patch: tre sul contratto di sendability delle API notifiche e uno sulla conclusione della sessione di debug con code 9. Non sono stati corretti né reinterpretati come prova di un crash dell’app. Gli avvisi di deprecazione della baseline restano aperti anche se la compilazione incrementale non li ripete. L’interfaccia Xcode è usata soltanto per avviare i test a causa del limite di sandbox già registrato; codice, documentazione e lettura delle evidenze sono gestiti direttamente sui file. I tre warning di sendability del contratto notifiche sono un intervento separato, non compreso in questa patch.

### Sesta patch approvata: contratto e isolamento delle callback

Registro **nuovo** del 2026-10-23. Giuseppe ha approvato modifiche a model, unit test e registro per correggere i tre warning di sendability, controllando anche le catture e mantenendo il progetto in Swift 5. Nessuna dipendenza, file sorgente del progetto o revisione parallela aggiuntiva.

Il controllo diretto del model con `swiftc -typecheck -swift-version 5 -strict-concurrency=complete`, SDK Simulator installato e deployment iOS 18.0, ha riprodotto **sette warning**: tre sulle firme native e quattro sulle catture di `self` e del centro notifiche. La compilazione ordinaria non mostrava questi ultimi. Correggere soltanto le tre firme avrebbe lasciato il problema di isolamento non verificato.

| File | Modifica e motivo |
| --- | --- |
| `Model/PostureMonitorModel.swift` | Contratto notifiche isolato sul `MainActor` e `Sendable`, callback esplicitamente `@Sendable`; model isolato sul `MainActor` e distruzione dichiarata `isolated deinit`, per vincolare accessi allo stato e rilascio all’executor corretto |
| `Model/PostureMonitorModel.swift` | Metodo puro della soglia e costante immutabile dichiarati `nonisolated`, preservando il calcolo senza vincoli UI; rimozione dei pendenti dichiarata `nonisolated`, coerentemente con la capacità dell’API nativa di essere invocata dalla callback senza accodare un nuovo hop sul main thread |
| `PoseGuard (3.0)Tests/PoseGuard__3_0_Tests.swift` | Fake notifiche isolato sul `MainActor`, firme e buffer delle completion allineati a `@Sendable`; la rimozione non isolata inoltra la mutazione del solo fake mediante un `Task` sul `MainActor` |
| `PoseGuard (3.0)Tests/PoseGuard__3_0_Tests.swift` | La fixture costruisce il fake nel proprio initializer isolato, evitando costruzione isolata nel valore di default dell’argomento; il test della pulizia iniziale attende il completamento asincrono con l’helper esistente, conservando gli assert |
| `PoseGuard (3.0)Tests/PoseGuard__3_0_Tests.swift` | Test di lifecycle **nuovo**: una barriera `AsyncStream` trattiene il model in un task detached, rilascia la reference del chiamante e consente poi il rilascio dal background; vengono verificati il thread dello stop e la rimozione degli avvisi |
| `AUDIT.md` | Registrati risultati del compilatore, motivazioni, perimetro e limiti |

Le annotazioni di isolamento sono **nuove** e non costituiscono una migrazione a Swift 6. Non sono stati aggiunti `@unchecked Sendable`, import `@preconcurrency`, esclusioni dei controlli o nuove build settings. Il riferimento al centro notifiche catturato dalle closure è ora vincolato a `Sendable`; le callback che leggono lo stato del model continuano a raggiungere il main executor attraverso i passaggi esistenti. I filtri sui prefissi usano valori immutabili. La rimozione di produzione conserva il percorso nativo; soltanto il fake accoda l’accesso al proprio dizionario isolato. La distruzione isolata mantiene lo stop sul main executor anche quando l’ultima reference viene rilasciata altrove: i casi di deinit e callback tardive restano nella suite.

Il sorgente effettivo del model supera adesso lo stesso controllo diretto con **zero warning e zero errori**. Questo è un controllo del file model, non una prova di concorrenza completa dell’intera app o della disponibilità di tutti i percorsi su dispositivo fisico. Non sono stati aggiunti test che replichino le annotazioni: il compilatore verifica i tipi e la suite esistente protegge i comportamenti. La prima compilazione applicativa e le settantacinque esecuzioni esistenti sono riuscite senza warning di sendability, con il solo warning di debug. Aggiunto il test di rilascio dal background, la suite completa ha superato **settantasei esecuzioni, zero fallimenti e zero test saltati**: settantadue esecuzioni unit e quattro UI.

Questa esecuzione ha però rilevato un warning nel test nuovo: `Thread.isMainThread` era letto nel corpo asincrono del task. La chiamata è stata rimossa da quel contesto; il thread dello stop continua a essere registrato nel metodo sincrono del fake. Il rilascio avviene nel task detached dopo una barriera `AsyncStream`, senza sleep. Sono rimasti gli assert su rilascio, numero degli stop, main thread dello stop e avvisi pendenti. Nessun sorgente applicativo o altro test è cambiato dopo la suite completa.

La nuova build e ripetizione mirata di questo solo caso sono riuscite: **una esecuzione, zero fallimenti, zero test saltati e zero warning**. Il confronto tramite hash con la versione precedente conferma che la correzione successiva riguarda soltanto quel corpo di test. I risultati non vengono sommati come settantasette casi distinti: il caso ripetuto appartiene già ai settantasei. Il warning `Debug session ended with code 9: killed` non compare nella ripetizione mirata, ma era presente nelle suite complete; la sua causa rimane da isolare e questo dato non prova né un crash applicativo né la sua innocuità.

Artefatti diagnostici **nuovi**, tutti nella cartella ignorata `build/poseguard-audit/`: `sendability-source-before.json`, `sendability-before-typecheck.log`, `sendability-after-typecheck.log`, `sendability-module-cache/`, `sendability-candidate.swift` e `sendability-candidate-typecheck.log`. Il candidato è una prova precedente conservata come evidenza, non il sorgente da ripristinare: per il codice attuale fanno fede `Model/PostureMonitorModel.swift` e il log `sendability-after-typecheck.log`. Nessun artefatto diagnostico è incluso nei gruppi sorgente del target.

Le evidenze applicative **nuove** sono `sendability-final.xcresult` con le corrispondenti estrazioni e riepilogo della prima suite, `sendability-lifecycle-final.xcresult` con le estrazioni e il riepilogo dei settantasei esiti, `sendability-test-refinement.json` e `sendability-focused-final.xcresult` con `sendability-focused-final-object.json`, `sendability-focused-final-details.json` e `sendability-focused-final-summary.json`. Quest’ultimo era il punto di ripresa della sesta patch e registra gli hash dei tre file approvati, quelli preservati e i riferimenti alla suite completa; la settima patch sotto conserva un riepilogo successivo. Tutti gli artefatti sono nella cartella già ignorata `build/poseguard-audit/`.

Al termine della sesta patch restavano separati il warning di debug, le deprecazioni delle view, background e hardware, policy e pubblicazione, report e accessibilità. Le tre deprecazioni individuate vengono affrontate nella settima patch sotto. Soglie, cadenza, identità delle richieste, layout e animazioni non sono cambiati.

### Settima patch approvata: aggiornamento delle API deprecate delle view

Registro **nuovo** dell’intervento approvato da Giuseppe sui soli quattro file indicati. L’applicazione e la verifica applicativa sono completate.

| File | Modifica e motivo |
| --- | --- |
| `PoseGuard (3.0)/PoseGuard__3_0_App.swift` | Rimosso soltanto l’initializer che impostava il tema scuro attraverso `UIApplication.shared.windows`; il tema rimane dichiarato mediante `preferredColorScheme(.dark)` sulla view radice |
| `PoseGuard (3.0)/View/MyTipsView.swift` | Sostituita la firma deprecata di `onChange` con la closure a due valori, ignorando quello precedente; condizione `if newValue` e chiamata a `showView()` conservate |
| `PoseGuard (3.0)/View/Myreportview.swift` | Stessa sostituzione puntuale per il pannello Report, senza modificare condizioni, layout o animazioni |
| `AUDIT.md` | Registrati perimetro, motivazioni e verifiche dell’intervento |

La firma è stata controllata nell’interfaccia Swift pubblica dell’SDK installato: il parametro `initial` ha valore predefinito `false`. Non viene quindi introdotta una chiamata iniziale alla comparsa delle view. Non sono aggiunti test che replichino queste modifiche formali: la compilazione e la suite esistente verificano l’integrazione; il confronto puntuale con la baseline verifica che le closure delle animazioni non cambino.

Artefatti **nuovi**, nella cartella già ignorata `build/poseguard-audit/`: `deprecations-source-before.json`, baseline degli hash; `deprecations-final.xcresult` e le estrazioni `deprecations-final-object.json`, `deprecations-final-details.json`, `deprecations-final-summary.json` per conservare gli esiti e il controllo del perimetro. Nessun commit, push, intervento sulla firma o prova su dispositivo fisico è incluso nella patch.

Build e azione Test riuscite sul Simulator iPhone 17 con iOS 27.0: **settantasei esecuzioni riuscite, zero fallimenti, zero test saltati e zero errori**. Il log di build contiene la compilazione di `PoseGuard__3_0_App.swift`, `MyTipsView.swift` e `Myreportview.swift`; le tre deprecazioni non compaiono nelle diagnostiche. È una build incrementale, senza clean, e non viene presentata come scansione completa di ogni possibile warning dell’app.

Il solo warning del result bundle è `Debug session ended with code 9: killed`, già osservato nelle suite complete precedenti. La causa resta da isolare; non viene classificato come innocuo né come crash applicativo dimostrato. Non sono stati aggiunti test, alterati dati o permessi del Simulator o avviate prove sull’iPhone fisico.

Il confronto degli hash con la baseline conferma modifiche soltanto ai quattro file approvati. Per i tre sorgenti il confronto inverso con la versione Git conferma esattamente la rimozione dell’initializer e le due sostituzioni della firma, senza altri cambiamenti. `git diff --check` non rileva problemi. Il riepilogo finale conserva conteggi, messaggi originali, attività di compilazione e hash dei file modificati e preservati. Nessun altro file necessita di un aggiornamento causato da questa patch; wiki e documenti esterni restano da riallineare con interventi separati già indicati.

### Ottava patch approvata: accessibilità della home e dei suggerimenti

La prima build è riuscita e ha eseguito settantasei casi, con settantaquattro successi e due fallimenti UI. La gerarchia XCTest allegata mostra Tips come `Alert` a coordinate fuori schermo, anche quando nascosto. Il test Motion trovava quindi Tips tramite `app.alerts.firstMatch` dopo la chiusura dell’alert reale. Rendere il tratto modale condizionale all’apertura ha risolto questo fallimento: nella seconda suite sono riusciti settantacinque casi su settantasei.

Il test Tips falliva ancora sull’assert `!closeButton.exists`. Anche una successiva prova mirata, con esclusione esplicita dei figli del container, non ha modificato questa osservazione. La compilazione dei due sorgenti interessati è confermata dal log: non si trattava di una build senza le modifiche. È stata corretta esplicitamente una conclusione precedente dell’audit: la presenza di un elemento nella gerarchia XCTest non dimostra di per sé che sia raggiungibile da VoiceOver. Una [risposta dello staff Apple](https://developer.apple.com/forums/thread/725008) distingue la gerarchia di automazione dal comportamento di `accessibilityElement(children:)`; non costituisce una prova del risultato di `accessibilityHidden` in PoseGuard.

Gli assert sono stati riallineati alla proprietà osservabile: pannello chiuso e home coperta non devono offrire controlli tappabili; il pulsante Chiudi deve funzionare anche vicino al bordo e la home deve tornare tappabile dopo la chiusura. La verifica con VoiceOver attivo resta manuale. La variazione temporanea `.ignore` è stata rimossa perché non giustificata dalla misura. Tips e Report rimangono montati come nella baseline per conservarne stato e ingresso; il Report conserva solo le regole di accessibilità e hit testing sul chiamante. Per Tips `accessibilityHidden` è applicato al container del pannello e la home è un container esplicito. La verifica mirata corretta e la successiva suite completa sono riuscite, con gli esiti sotto.

Artefatti diagnostici **nuovi**: `accessibility-first.xcresult`, `accessibility-first-object.json`, `accessibility-first-summary.json`, `accessibility-first-failure-1.json`, `accessibility-first-failure-2.json` e le due estrazioni testuali `accessibility-first-hierarchy-1-1.txt`, `accessibility-first-hierarchy-2-1.txt`. Conservano il primo tentativo e la diagnosi della gerarchia XCTest, nella stessa cartella ignorata. Gli artefatti **nuovi** `accessibility-second.xcresult`, `accessibility-second-object.json`, `accessibility-second-failure.json`, `accessibility-second-hierarchy-1.txt`, `accessibility-focused-first.xcresult`, `accessibility-focused-first-object.json` e `accessibility-focused-first-hierarchy.txt` conservano i due tentativi diagnostici successivi. Le interpretazioni non confermate su VoiceOver non vengono usate come evidenza di un difetto o di una correzione verificata.

Registro **nuovo** della patch approvata da Giuseppe sui cinque file sotto. Codice e risorse applicati; build e suite completa riuscite, entro i limiti di verifica sotto. Gli elementi **nuovi** sono il pulsante di chiusura, due etichette localizzate, gli stati di focus e chiusura e la lettura della preferenza Reduce Motion; non vengono aggiunti file sorgente, dipendenze o build settings.

| File | Modifica e motivo |
| --- | --- |
| `PoseGuard (3.0)/View/TrackingView.swift` | Label testuale del pulsante Tips, focus di ritorno, home esclusa da VoiceOver e hit testing mentre Tips è aperto; overlay Report inattivo escluso dalle interazioni; aggiornamento delle animazioni alla preferenza Reduce Motion anche durante il tracking |
| `PoseGuard (3.0)/View/MyTipsView.swift` | Pulsante Chiudi con label e area tappabile di 44 × 44 punti, azione accessibility escape, pannello modale, focus dopo l’apertura; pannello nascosto escluso da accessibilità e tocchi; protezione contro chiusure ripetute |
| `PoseGuard (3.0)/Localizable.xcstrings` | Etichette **nuove** `Show posture tips` e `Close tips`, in inglese e italiano |
| `PoseGuard (3.0)UITests/PoseGuard__3_0_UITests.swift` | Test Tips rafforzato: due cicli di apertura e chiusura, controlli nascosti o coperti non tappabili e ritorno alla home, frame del pulsante e tap vicino al bordo, screenshot allegati |
| `AUDIT.md` | Motivazioni, fonti Apple, revisione, risultati e limiti dell’intervento |

Con Reduce Motion disattivato rimangono le curve e i parametri delle animazioni ordinarie. Quando è attivo, scompaiono le onde espansive e la pulsazione esterna, si fermano rotazione e scala animata e il pannello cambia posizione senza animazione. Il drag continua a seguire direttamente il dito, senza spring: non si impedisce una gesture esplicita dell’utente. La modifica è limitata a home e Tips; onboarding e Report non costituiscono una verifica globale del supporto Reduce Motion.

Per gestire il focus e la chiusura viene usata la completion nativa di `withAnimation`: il pannello si chiude al completamento logico della stessa spring, invece che dopo il precedente timer fisso di 0,3 secondi. Una guardia di stato impedisce chiusure sovrapposte. Il focus viene richiesto sul pulsante Chiudi dopo l’apertura e torna a Tips dopo la chiusura; il comportamento con VoiceOver attivo richiede ancora una prova manuale.

La revisione indipendente, già autorizzata e limitata alla patch, non ha individuato un bug certo di focus o chiusura. Ha segnalato che un frame esterno al Button non dimostra da solo l’area tappabile: frame e contentShape sono stati applicati alla label e il test effettua il tap vicino al bordo. Il drag diretto con Reduce Motion è intenzionale; la misura delle animazioni durante dati Motion reali rimane una prova hardware.

Fonti ufficiali ricontrollate: [Accessibility nelle HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility), per alternative alle gesture e movimento ridotto; [AccessibilityFocusState](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate), per le richieste di focus; [withAnimation con completion](https://developer.apple.com/documentation/swiftui/withanimation(_:completioncriteria:_:completion:)), per il completamento nativo, eseguito una sola volta anche in assenza di animazioni. La disponibilità della completion e delle API usate è stata confrontata con l’interfaccia pubblica dell’SDK installato, senza cambiare deployment target.

Artefatti **nuovi** nella cartella già ignorata `build/poseguard-audit/`: `accessibility-source-before.json` conserva la baseline; `accessibility-final.xcresult`, `accessibility-final-object.json`, `accessibility-final-details.json`, `accessibility-final-summary.json` e `accessibility-localizations.json` conservano le verifiche finali. Gli artefatti **nuovi** `accessibility-focused-final.xcresult`, `accessibility-focused-final-object.json`, `accessibility-focused-final-details.json`, `accessibility-focused-final-summary.json` e `accessibility-tips-open.png` conservano il test mirato riuscito e lo screenshot esportato e ispezionato. Non sono inclusi cambiamenti ai permessi, alle impostazioni del Simulator, alla firma o al dispositivo fisico.

Verifica finale: **build e azione Test riuscite, settantasei esecuzioni riuscite, zero fallimenti, zero test saltati e zero errori**. Il test Tips rimane uno dei quattro UI test esistenti: è stato rafforzato, non viene contato come un caso aggiuntivo. La precedente ripetizione mirata ha superato una esecuzione; non si somma alla suite come un settantasettesimo caso distinto. Il solo warning presente è `Debug session ended with code 9: killed`; la causa rimane da isolare. Le build sono incrementali, senza clean, reset di dati o cambiamenti ai permessi.

Le due etichette sono state lette dalle risorse inglesi e italiane nel bundle effettivamente compilato e confrontate con i valori attesi. Rimuovere dal catalogo solo i due blocchi nuovi ricostruisce esattamente l’hash della baseline: nessuna altra traduzione è stata cambiata. Nello screenshot del test riuscito il titolo e il pulsante Chiudi sono separati e allineati; le cinque schede e la struttura del pannello rimangono riconoscibili e non mostrano sovrapposizioni nella configurazione osservata. Non è una verifica di Dynamic Type, contrasto misurato o di tutte le dimensioni dello schermo.

La revisione indipendente è stata riesaminata alla luce della distinzione fra XCTest e VoiceOver: anche la sua prima inferenza sulla gerarchia era troppo ampia ed è stata corretta. Non sono stati mantenuti workaround che smontassero Tips o Report o aggiungessero `.ignore` per soddisfare un assert non appropriato. Il confronto finale conferma modifiche soltanto ai cinque file approvati; i file rimanenti coincidono con gli hash precedenti e `git diff --check` non segnala problemi. Non servono altri aggiornamenti documentali causati dalla patch; wiki, policy esterna e documenti di pubblicazione restano gli interventi separati già indicati.

Prove pratiche ancora necessarie, senza considerarle già eseguite:

- Con VoiceOver attivo, aprire Tips, verificare il focus su Chiudi, esplorare i suggerimenti senza raggiungere la home e chiudere tramite pulsante e gesture escape; verificare il ritorno del focus a Tips.
- Con Reduce Motion attivo, verificare apertura e chiusura di Tips senza scorrimento automatico; durante dati Motion reali, verificare assenza di onde, pulsazione e rotazione.
- Cambiare Reduce Motion mentre il tracking è in corso e verificare arresto e ripresa del movimento; con preferenza disattivata confrontare le animazioni ordinarie e la chiusura tramite trascinamento.
- Ripetere i flussi in italiano e con dimensioni testo accessibili. Le etichette compilate corrette non provano da sole il layout o la lettura di VoiceOver.

### Nona patch approvata: testo di attesa, trascinamento Tips e avvisi per episodio

Registro **nuovo** della correzione approvata dopo il resoconto hardware su iOS 27.1. Modificati soltanto i sei file del piano; build e test sul Simulator sono riusciti, entro i limiti sotto. L’installazione della nuova build e la ripetizione fisica dei tre casi rimangono affidate a Giuseppe.

- `TrackingView.swift`: il testo di stato conserva font e contenuto, ma può usare tutta l’altezza necessaria su più righe, con margini orizzontali e priorità di layout. Il testo di attesa non viene abbreviato per mascherare il problema.
- `MyTipsView.swift`: altezza del pannello derivata da geometria e safe area, senza la precedente sottrazione di cento punti; maniglia con area alta quarantaquattro punti e identificatore tecnico **nuovo** `tipsDismissHandle`. Il drag verso il basso parte da maniglia o intestazione, seguendo direttamente il dito; il gesto non viene assegnato al container della lista, così lo scroll conserva il proprio ruolo. La chiusura prosegue verso il basso e ripristina fuori schermo l’offset d’ingresso mentre il pannello è nascosto. X, escape, focus e Reduce Motion restano gestiti.
- `PostureMonitorModel.swift`: il prefisso dell’episodio impedisce nuove registrazioni fino a recupero o stop, anche dopo la consegna del primo avviso. Il primo trigger rimane a sette secondi; il cooldown di cinque secondi fra tentativi rimane. Se add restituisce un errore, solo la callback ancora appartenente all’episodio corrente può liberarne il gate per il retry.
- Unit test: il caso che richiedeva due pendenti è sostituito dalla verifica di un solo avviso, anche dopo delivery simulata e altri campioni; casi **nuovi** per retry dopo errore e per errore tardivo dopo recupero o stop. Nel fake sono **nuovi** il risultato di errore configurabile e la simulazione di consegna, confinati ai test.
- UI test: caso **nuovo** di trascinamento verso il basso dalla maniglia e dall’intestazione, posizione della maniglia nella parte bassa, scroll della lista e riapertura; resta il precedente test della X e della tappabilità.
- `AUDIT.md`: registrati problema, politica approvata, verifiche e limiti.

Il sorgente effettivo del model supera `swiftc -typecheck -swift-version 5 -strict-concurrency=complete`, SDK Simulator installato e target iOS 18.0, con **zero warning e zero errori**. Una revisione indipendente in sola lettura non ha rilevato difetti concreti nel gate, nel retry o nella protezione dalle callback obsolete; non sostituisce la suite applicativa.

Xcode era in Run sul dispositivo fisico dopo la prova di Giuseppe. La sessione di debug è stata terminata; la destinazione dei test è stata cambiata e verificata su iPhone 17 Simulator, senza installare una nuova build sul telefono o cambiare la firma. Non sono stati azzerati dati o permessi.

Artefatti **nuovi**, nella cartella ignorata `build/poseguard-audit/`: `device-bugs-source-before.json`, `device-bugs-model-typecheck.log`; `device-bugs-final.xcresult`, `device-bugs-final-object.json`, `device-bugs-final-details.json` e `device-bugs-final-summary.json` conservano la suite completa. Gli artefatti **nuovi** `device-bugs-focused-final.xcresult`, `device-bugs-focused-final-object.json`, `device-bugs-focused-final-details.json`, `device-bugs-focused-final-summary.json` e `device-bugs-tips.png` conservano il caso mirato riuscito e lo screenshot ispezionato.

Verifica finale della nona patch: **build e azione Test riuscite, ottanta esecuzioni riuscite, zero fallimenti, zero test saltati e zero errori**: settantacinque esecuzioni unit e cinque UI. La ripetizione mirata precedente ha superato una esecuzione già compresa negli ottanta casi; non viene sommata come un caso distinto. Il solo warning del result bundle è `Debug session ended with code 9: killed`, già osservato e ancora da diagnosticare. Il controllo completo di concorrenza del model rimane senza warning o errori.

La prima suite aveva superato settantanove casi su ottanta. Il nuovo test del drag si fermava prima della gesture nell’attesa che Chiudi e la maniglia decorativa, esclusa da VoiceOver, risultassero entrambi `isHittable`. La misura ora attende Chiudi tappabile e geometria della maniglia dentro il viewport e verifica poi la chiusura tramite il trascinamento reale. Il primo tentativo mirato ha successivamente individuato un selettore troppo ampio: `scrollViews.firstMatch` prendeva il Report fuori schermo. Il selettore è stato vincolato al contenuto dei suggerimenti. Nessun codice di produzione è cambiato dopo la prima suite: le due rifiniture riguardano soltanto il test e non eliminano la verifica della gesture.

I tentativi diagnostici sono conservati negli artefatti **nuovi** `device-bugs-first.xcresult`, `device-bugs-first-object.json`, `device-bugs-first-failure.json`, `device-bugs-first-hierarchy-1.txt`, `device-bugs-focused-first.xcresult` e `device-bugs-focused-first-object.json`. L’estrazione della prima gerarchia è uno snapshot di XCTest, non una prova del comportamento di VoiceOver; valgono le distinzioni già documentate nella patch precedente.

La prova mirata e la suite finale verificano altezza della maniglia di almeno quarantaquattro punti, posizione nella parte inferiore del viewport, scroll della lista e chiusura verso il basso da maniglia e intestazione, oltre alla riapertura. Lo screenshot mostra titolo e schede senza sovrapposizioni nella configurazione provata e la maniglia più vicina al bordo inferiore. Non certifica tutte le dimensioni del testo o dello schermo. I test deterministici delle notifiche verificano un solo add durante un episodio continuo anche dopo delivery simulata, retry dopo errore e innocuità dell’errore tardivo dopo recupero o stop; rimangono superati anche cancellazione, riavvio e callback obsolete.

Il testo di attesa tagliato non è stato riprodotto e misurato direttamente nell’interfaccia del dispositivo: è stato corretto il vincolo di layout, ma occorre confermare il risultato sulla nuova build. Anche la presentazione reale a schermo bloccato va riconfermata: un test del servizio sostitutivo non controlla come iOS presenta notifiche vecchie o già consegnate. Giuseppe deve ripetere soltanto i tre casi segnalati: testo dopo Tap To Track, Tips con trascinamento verso l’alto secondo la successiva decima patch e episodio Bad Posture a schermo bloccato. VoiceOver e Reduce Motion con hardware restano le prove successive.

Il confronto finale con `device-bugs-source-before.json` conferma modifiche soltanto ai sei file approvati; gli altri hash coincidono e `git diff --check` non rileva problemi. Il README non promette una frequenza periodica degli avvisi: non richiede un aggiornamento causato da questa politica. Nessun altro file deve essere modificato per completare la patch. Wiki, policy esterna e pubblicazione restano interventi separati già indicati. La destinazione lasciata in Xcode è il Simulator: Giuseppe selezionerà il proprio iPhone prima dell’installazione manuale della nuova build.

### Decima patch approvata: chiusura di Tips verso l’alto

Registro **nuovo** del chiarimento di Giuseppe dopo la nona patch: il pannello ora scorre verso il basso, ma la chiusura desiderata deve avvenire verso l’alto. La direzione verso il basso era quella espressamente scelta nel primo chiarimento; il resoconto della nona patch resta storico e viene superato da questa correzione.

Modificati soltanto tre file esistenti:

- `PoseGuard (3.0)/View/MyTipsView.swift`: il drag ammette traslazioni negative e chiude oltre ventiquattro punti verso l’alto o con velocità inferiore a meno cento punti al secondo. Anche l’uscita animata e l’offset di chiusura quando cambia Reduce Motion diventano negativi. Restano maniglia in basso, area di quarantaquattro punti, X, escape, focus, scroll della lista e curve spring esistenti.
- `PoseGuard (3.0)UITests/PoseGuard__3_0_UITests.swift`: il caso esistente viene rinominato `testTipsCanBeDismissedByDraggingUp`; la maniglia viene trascinata verso il centro dello schermo e l’intestazione di quaranta punti verso l’alto, mantenendo il punto finale dentro il viewport. Il test verifica ancora geometria della maniglia, scroll della lista, chiusura e riapertura.
- `AUDIT.md`: aggiornati stato corrente, checkpoint e istruzioni della prova fisica; conservata la cronologia della direzione precedente.

Verifica: **build e azione Test riuscite sul Simulator iPhone 17 con iOS 27.0; ottanta esecuzioni riuscite, zero fallimenti, zero test saltati e zero errori**. Sono settantacinque esecuzioni unit e cinque UI; il caso rinominato supera la chiusura verso l’alto sia dalla maniglia sia dall’intestazione. Non è un test aggiuntivo rispetto agli ottanta. Il solo warning è ancora `Debug session ended with code 9: killed`, dalla causa non isolata. La build è incrementale; non sono stati azzerati dati o permessi. Xcode è stato usato soltanto per selezionare il Simulator e avviare la suite; modifiche e lettura degli esiti sono state effettuate direttamente sui file.

Artefatti **nuovi**, nella cartella già ignorata `build/poseguard-audit/`: `tips-up-source-before.json`, `tips-up-final.xcresult`, `tips-up-final-object.json`, `tips-up-final-details.json` e `tips-up-final-summary.json`. Il riepilogo conserva esiti, warning e hash correnti; il confronto con la baseline conferma modifiche soltanto ai tre file approvati e `git diff --check` non segnala problemi. Non risultano altri file da aggiornare per questa correzione. Nessun commit, push o intervento sulla firma.

Prova ancora necessaria di Giuseppe sulla nuova build: trascinare la maniglia di Tips verso l’alto, verificare la riapertura e la X, quindi riconfermare il testo di attesa e l’assenza di notifiche duplicate nello stesso episodio a schermo bloccato. La suite sul Simulator non certifica questi ultimi due comportamenti sul dispositivo, né VoiceOver attivo o Reduce Motion con dati Motion reali. L’installazione sull’iPhone resta a Giuseppe; in Xcode è selezionato il Simulator.

### Undicesima patch approvata: istruzioni coerenti e localizzate

Registro **nuovo** dell’intervento approvato sui cinque file. L’onboarding presentava un report non accessibile dalla home e il README dichiarava una calibrazione personale assente dal monitor. Inoltre `InstructionRow` riceveva `String`: i suoi `Text` mostravano il valore letterale anziché cercare le traduzioni delle istruzioni.

- `PoseGuard (3.0)/View/Onboarding.swift`: la terza istruzione diventa «Read posture tips», con icona `lightbulb` e invito ad aprire i suggerimenti. Corretto il refuso «airpdos». Titolo e descrizione di `InstructionRow` usano `LocalizedStringKey`, con gli stessi tre punti di chiamata e senza wrapper aggiuntivi. Restano gerarchia, spaziature, font, limite di due righe per le descrizioni, pulsante e comportamento del completamento.
- `PoseGuard (3.0)/Localizable.xcstrings`: sei voci **nuove**, ciascuna in inglese e italiano, per titoli e descrizioni delle tre istruzioni. Rimuovere soltanto i sei blocchi aggiunti ricostruisce esattamente l’hash del catalogo precedente: nessuna voce esistente è stata modificata. I dodici valori sono stati letti anche dalle risorse `Localizable.strings` inglesi e italiane del bundle compilato e confrontati con quelli attesi.
- `PoseGuard (3.0)UITests/PoseGuard__3_0_UITests.swift`: rafforzato il caso inglese con la verifica delle sei istruzioni; caso **nuovo** `testOnboardingInstructionsAreAvailableInItalian`, che avvia l’app in italiano, apre l’onboarding dalla home se è già stato completato, verifica le sei istruzioni e completa il flusso. I due casi conservano screenshot **nuovi** come allegati. Gli argomenti di lancio selezionano la lingua dell’app durante il test.
- `README.md`: la voce sulla calibrazione personalizzata diventa la descrizione della soglia fissa di più o meno quindici gradi su pitch e roll, dichiarando che la calibrazione personale non è implementata. Conservati lingua inglese, crediti e altre sezioni.
- `AUDIT.md`: aggiornati stato, checkpoint e rilievi su calibrazione, report e localizzazione. Chiarito anche che il vecchio rinvio al manuale era già stato eliminato dalla quarta patch: il collegamento alla policy resta da implementare dopo averne concordato il contenuto.

Verifica: **build e azione Test riuscite, ottantuno esecuzioni riuscite, zero fallimenti, zero test saltati e zero errori**, sul Simulator iPhone 17 con iOS 27.0. Le esecuzioni unit rimangono settantacinque; gli UI test diventano sei. L’unico warning del result bundle è `Debug session ended with code 9: killed`, già osservato e dalla causa ancora non isolata. È una build incrementale, senza clean o reset dei dati. La suite comprende anche la chiusura di Tips verso l’alto e i test delle notifiche delle patch precedenti.

Gli screenshot inglese e italiano sono stati estratti e ispezionati: nella configurazione provata le tre istruzioni sono complete e separate, l’icona dei suggerimenti è corretta e il pulsante per continuare è visibile. L’intestazione italiana usa la traduzione già presente. La prova non certifica Dynamic Type, altri formati di schermo, contrasto misurato o navigazione con VoiceOver attivo.

Artefatti **nuovi**, nella cartella già ignorata `build/poseguard-audit/`: `onboarding-source-before.json`, `onboarding-localization-check.json`, `onboarding-final.xcresult`, `onboarding-final-object.json`, `onboarding-final-details.json`, `onboarding-ui-details.json`, `onboarding-en.png`, `onboarding-it.png` e `onboarding-final-summary.json`. Il riepilogo conserva risultati, warning, limiti e hash correnti. Il confronto con la baseline conferma modifiche soltanto ai cinque file approvati; gli altri file coincidono e `git diff --check` non segnala problemi. Nessun altro file richiede modifiche per completare questa patch.

Non sono stati eseguiti commit, push, cambiamenti alla firma o installazioni sul dispositivo fisico. Restano da confermare sulla nuova build dell’iPhone i tre problemi segnalati da Giuseppe: testo di attesa, chiusura di Tips verso l’alto e notifiche durante un episodio continuo a schermo bloccato. Report reali, calibrazione personale, policy pubblica, background e verifiche di accessibilità restano interventi distinti dell’obiettivo complessivo.

## Ambiente e verifiche

- Toolchain locale verificata: Xcode 27.1, build 27A9275.
- Target applicativo: iPhone; deployment target dell'app iOS 18.0, Swift language mode 5.
- Configurazione hardware dichiarata da Giuseppe: iPhone 17 dell’Academy con iOS 27.1 e AirPods 4. Installazione e prova sono state svolte da Giuseppe, che ha comunicato le tre anomalie riportate nel resoconto della prima prova reale. Non sono risultati osservati direttamente dall’assistente né una certificazione di tutti i flussi.
- Simulator osservati in Xcode: runtime iOS 27.0. Non equivale alla verifica sull'iPhone con iOS 27.1.
- `plutil -lint` ha accettato il plist sorgente e `project.pbxproj`. Questo verifica la sintassi, non il comportamento dell'app o la conformità all'App Store.
- Il progetto non dichiara dipendenze di terze parti. Nel sorgente esaminato non sono emerse chiamate di rete, backend, SDK esterni o credenziali evidenti. Non è stata verificata l'intera cronologia Git né certificata la privacy del binario pubblicato.
- Due revisioni indipendenti hanno esaminato rispettivamente lifecycle e test, privacy e UX. Le conclusioni sono state confrontate con il codice corrente.

### Build da terminale

È stato eseguito questo comando dalla radice della repository:

```sh
xcodebuild -project PoseGuard.xcodeproj \
  -scheme PoseGuard -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/poseguard-audit/DerivedData \
  -resultBundlePath build/poseguard-audit/baseline-build.xcresult \
  -disableAutomaticPackageResolution CODE_SIGNING_ALLOWED=NO build
```

Il tentativo è terminato con exit code 133. Nel log compaiono il blocco `sandbox-exec: sandbox_apply: Operation not permitted`, il fallimento del servizio delle macro SwiftUI e l'indisponibilità di CoreSimulator. Gli errori derivati su `@State`, binding e `#Preview` non sono stati trattati come difetti dimostrati di PoseGuard.

Evidenze locali, escluse da Git: `build/poseguard-audit/baseline-build.log`, `baseline-build.xcresult`, `project-list.log`, `simulator-devices-error.log`. L'inventario dei dispositivi da terminale è fallito: il relativo JSON non è un elenco valido dei runtime disponibili.

### Build da Xcode

La compilazione dall'interfaccia di Xcode ha mostrato `Build Succeeded`, senza correzioni dei sorgenti. Il registro di build di Xcode conferma zero errori. I tentativi di esecuzione vengono registrati separatamente: compilare non dimostra che l'app si avvii, che i test coprano le funzionalità o che i sensori funzionino.

La prima compilazione completa aveva registrato tre warning: i due impieghi di `onChange(of:perform:)` nei pannelli Tips e Report e l’accesso deprecato a `UIApplication.shared.windows` nell’entry point. La settima patch aggiorna questi impieghi e ne verifica la ricompilazione senza le tre diagnostiche. Le altre compilazioni incrementali precedenti non dimostravano da sole la risoluzione.

### Test e primo avvio

Il primo tentativo di Test sul Simulator iPhone 18 Pro con iOS 27.0 ha incontrato un errore di lancio del Simulator: Xcode riporta che SpringBoard potrebbe essere terminato in modo anomalo. Il result bundle conferma build riuscita, azione Test fallita, zero test eseguiti e due errori di esecuzione. Tra i warning compare `Cannot test target “PoseGuardUITests” on “iPhone 18 Pro”: UITargetAppPath should be provided`, coerente con la configurazione incompleta del target UI. Gli zero test falliti non costituiscono un esito positivo: non ne è stato eseguito nessuno.

L'errore di SpringBoard appartiene al percorso di lancio e non dimostra un crash del codice applicativo. L'app è stata poi avviata normalmente sul Simulator iPhone 17 con iOS 27.0. In questa configurazione sono stati verificati manualmente:

- visualizzazione dell'onboarding;
- passaggio alla schermata principale tramite `Continue`;
- comparsa della richiesta di notifiche e accesso alla home dopo `Don’t Allow`;
- avviso `AirPods not connected` quando si tenta il tracking senza cuffie disponibili sul Simulator;
- apertura del pannello Tips.

Le immagini di onboarding, home e Tips sono state ispezionate e mostrate nella chat; non sono stati salvati file immagine nella repository. Questa è una baseline visiva parziale, senza sessione di tracking attiva. Non è stato verificato il comportamento dei sensori reali, l'animazione durante il tracking, la chiusura tramite tecnologie assistive o il funzionamento in background. L'albero di accessibilità mostra i controlli principali come `Light Bulb` e `Airpods Pro`: conferma nomi degli oggetti, non descrizioni esplicite delle azioni.

Il result bundle del primo tentativo è stato copiato in `build/poseguard-audit/baseline-tests.xcresult` per esaminarlo senza scrivere sull'originale di Xcode. L'estrazione moderna del riepilogo incontra un ulteriore limite di scrittura nella cache TestReport; la lettura degli oggetti con l'opzione documentata `--legacy` è riuscita. Il risultato grezzo è in `baseline-tests-object.json`; il riepilogo derivato, con conteggi e messaggi originali, è in `baseline-tests-summary.json`. Questo uso dell'opzione legacy riguarda soltanto l'ispezione del risultato, non le API dell'app.

La verifica successiva sulla destinazione iPhone 17 è terminata. Il result bundle registra build riuscita, azione Test riuscita, zero test eseguiti, zero errori di esecuzione e un warning: `Cannot test target “PoseGuardUITests” on “iPhone 17”: UITargetAppPath should be provided`. Questo distingue il precedente errore di avvio dalla carenza stabile dei target test. Il risultato è raccolto in `baseline-tests-iphone17.xcresult`, con oggetto e riepilogo nei corrispondenti file JSON. Nessun valore di code coverage di un'esecuzione senza test viene usato come prova della correttezza delle funzionalità.

| Verifica | Esito osservato | Che cosa dimostra |
| --- | --- | --- |
| Build da terminale controllato | Fallita per macro e servizi bloccati dal sandbox | Limite di quel percorso di esecuzione; non un errore di compilazione dell'app riprodotto in Xcode |
| Build da Xcode | Riuscita | Il sorgente corrente compila con la toolchain locale |
| Run su iPhone 17 simulato, iOS 27.0 | Riuscito, con le verifiche manuali sopra elencate | I flussi osservati sono raggiungibili in questa configurazione |
| Test su iPhone 18 Pro simulato | Azione fallita durante il lancio; zero test eseguiti | Nessuna verifica automatica del comportamento |
| Test su iPhone 17 simulato | Azione riuscita; zero test eseguiti; warning sul target UI | L'esito dell'azione non costituisce una suite di test funzionante |

L'ultimo tentativo di lettura dell'interfaccia di Xcode ha incontrato un errore del servizio di cattura dello schermo. L'esito finale dei test è stato verificato sul result bundle completato, non dedotto dallo stato precedente della finestra.

## Problemi verificati nel codice

### Avvisi che restavano programmati dopo recupero o arresto nella baseline

In `Model/PostureMonitorModel.swift`, `checkPosture` può programmare un avviso dopo due campioni consecutivi fuori soglia. Ogni richiesta ha un identificatore casuale e un ritardo di sette secondi. Il recupero della postura e `stopMonitoring()` non cancellano le richieste pendenti. La soglia temporale di cinque secondi limita la frequenza degli avvisi, ma non misura la durata continuativa della posizione scorretta.

Conseguenza nella baseline: un avviso già programmato può essere consegnato dopo che la condizione è cessata. La seconda patch approvata corregge cancellazione e callback mantenendo i tempi esistenti; la definizione di una diversa permanenza richiesta resta una scelta funzionale separata. La verifica con clock controllato e servizio notifiche sostitutivo è riuscita, entro i limiti e con le evidenze indicate nel registro della seconda patch.

### Più motion manager e avvii concorrenti nella baseline

`TrackingView.swift` conteneva un manager nella view, ne creava un altro in `areAirPodsConnected` e utilizzava anche il manager del model. Il ramo positivo della verifica non chiudeva il proprio stream. Durante l'attesa la view restava nello stato inattivo, consentendo altre richieste di avvio, senza un meccanismo per invalidare una completion tardiva dopo uno stop.

La terza patch sostituisce questo percorso con un unico proprietario e uno stato esplicito di avvio annullabile, invalidando la sessione prima dello stop. Le evidenze e i limiti sono riportati nel relativo registro. Non è stato misurato un consumo energetico anomalo: la mancata chiusura era un problema di lifecycle, non una misura di performance.

### Stato visibile incoerente dopo errori e autorizzazioni negate nella baseline

`PostureMonitorModel` impostava `isMonitoring` all'avvio, ma nel ramo errore modificava soltanto messaggio e notifica. La view conservava separatamente `isTracking`, da cui dipendevano animazioni e colore. La verifica degli AirPods riconduceva gli errori a un messaggio di mancata connessione, senza distinguere il consenso Motion.

La terza patch deriva lo stato visibile dal model e distingue avvio, tracking effettivo ed errori, con motivi separati per consenso, indisponibilità e disconnessione. I test controllati e il test UI sono descritti nel registro; rimozione e riconnessione degli auricolari reali restano da provare.

### File dei test non associati ai target nella baseline

Nella baseline, i target test nel `project.pbxproj` non avevano gruppi sincronizzati assegnati e le rispettive Sources erano vuote. I file nelle cartelle test non risultavano inclusi; il test unitario era un template vuoto, con il precedente nome del modulo nell'import. Anche `TEST_TARGET_NAME` degli UI test conservava il nome storico del target.

La prima patch associa i file ai target corretti, riallinea i nomi e introduce verifiche di comportamento. La configurazione è stata verificata staticamente e in esecuzione: il result bundle finale contiene diciannove campioni della classificazione e quattro test UI riusciti. La baseline aveva eseguito zero test effettivi; la nuova suite rende misurabile questo primo insieme di comportamenti.

### Privacy manifest aggiunto nella quarta patch

`ContentView.swift` usa `@AppStorage` per ricordare il completamento dell'onboarding, quindi UserDefaults. Nella baseline mancava il privacy manifest. La quarta patch lo aggiunge per dichiarare la motivazione dell’uso delle API UserDefaults interessate.

Intervento applicato: **nuovo** `PoseGuard (3.0)/PrivacyInfo.xcprivacy`, limitato all’uso verificato. L’inclusione nel bundle compilato viene controllata nella quarta patch; il futuro archive richiederà una verifica separata. L'assenza di trasmissione al server non elimina questo requisito. `NSMotionUsageDescription` è invece già presente nelle build settings Debug e Release.

### Privacy policy non raggiungibile dall'app

Il rinvio a un manuale informativo è stato eliminato nella quarta patch; il vecchio pulsante resta commentato e non offre accesso alla policy. Non sono emersi altri collegamenti alla policy nel codice. La scheda Store contiene una policy esterna: il requisito Apple richiede comunque un collegamento facilmente accessibile anche nell'app.

Intervento proposto: rendere raggiungibile una policy coerente con il trattamento effettivo, da un punto accessibile sia prima sia dopo l'onboarding. Posizione e contenuto vanno concordati senza cambiare l'identità grafica.

### Calibrazione personale non ancora implementata

Il README descriveva una posizione neutra personale. L’undicesima patch lo riallinea al monitor, che confronta pitch e roll assoluti con una soglia fissa di quindici gradi. Non esistono acquisizione, conservazione o impiego di un riferimento personale; questa assenza è ora dichiarata nel README.

La calibrazione personale rimane una funzionalità candidata, da concordare e verificare separatamente. Non dimostrerebbe da sola l’accuratezza posturale: l'orientamento degli auricolari non equivale a una misura diretta di collo e schiena.

### Report dimostrativi e attualmente non esposti

Il controllo che apre il report è commentato in `TrackingView.swift`. I model dei report producono sessioni casuali o prestabilite; il monitor non registra sessioni reali e non esiste persistenza dello storico. Il precedente invito dell’onboarding a consultare il report è stato sostituito nell’undicesima patch con un invito ai suggerimenti effettivamente accessibili.

Questo è codice dimostrativo attualmente non esposto dal flusso principale, non la prova che un utente stia vedendo dati casuali come propri. Prima di renderlo accessibile occorre collegarlo a misure reali, gestire lo stato vuoto e verificare durata, cambi di giorno e riapertura dell'app. Anche la conversione delle coordinate del grafico va corretta prima di riattivarlo: attualmente ignora l'area di plot del `ChartProxy`.

### Accessibilità e localizzazione incomplete

La terza patch aggiunge al pulsante del tracking etichette esplicite per avvio, annullamento e arresto. L’ottava patch aggiunge una label esplicita a Tips, un pulsante di chiusura e l’azione escape, richiede il focus sul pannello e il ritorno alla home e legge Reduce Motion in home e Tips. Il flusso tappabile e le risorse localizzate sono verificati; navigazione e focus con VoiceOver attivo e animazioni durante tracking reale rimangono da provare. L’undicesima patch rende localizzabili le tre istruzioni dell’onboarding e ne verifica i testi e il completamento in inglese e italiano. Il corpo degli avvisi posturali resta in inglese nella localizzazione italiana.

Restano localizzazioni residue, verifica estesa di onboarding e Report con dimensioni del testo e dello schermo diverse, Dynamic Type, contrasto effettivo, VoiceOver e layout durante l’uso. I test di XCTest non certificano la navigazione con tecnologie assistive attive. Non è stato dimostrato un problema di performance delle animazioni.

## Verifiche hardware necessarie

Apple documenta il dynamic head tracking sia per AirPods 4 sia per AirPods 4 con ANC. Un sample Apple nomina AirPods 4 per le motion activity; usa però `CMHeadphoneActivityManager`, diverso dal manager di attitude di PoseGuard. La disponibilità dello stream effettivamente usato deve quindi essere verificata tramite API e campioni sul dispositivo, senza dedurla soltanto dal supporto a Spatial Audio.

| Prova | Procedura | Evidenza richiesta |
| --- | --- | --- |
| Disponibilità, avvio e stop | Indossare le cuffie, avviare, muovere la testa, interrompere; ripetere | Campioni con timestamp e pitch/roll variabili; dopo lo stop nessun aggiornamento applicativo o avviso pendente |
| Consensi | Accettare Motion dopo un'attesa; negare separatamente Motion e notifiche; riabilitare dalle Settings | Stato corretto, assenza di falsi messaggi di disconnessione e ripresa comprensibile |
| Rimozione e riconnessione | Togliere un auricolare, poi entrambi; reinserire e disconnettere Bluetooth | Distinzione fra dati attuali, assenza di dati e disconnessione; nessuna valutazione corrente basata su un campione vecchio |
| Background | Uscire dall'app e bloccare lo schermo, osservando intervalli di trenta secondi, due e dieci minuti | Continuità o interruzione dei timestamp, stato al rientro ed eventuali avvisi; una notifica già programmata non dimostra elaborazione continua |
| Attendibilità | Ripetere posizioni e movimenti concordati, anche dopo aver indossato nuovamente le cuffie | Frequenza dei falsi avvisi e dei mancati rilevamenti rispetto al comportamento atteso; nessuna conclusione clinica da questi soli test |

La promessa di funzionamento «sempre in background» non è stata verificata. Non verranno aggiunte modalità background prive di una giustificazione funzionale e del supporto della piattaforma.

## Piano del primo intervento: approvato, applicato e verificato

Prima rendere affidabile la verifica dei test e fissare il comportamento corrente. Poi correggere notifiche e lifecycle, mantenendo l'animazione ordinaria. La separazione utile è tra presentazione, proprietario del monitoraggio e valutazione verificabile con campioni controllati; non è emersa una necessità di altri framework.

Il piano seguente è stato approvato da Giuseppe e applicato nei file elencati nel registro delle modifiche:

| File | Intervento proposto | Perché serve |
| --- | --- | --- |
| `PoseGuard.xcodeproj/project.pbxproj` | Associare le due cartelle test ai rispettivi target e correggere il nome dell'app usato dagli UI test | I file devono essere compilati e il test runner deve individuare l'app corretta |
| `Model/PostureMonitorModel.swift` | Estrarre il confronto degli angoli in una piccola funzione interna pura, **nuova**, nello stesso file, mantenendo identici soglia e risultato sui campioni validi | Permettere test deterministici della classificazione senza creare manager hardware o chiedere permessi |
| `PoseGuard (3.0)Tests/PoseGuard__3_0_Tests.swift` | Correggere l'import al modulo `PoseGuard` e sostituire il template con casi sulla posizione neutra, sulla soglia, sui segni e sull'inclinazione dei due assi | Verificare il contratto della classificazione con esempi e valori limite |
| `PoseGuard (3.0)UITests/PoseGuard__3_0_UITests.swift` | Sostituire il semplice avvio con verifiche dei flussi principali già osservati, gestendo lo stato iniziale dell'onboarding | Un avvio senza assert non protegge la navigazione dalle regressioni |
| `PoseGuard (3.0)UITests/PoseGuard__3_0_UITestsLaunchTests.swift` | Collegare la verifica di lancio alla presenza della schermata attesa | Lo screenshot da solo non dimostra che il lancio abbia raggiunto uno stato utilizzabile |
| `PoseGuard.xcodeproj/xcshareddata/xcschemes/PoseGuard.xcscheme`, **nuovo** | Condividere lo scheme con riferimenti espliciti ai target e alle azioni di build e test | Rendere ripetibile la verifica anche da un altro checkout, senza dipendere dalle preferenze locali di Xcode |
| `AUDIT.md` | Registrare patch, motivazioni, test effettivamente eseguiti e limiti rimasti | Mantenere il registro allineato al codice e alle evidenze |

Per la prima patch sono state verificate compilazione, scoperta ed esecuzione effettiva dei test e i flussi UI descritti nel registro, senza modificare schermate, risorse e catalogo. Non sono stati aggiunti altri framework o un test plan separato. La seconda patch ha introdotto le verifiche delle notifiche e delle callback; la terza interviene ora sulla view e sul monitoraggio unificato, con messaggi localizzati. La sola verifica delle soglie non basta a dimostrarne la correttezza e la fluidità reale dell'animazione non è ancora stata misurata.

Calibrazione personale, storico locale reale e impostazioni degli avvisi sono candidate utili per una fase successiva. Non sono considerate funzionalità completate o già approvate nei dettagli.

## Pubblicazione e documenti da riallineare

La scheda App Store consultata riporta versione 1.1.0 del 2025-03-24 e Matteo Cotena come sviluppatore; il progetto locale dichiara 1.0. Giuseppe è incluso nei crediti. Resta da identificare il sorgente della build pubblicata e chiarire l'accesso alla scheda esistente prima di cambiare bundle identifier o signing.

Il README parla di quattro sviluppatori, il CV di un team di sei; i cinque firmatari del copyright Store non equivalgono necessariamente al numero di partecipanti. Non è stata corretta questa differenza per deduzione.

I documenti della wiki `wiki/progetti/PoseGuard/PoseGuard.md` e `wiki/progetti/_indice.md` riportano ancora il progetto come concluso; il Cruscotto non registra la ripresa. Non sono stati modificati: l'autorizzazione corrente riguarda la repository. L'aggiornamento dello stato della wiki e dell'hardware nel profilo va proposto separatamente.

## Fonti ufficiali consultate

- [Scheda App Store di PoseGuard](https://apps.apple.com/it/app/poseguard/id6743227917).
- [App Review Guidelines: privacy](https://developer.apple.com/app-store/review/guidelines/#privacy).
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).
- [Privacy manifest e required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).
- [CMHeadphoneMotionManager](https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanager).
- [Autorizzazione del movimento delle cuffie](https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanager/authorizationstatus()).
- [Delegate di connessione delle cuffie](https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanagerdelegate).
- [HIG: richiesta dei permessi nel contesto d'uso](https://developer.apple.com/design/human-interface-guidelines/privacy).
- [HIG: alert essenziali e azioni utili](https://developer.apple.com/design/human-interface-guidelines/alerts).
- [Programmazione e cancellazione delle notifiche locali](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app).
- [Sostituzione delle richieste con lo stesso identificatore](https://developer.apple.com/documentation/usernotifications/unnotificationrequest/identifier).
- [Cancellazione asincrona delle sole richieste pendenti](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/removependingnotificationrequests(withidentifiers:)).
- [Gestione del lifecycle](https://developer.apple.com/documentation/uikit/managing-your-app-s-life-cycle).
- [HIG: accessibilità](https://developer.apple.com/design/human-interface-guidelines/accessibility).
- [Verifiche dell'accessibilità e relativi limiti](https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app).
- [Misura e miglioramento delle performance](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance).
- [Specifiche AirPods 4](https://support.apple.com/en-us/121203) e [AirPods 4 con ANC](https://support.apple.com/en-gb/121204).
- [Sample motion activity delle cuffie](https://developer.apple.com/documentation/CoreMotion/getting-motion-activity-data-from-headphones).
- [Trasferimento di un'app in App Store Connect](https://developer.apple.com/help/app-store-connect/transfer-an-app/overview-of-app-transfer/).

## Limiti dell'esito

Questo documento registra un audit del codice e verifiche locali parziali. Non certifica il comportamento del binario già distribuito, l'accuratezza posturale, il funzionamento in background o l'approvazione del prossimo aggiornamento. Non sono ancora disponibili misure comparative di CPU, memoria, energia o responsività.
