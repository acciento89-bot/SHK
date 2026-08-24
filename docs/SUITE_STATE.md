# SHK Suite – Projektstand

Stand: 2026-08-24

## Aktive Apps

| App | iOS Bundle-ID | Status |
| --- | --- | --- |
| KälteCalc | `de.kamilunav.kaltecalc` | App-Store-Eintrag angelegt, Entwicklung gestartet |
| LüftungsCalc | `de.kamilunavo.luftungscalc` | App-Store-Eintrag angelegt, Entwicklung gestartet |
| HeizkörperCalc | `de.kamilunavo.heizkorpercalc` | App-Store-Eintrag angelegt, Entwicklung gestartet |
| RohrCalc | `de.kamilunavo.rohrcalc` | App-Store-Eintrag angelegt, Entwicklung gestartet |
| AnlagenCheck | `de.kamilunav.anlagencheck` | App-Store-Eintrag angelegt, Entwicklung gestartet |

Die Bundle-IDs werden exakt wie in App Store Connect angelegt verwendet. Sie werden nicht automatisch vereinheitlicht.

## Bewusst nicht umgesetzt

`AbgleichCalc` entfällt. Die hydraulischen Abgleich-, Volumenstrom- und verwandten Funktionen werden durch HydroCalc abgedeckt.

## Architektur

- Ein Repository, fünf eigenständige iOS-App-Targets.
- `SHKCore` enthält gemeinsame, UI-unabhängige Fachberechnungen.
- `SharedUI` enthält das gemeinsame Kamilunavo-SHK-Design.
- Jede App besitzt eigenen Namen, Bundle-ID, Scheme und später eigenen App-Store-Releaseprozess.
- Alle Berechnungen funktionieren offline.

## Nächste Gates

1. Swift-Core-Tests grün.
2. XcodeGen-Projekt erzeugen und alle fünf Schemes im iOS-Simulator bauen.
3. Icons/Store-Metadaten je App.
4. TestFlight nacheinander pro App.
