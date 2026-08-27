# HeizBalance – Hydraulik-Recherche

## Zweck
Diese Datei dokumentiert öffentlich prüfbare Grundlagen für technische Hydraulik-Vorbereitungen. Sie ersetzt weder Herstellerunterlagen noch normative Fachprüfung.

## kv-Grundlage für Flüssigkeiten
Bürkert beschreibt den kv-Wert als standardisierten Durchflusskennwert eines Ventils. Für Flüssigkeiten kann der erforderliche kv-Wert aus Volumenstrom, Flüssigkeitsdichte und Druckverlust berechnet werden:

`kv = Q × sqrt((rho / 1000) / deltaP)`

mit:
- `Q` in m³/h
- `rho` in kg/m³
- `deltaP` in bar
- Ergebnis `kv` in m³/h

Öffentliche Quelle:
- Bürkert Fluidic Calculator / Flow factor: https://www.burkert.com/en/service-support/knowledge-center/glossary/fluid-calculator

Bürkert verweist dort für die Definition des kv-Werts auf DIN EN 60534 sowie VDI/VDE 2173. Diese Norminhalte selbst werden nicht in das Repository übernommen.

## Öffentlicher Plausibilitätsfall
Ein Danfoss-Datenblatt zeigt für Wasser:
- Q = 0,6 m³/h
- Ventil-Druckverlust = 12 kPa = 0,12 bar
- daraus kv ≈ 1,73 m³/h

Öffentliche Quelle:
- Danfoss KOVM data sheet, Abschnitt Sizing: https://assets.danfoss.com/documents/latest/74266/AI141986475466en-010801.pdf

Dieser öffentliche Beispielpunkt wird als technischer Unit-Test verwendet, ohne Tabellen oder geschützte Herstellerkennlinien zu kopieren.

## Freigabegrenzen
- HeizBalance berechnet in diesem Entwicklungsstand nur einen technischen erforderlichen kv-Rechenwert.
- Eine Ventil-Voreinstellung wird daraus nicht automatisch erzeugt.
- Die Zuordnung kv → konkrete Voreinstellung erfordert die autorisierte Kennlinie des tatsächlich eingesetzten Ventils.
- Viskositäts-/Sondermedienkorrekturen und herstellerspezifische Einsatzgrenzen werden nicht erfunden; sie müssen separat fachlich validiert werden.
- Der kv-Rechenwert ist kein Verfahren-B-Nachweis.
