# SHK Werkstatt — current portfolio state, 16 October 2026

Six rejected tools are consolidated in SHK Werkstatt, using the original AnlagenCheck host 6804749223 and bundle de.kamilunavo.servicecheck. RohrCalc, KälteCalc, LüftungsCalc, HeizkörperCalc and VolumeCalc were removed from the normal App Store Connect list at the owner’s explicit request. Their code/history are retained; do not restore or upload them independently without a new instruction. See QA/rejected-calculators-removed-20261016.json.

SHK Werkstatt 1.0 (6) remains READY_FOR_REVIEW with the first permanent Pro purchase prepared together. It is not yet submitted or approved. Source audit for Duo passes; actual pose/state/device validation remains open. See CURRENT_TASK.md and DUO_READINESS.md.

Approved HydroCalc SHK, MAGCalc and BrennerCalc remain separate, unchanged and READY_FOR_DISTRIBUTION. Approved Rising Steps and Perfect Drop are outside this cleanup. Repository targets below describe historical implementations, not active independent release instructions.

---

## Historical state recorded 24 August 2026

# SHK Suite – Projektstand

Stand: 2026-08-24

## Aktive Apps

| App | iOS Bundle-ID | Status |
| --- | --- | --- |
| KälteCalc | `de.kamilunav.kaltecalc` | v1-Funktionsstand fertig, CI grün |
| LüftungsCalc | `de.kamilunavo.luftungscalc` | v1-Funktionsstand fertig, CI grün |
| HeizkörperCalc | `de.kamilunavo.heizkorpercalc` | v1-Funktionsstand fertig, CI grün |
| RohrCalc | `de.kamilunavo.rohrcalc` | v1-Funktionsstand fertig, CI grün |
| AnlagenCheck | `de.kamilunavo.servicecheck` | App-Store-Name AnlagenCheck; v1-Funktionsstand fertig, CI grün |

Die Bundle-IDs werden exakt wie in App Store Connect angelegt verwendet. Sie werden nicht automatisch vereinheitlicht. Bei AnlagenCheck wurde im App-Store-Eintrag die bereits vorhandene Bundle-ID `de.kamilunavo.servicecheck` ausgewählt; der sichtbare App-Name bleibt AnlagenCheck.

## Bewusst nicht umgesetzt

`AbgleichCalc` entfällt. Die hydraulischen Abgleich-, Volumenstrom- und verwandten Funktionen werden durch HydroCalc abgedeckt.

## Architektur

- Ein Repository, fünf eigenständige iOS-App-Targets.
- `SHKCore` enthält gemeinsame, UI-unabhängige Fachberechnungen.
- `SharedUI` enthält das gemeinsame Kamilunavo-SHK-Design.
- Jede App besitzt eigenen Namen, Bundle-ID, Scheme und später eigenen App-Store-Releaseprozess.
- Alle Kernberechnungen funktionieren offline.

## Funktionsstand

### KälteCalc
- Überhitzung und Unterkühlung ohne Wegkappen negativer Diagnosewerte.
- Verdichter-Druckverhältnis aus Absolutdrücken.
- Luftseitige sensible Leistungsnäherung.
- Temperatur-, Druck- und Vakuumumrechnungen.
- Teilbarer Service-Messwertbericht.
- P/T-Sättigungswerte werden nicht geschätzt; verifizierte Stoffdaten sind ein späteres Gate.

### LüftungsCalc
- Rundkanal-Dimensionierung und Ist-Geschwindigkeit.
- Rechteckkanal, erforderliche Höhe und äquivalenter Runddurchmesser.
- Raumvolumen, Luftwechsel und erforderlicher Volumenstrom.
- m³/h, l/s und CFM.
- Teilbare Berechnung.

### HeizkörperCalc
- ΔT50-Leistungsumrechnung mit Hersteller-Exponent n.
- Automatische arithmetische/logarithmische Übertemperaturbewertung.
- Benötigte ΔT50-Nennleistung aus Raum-Zielleistung.
- Stückzahl und Volumenstrom.
- Vergleich typischer Systemtemperaturen.

### RohrCalc
- Geschwindigkeit, Reynolds-Zahl und Strömungsart.
- Rohrreibungsverlust nach Darcy-Weisbach.
- ζ-Einzelwiderstände und Gesamtdruckverlust.
- Förderhöhe, Rohrinhalt und Dimensionierung aus Zielgeschwindigkeit.
- Vergleich freier Innendurchmesser.

### AnlagenCheck
- Messwerte gegen frei einstellbare Prüfvorgaben.
- Spreizung, Kalt-/Warmdruck, statische Höhe und Sicherheitsventil-Reserve.
- Service-Checkliste und freie Notizen.
- Teilbarer Servicebericht.
- Keine automatische Sicherheitsfreigabe; Hersteller-/Normvorgaben bleiben maßgebend.

## Nächste Gates

1. App-Icons und Store-Metadaten je App finalisieren.
2. Release-/Signing-Workflow für die fünf Targets aufbauen.
3. TestFlight nacheinander pro App.
4. Store-Review erst nach TestFlight-Prüfung und manueller Freigabe.
