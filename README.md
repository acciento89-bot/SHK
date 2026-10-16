# SHK Werkstatt

Eine zusammengeführte iOS-Fachwerkstatt für Sanitär, Heizung, Klima und Lüftung. Kunden- und Anlagendaten verbinden Heizkörperauslegung, Rohrstrecken, Anlagenvolumen und Befüllung, Lüftung, Kältemessungen sowie Anlagenprüfung in einem gemeinsamen Projekt und Übergabebericht.

## Aktueller App-Store-Stand

SHK Werkstatt nutzt den bisherigen AnlagenCheck-Eintrag 6804749223 mit Bundle-ID `de.kamilunavo.servicecheck`. Build 1.0 (6) und der dauerhafte Pro-Kauf sind gemeinsam vorbereitet; Status **READY_FOR_REVIEW**, noch nicht eingereicht oder genehmigt. Die tatsächliche iPhone-Duo-Prüfung bleibt offen. Grundfunktionen, ein gespeichertes Projekt und Textbericht sind kostenlos; Pro schaltet weitere Projekte und PDF frei.

Die abgelehnten Einzel-Einträge **RohrCalc, KälteCalc, LüftungsCalc, HeizkörperCalc und VolumeCalc** wurden am 16. Oktober 2026 auf ausdrücklichen Auftrag aus der normalen App-Store-Connect-Liste entfernt. Quellcode, bisherige Targets und historische Builds bleiben erhalten. Keine neuen unabhängigen Uploads dieser alten Einträge ohne neuen Auftrag.

Die genehmigten **HydroCalc SHK, MAGCalc und BrennerCalc** bleiben eigenständige Produkte und wurden nicht verändert oder entfernt. AbgleichCalc wird nicht separat umgesetzt; diese Funktionen werden bereits durch HydroCalc abgedeckt.

## Dokumentation

- [Aktueller Arbeits- und Freigabestand](docs/CURRENT_TASK.md)
- [Projekt- und Portfoliozustand](docs/SUITE_STATE.md)
- [Duo-Prüfung und offene Nachweise](docs/DUO_READINESS.md)
- [Bestätigung der fünf entfernten Einträge](docs/QA/rejected-calculators-removed-20261016.json)

`SHKCore` enthält gemeinsame Fachberechnungen. Die aktuelle Oberfläche nutzt SwiftUI und funktioniert ohne Anmeldung offline. Historische Einzel-Targets sind kein Auftrag, die entfernten Apps wieder zu veröffentlichen.
