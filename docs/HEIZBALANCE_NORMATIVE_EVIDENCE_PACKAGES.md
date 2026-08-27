# HeizBalance – Normative Evidence Candidate Packages

Schema: `normative-evidence-candidate-package-v1`

## Zweck

Evidenzpakete transportieren **Kandidaten** für eine spätere normative Fachprüfung:

- dokumentierte Quellenmetadaten,
- Modulspezifikations-Referenzen,
- unabhängige Referenzfall-Referenzen,
- konkrete Erwartungswerte und Toleranzen.

Der Import selbst ist ausdrücklich **keine Vertrauensentscheidung**.

## Fail-closed-Grundsatz

Jeder erfolgreiche Import erhält ausschließlich den Trust-State:

`quarantined`

Im Core ist `canAffectNormativeReadiness` für einen Import-Receipt hart `false`.

Der App-Store besitzt keine `approve()`- oder `qualify()`-Funktion. Auch beim erneuten Laden persistierter Kandidaten wird der Trust-State defensiv wieder auf Quarantäne gesetzt. Ein unbekannter/manipulierter Trust-State kann deshalb nicht zu einer Freigabe führen.

## Inhalt eines Kandidatenpakets

Pflichtkopf:

- `schema`
- `id`
- `packageVersion`
- `targetEngineID`
- `createdOn`
- `submitter`

Das Ziel muss ein reserviertes Normprofil mit Pflichtmodulen sein. Das technische Preview-Profil wird als Ziel abgewiesen.

### Quellen

Jede Quelle dokumentiert:

- Dokument und Ausgabe,
- Rolle (`normativeBasis`, `successorDraft`, `referenceCase`),
- Metadatenreferenz und Prüfdatum,
- behauptete Nutzungsrechte,
- bei behaupteten Rechten eine Rechte-/Lizenzreferenz.

Wichtig: Rechteangaben aus einem importierten Paket sind **ungeprüfte Behauptungen des Pakets**. Sie werden durch den Import nicht zu `HeizBalanceNormativeSourceRecord`-Evidenz für eine Normfreigabe.

### Spezifikationskandidaten

Ein Kandidat benennt:

- eindeutige ID,
- genau ein Normmodul,
- eine im Paket vorhandene `normativeBasis`-Quelle,
- Spezifikationsversion,
- externe/interne Spezifikationsreferenz.

Der Paketimport kennt absichtlich kein Feld, das eine unabhängige fachliche Review bestätigt.

### Referenzfallkandidaten

Ein Kandidat benennt:

- eindeutige Fall-ID,
- ein oder mehrere Normmodule,
- eine im Paket vorhandene Quelle,
- Fallreferenz,
- mindestens einen Erwartungswert.

Jeder Erwartungswert besitzt:

- ID,
- Metrikschlüssel,
- erwarteten Zahlenwert,
- absolute Toleranz.

Doppelte IDs oder Metrikschlüssel innerhalb eines Falls werden abgewiesen. Nicht-endliche Werte und negative Toleranzen werden abgewiesen.

## Was absichtlich NICHT im Paket existiert

Das Schema transportiert keinen vertrauensbildenden Status wie:

- `approved`
- `qualified`
- `reviewPassed`
- `validationPassed`
- `normativeOutputAllowed`

Selbst zusätzliche unbekannte JSON-Felder können keinen Einfluss auf die Readiness erzeugen, weil der Decoder daraus keine entsprechende Trust- oder Freigabeinformation ableitet.

## Trennung von Erwartungswert und Ergebnis

Ein Referenzpaket darf einen erwarteten Wert liefern. Ob die HeizBalance-Implementierung diesen Wert tatsächlich innerhalb der Toleranz trifft, ist eine **separate spätere Ausführung**.

Damit kann ein Datenlieferant nicht gleichzeitig Erwartung und eigenes PASS-Ergebnis als vertrauenswürdige Wahrheit importieren.

## Persistenz

Die iOS-App speichert strukturell valide Kandidaten lokal unter der HeizBalance Application-Support-Struktur in einer separaten `NormativeEvidenceCandidates`-Ablage.

Diese Ablage ist nicht mit `HeizBalanceNormativeReadiness.evaluate(...)` verbunden.

## Aktueller Freigabestatus

Batch 43 schafft ausschließlich Import, Strukturprüfung, lokale Quarantäne und Einsicht in Kandidatendaten.

Die normative Raumheizlast bleibt weiterhin gesperrt. Eine spätere Qualifikationsstufe muss separat implementiert und überprüft werden; sie darf nicht einfach den importierten Trust-Behauptungen folgen.
