# SHK Suite – Projektstand

Stand: 2026-08-24

## Aktive Apps

| App | iOS Bundle-ID | Status |
| --- | --- | --- |
| KälteCalc | `de.kamilunav.kaltecalc` | v1-Funktionsstand auf `main`, CI grün |
| LüftungsCalc | `de.kamilunavo.luftungscalc` | v1-Funktionsstand auf `main`, CI grün |
| HeizkörperCalc | `de.kamilunavo.heizkorpercalc` | v1-Funktionsstand auf `main`, CI grün |
| RohrCalc | `de.kamilunavo.rohrcalc` | v1-Funktionsstand auf `main`, CI grün |
| AnlagenCheck | `de.kamilunavo.servicecheck` | App-Store-Name AnlagenCheck; v1-Funktionspass in Validierung |

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

1. AnlagenCheck v1 vollständig grün mergen.
2. App-Icons und Store-Metadaten je App finalisieren.
3. Release-/Signing-Workflow für die fünf Targets aufbauen.
4. TestFlight nacheinander pro App.
