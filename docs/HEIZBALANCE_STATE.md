# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Heizlast, Heizflächenprüfung, Niedertemperaturbewertung und hydraulischen Abgleich mit nachvollziehbarer Projektdokumentation.

## Produktname
- App Store: HeizBalance
- Technischer Target-Name: HeizBalance
- Bundle Identifier: `de.kamilunavo.heizbalance`
- App Store Connect: angelegt am 25.08.2026

## Normstrategie
- Rechenverfahren werden eigenständig implementiert.
- Keine DIN-Texte, Tabellen, Grafiken oder sonstigen geschützten Norminhalte werden in die App kopiert.
- Rechenengine und Berichtsschemata werden versioniert, damit Regelwerks- und Ausgabeänderungen später getrennt gepflegt werden können.
- Referenzfälle und Regressionstests sind vor einer fachlichen Release-Freigabe verpflichtend.
- Eine technische Vorberechnung darf nicht als Norm-Heizlast oder Verfahren-B-Nachweis bezeichnet werden, solange die normative Engine und Referenzvalidierung nicht vollständig sind.
- Aktueller Rechts-/Regelwerksbezug und öffentliche Quellen sind in `docs/HEIZBALANCE_NORM_RESEARCH.md` dokumentiert.

## Geplanter Funktionsumfang
### Phase 1 – Heizlast
- Projekte, Gebäude, Nutzungseinheiten und Räume
- Geometrie und Bauteilflächen
- U-Werte und Randbedingungen
- Transmissions- und Lüftungswärmeverluste
- Raumweise Heizlast und Gebäudeübersicht
- Eingabeherkunft kennzeichnen: Mess-/Nachweiswert / Plan / Hersteller / fachlich ermittelt / geschätzt
- Projektbericht / PDF

### Phase 2 – Hydraulischer Abgleich
- Vorhandene Heizflächen erfassen
- Heizflächenleistung bei gewählten Systemtemperaturen prüfen
- Soll-Volumenströme je Heizfläche
- Rohrnetz und Druckverluste
- Ventilauslegung / Soll-kv bzw. Durchfluss
- Pumpenanforderung und Anlagen-Gesamtvolumenstrom
- Dokumentation der Einstellwerte

### Phase 3 – Herstellerdaten & Wärmepumpen-Optimierung
- Freigegebene Hersteller-/Produktdatensätze
- Ventilvoreinstellungen ausschließlich aus autorisierten und dokumentierten Produktdaten
- Niedertemperatur-Check und minimale technisch ausreichende Vorlauftemperatur
- Später getrennt davon: echte Wärmepumpenauslegung, Leistungs-/Bivalenz- und Effizienzbewertung

### Phase 4 – Flächenheizung
- Fußboden-, Wand- und Deckenheizung als separates Fachmodul

## Qualitäts-Gates
1. Keine proprietären Norminhalte im Repository.
2. Jede normative Rechenfunktion erhält Unit Tests.
3. Referenzgebäude mit erwarteten Zwischenergebnissen.
4. Ergebnisse werden gegen etablierte Fachsoftware bzw. fachlich geprüfte Referenzrechnungen gegengeprüft.
5. Rechenweg, Eingabeherkunft und Annahmen müssen im Projektbericht nachvollziehbar sein.
6. Keine GEG-/BEG-Konformitätsaussage ohne fachliche Prüfung des vollständigen Verfahrens.
7. Nicht normative Vorbereitungen werden in UI, Code und Bericht eindeutig als solche gekennzeichnet.
8. Normative Ausgaben bleiben technisch gesperrt, bis alle Validierungsgates erfüllt sind.
9. Ein einzelner Profil-/Release-Schalter darf die normative Ausgabe nicht freigeben; alle verpflichtenden Module müssen Spezifikation und Referenzabdeckung erfüllen.
10. Eine Ventilvoreinstellung darf nur aus einem dokumentierten Produktdatensatz stammen; ein mathematisch nächster kv-Datenpunkt ist keine automatische Empfehlung.
11. Ein Pumpen-Betriebspunkt darf nur bei vollständig bekannten Verbraucherströmen und vollständigen Kreis-Druckverlusten ausgegeben werden.
12. Eine minimale Systemtemperatur darf nur ausgegeben werden, wenn jede erfasste Heizfläche mit Nennleistung, Exponent und zugeordneter erforderlicher Leistung auswertbar ist.
13. Der Niedertemperatur-Check ist eine Heizflächenbewertung und darf nicht als Wärmepumpenauslegung, COP-/Bivalenznachweis oder Norm-Heizlast ausgegeben werden.

## Aktueller Stand – Foundation Pass 11
- Branch `feature/heizbalance-foundation` und Draft-PR #12 aktiv.
- XcodeGen-Target `HeizBalance` mit Bundle-ID `de.kamilunavo.heizbalance` eingebunden.
- Persistente lokale Projektstruktur Projekt → Geschoss → Raum → Bauteil vorhanden.
- Projektaufnahme: Kunde, Adresse, Baujahr, Auslegungs-Außentemperatur, Quellenangaben, System-Vorlauf/Rücklauf, explizite Hydraulik-Fluidwerte und Notizen.
- Raumaufnahme: Geometrie, Solltemperatur, Luftwechsel, Quellenangabe und optionale Heizflächen.
- Bauteilaufnahme: Art, Fläche, U-Wert, U-Wert-Quelle und thermische Randbedingung.
- Randbedingungen unterstützen Außenluft oder explizite Gegenseitentemperatur; für Boden/Decke/unbeheizte Bereiche werden keine erfundenen Pauschalwerte eingesetzt.
- `HeizBalanceHeatLossPreviewCalculator` berechnet technische Transmission und Lüftung aus expliziten Eingaben.
- Vorberechnung je Raum zeigt Transmission, Lüftung, Summe und W/m²; eine Gebäudesumme wird nur ausgegeben, wenn alle Räume vollständig sind.
- Versionierte Rechenprofile im SHKCore vorhanden; `technical-preview-v1` ist ausdrücklich nicht normativ.
- `de-room-heat-load-2017-2020` ist als reserviertes Profil für DIN EN 12831-1:2017-09 + DIN/TS 12831-1:2020-04 angelegt; normative Ausgabe ist technisch gesperrt.
- Normative Validierung ist in Pflichtmodule aufgeteilt; `HeizBalanceNormativeReadiness` verlangt verifizierte Spezifikation, vollständige Referenzabdeckung, Profil-Lifecycle und explizite Release-Freigabe.
- Heizflächenaufnahme pro Raum: Art, Bezeichnung, Hersteller, Modell, Nennleistung ΔT50, Exponent, Datenquelle, zugeordnete erforderliche Leistung und Notiz.
- Heizflächenleistung und erforderliche Leistung sind getrennt. Der technische Ziel-Volumenstrom entsteht aus zugeordneter erforderlicher Leistung und Wasserspreizung.
- Raumübersicht vergleicht technische Raum-Vorbereitung, verfügbare Heizflächenleistung, zugeordnete Leistungen und aufsummierte Ziel-Volumenströme.
- Hydraulik-Fluidwerte werden explizit erfasst: Dichte in kg/m³ und kinematische Viskosität in mm²/s. Keine versteckten Wasser-/Glykolannahmen.
- Pro Heizfläche können Rohrabschnitte mit Innendurchmesser, hydraulischer Länge, absoluter Rauheit und optionaler ζ-Summe erfasst werden.
- Rohrabschnitte unterscheiden `Heizflächen-Anbindung` und `Gemeinsame Verteilung`. Anbindeleitungen verwenden den Heizflächen-Zielvolumenstrom; gemeinsame Verteilrohre benötigen ihren tatsächlichen Abschnitts-Volumenstrom.
- `HeizBalanceHydronicCircuitCalculator` berechnet je Abschnitt Volumenstrom, Geschwindigkeit, Reynolds-Zahl, Rohrreibung und bekannte Einzelwiderstandsverluste.
- Ein vollständiger Rohrkreis-Druckverlust wird nur ausgegeben, wenn die ζ-Abdeckung vollständig ist; sonst bleibt die Ausgabe eine klar bezeichnete Teilsumme.
- Hydraulische Bauteilverluste werden getrennt erfasst: Thermostatventil, Rücklaufverschraubung, Heizfläche, Verteiler/Sammler und sonstige Bauteile mit explizitem Δp und Quelle.
- Ein vollständiger Heizflächenkreis wird nur ausgegeben, wenn Rohrweg, Bauteilwerte und die explizite Bauteil-Vollständigkeitsbestätigung vorliegen.
- `HeizBalanceValveSizingPreparationCalculator` berechnet aus Ziel-Volumenstrom, Ventil-Δp und Fluiddichte den technischen erforderlichen kv-Wert.
- Die kv-Berechnung wurde mit einem öffentlich dokumentierten Referenzfall 0,6 m³/h bei 12 kPa gegengeprüft; Ergebnis rund kv 1,73 m³/h.
- Projektaggregation bestimmt Gesamt-Verbrauchervolumenstrom und hydraulisch ungünstigsten vollständigen Kreis. Druckverluste paralleler Kreise werden nicht addiert.
- Ein technischer Pumpen-Betriebspunkt wird nur ausgegeben, wenn alle Verbraucherströme und alle Kreis-Druckverluste vollständig sind.
- Projekt-Dashboard zeigt Hydraulikkreis-Abdeckung, Gesamtvolumenstrom, ungünstigsten Kreis, erforderliches Netz-Δp und äquivalente Förderhöhe bzw. klare Sperrhinweise bei unvollständigen Daten.
- Optionale Ventil-Produktdatensätze sind vorhanden: Hersteller, Produkt, Datenstand, Quelle/Referenz sowie diskrete Punkte `Voreinstellung → kv`.
- `HeizBalanceValvePresetComparisonCalculator` prüft den Soll-kv gegen einen expliziten Datensatz und zeigt unteren/oberen sowie mathematisch nächstliegenden Datenpunkt, Bereichsstatus und Abweichung. Dies ist ausdrücklich keine automatische Voreinstellung.
- Projektweiter `Ventildaten & Kennlinien`-Manager findet Thermostat-/Rücklaufventile, zeigt Soll-kv und erlaubt die dokumentierte Pflege echter Produktdaten.
- Neue Ventil-/Reportfelder sind optional angelegt, damit bestehende gespeicherte Projekte ohne diese Schlüssel weiterhin decodierbar bleiben.

### Niedertemperatur-/Wärmepumpen-Vorbereitung
- `HeizBalanceLowTemperatureCheckCalculator` berechnet aus Nennleistung ΔT50, Exponent, zugeordneter erforderlicher Leistung, Raumtemperatur und expliziter Wasserspreizung die technisch minimal erforderliche mittlere Übertemperatur sowie die daraus resultierende minimale Vorlauf-/Rücklauftemperatur.
- Der Projektcheck hält aktuell bewusst die im Projekt hinterlegte Wasserspreizung konstant; es wird keine neue Spreizung versteckt angenommen.
- Eine System-Minimaltemperatur wird nur ausgegeben, wenn jede erfasste Heizfläche vollständig auswertbar ist.
- Der hydraulisch bzw. thermisch begrenzende Heizkörper wird als die Heizfläche mit der höchsten erforderlichen Vorlauftemperatur ausgewiesen.
- Eine frei änderbare Vergleichs-Vorlauftemperatur zeigt in der UI je Heizfläche und für das Gesamtprojekt, ob die zugeordnete Leistung bei dieser Temperatur und gleicher Spreizung erreicht wird.
- Die Funktion wird ausdrücklich als Heizflächen-/Niedertemperatur-Check bezeichnet, nicht als Wärmepumpenauslegung.
- Ein fiktives End-to-End-Musterprojekt mit drei Räumen kann über das Entwicklungsmenü angelegt werden. Es ist klar als technischer Testdatensatz gekennzeichnet und darf vor Produktionsfreigabe nicht als normales Benutzerfeature sichtbar bleiben.
- Technischer Regressionfall `technical-low-temp-demo-001`: bei 10 K Spreizung ergibt sich im Muster ca. 43,8/33,8 °C für Wohnzimmer, 42,7/32,7 °C für Schlafzimmer und 47,4/37,4 °C für das Bad. Damit reicht 45/35 °C bewusst nicht für das gesamte Musterprojekt; begrenzend ist das Bad.
- Die exakten Erwartungswerte sind als Unit-Test und in `docs/HEIZBALANCE_REFERENCE_CASES.md` festgehalten. Der Fall ist ausdrücklich kein DIN-/Norm-Referenzfall.

### Bericht, PDF und Reproduzierbarkeit
- `HeizBalanceTechnicalReportSnapshot` mit Schema `technical-report-v1` friert den technischen Projektstand reproduzierbar ein: Projekt-/Quellendaten, Räume, Wärmeverluste, Heizflächen, Rohrabschnitte, Hydraulikbauteile, Soll-kv, Ventildatensätze, Kreissummen und Systembetriebspunkt.
- Der Haupt-Report-Snapshot enthält harte Statusflags: Norm-Heizlast nicht freigegeben, Verfahren B nicht freigegeben, automatische Ventilvoreinstellung nicht freigegeben, Pumpenauswahl nicht freigegeben.
- Ein eigener A4-Mehrseiten-PDF-Renderer erzeugt aus dem Hauptsnapshot einen technischen Projektbericht mit Seitenkopf/-fuß und vollständiger Kennzeichnung als technische Vorbereitung.
- Erfolgreiche PDF-Exporte archivieren den exakt verwendeten `technical-report-v1`-JSON-Snapshot lokal, projektweise auf die letzten 10 Exporte begrenzt. Abgebrochene/fehlgeschlagene PDF-Exporte erzeugen keinen falschen Archivstand.
- Für den Niedertemperaturteil existiert zusätzlich der getrennt versionierte Begleit-Snapshot `technical-low-temperature-v1` mit Rechenprofil `fixed-spread-emitter-check-v1`.
- Hauptbericht und Niedertemperatur-Supplement werden zu einem gemeinsamen PDF zusammengeführt. Beide Snapshots erhalten beim Export denselben Zeitstempel und werden nach erfolgreichem Export getrennt archiviert.
- Durch die getrennten Schemata bleiben bereits archivierte ältere `technical-report-v1`-Dateien unverändert lesbar; der Niedertemperaturteil kann unabhängig weiterentwickelt/versioniert werden.
- `Technischer Bericht & PDF` ist im Projekt verlinkt. Unvollständige Werte bleiben als fehlend erkennbar und werden nicht durch Annahmen ersetzt.
- Keine Hersteller-Typentabellen, Ventilkennlinien oder Voreinstellwerte werden erfunden oder ungeprüft hinterlegt.

## Validierte CI-Checkpoints
- #50 Heizflächenaufnahme/Leistungs- und Volumenstrom-Vorbereitung: komplett grün.
- #53 Trennung erforderliche/verfügbare Leistung und technischer Ziel-Volumenstrom: komplett grün.
- #55 Raum-Heizflächenabdeckung nach Dateinamen-Fix: komplett grün.
- #57 Rohrnetz-/Druckverlust-Vorbereitung: komplett grün.
- #61 explizite Bauteilverluste und harte Kreis-Vollständigkeit: komplett grün.
- #62 Soll-kv-Engine und Referenzfall: komplett grün.
- #66 abschnittsspezifische Volumenströme / gemeinsame Verteilung + kv-Anzeige: komplett grün.
- #68 hydraulische Projektaggregation: komplett grün.
- #73 Ventil-Datensatzvergleich und optionale Produktdatenmodelle: komplett grün inklusive Core-Tests und kompletter iOS-Matrix.
- #78 PDF-Renderer und Exportansicht: komplette iOS-Matrix grün.
- #79 Link-Stand `Technischer Bericht & PDF`: HeizBalance und iOS-Builds grün.
- #82 Report-Snapshot-Archiv nach erfolgreichem PDF-Export: komplett grün inklusive Core-Tests und kompletter iOS-Matrix.
- #92 Niedertemperatur-Core, Projektcheck, Musterprojekt und technischer Regressionfall: komplett grün inklusive Core-Tests und kompletter iOS-Matrix.
- #96 Niedertemperatur-Snapshot, Zusatzrenderer und PDFKit-Merger: HeizBalance-Build grün.
- #97 vollständige Verdrahtung Hauptbericht + Niedertemperatur-PDF + Doppelarchiv: komplett grün inklusive Core-Tests und kompletter iOS-Matrix.

## Nächster Entwicklungsschritt
1. Entwicklungsmenü/Musterprojekt vor einem Produktionsbuild hinter `DEBUG` bzw. einen expliziten internen Testschalter legen.
2. PDF-Bericht mit größeren Musterprojekten (mehrere Geschosse, viele Heizflächen, lange Notizen) auf Seitenumbrüche und Lesbarkeit härten; keine fremden Formularlayouts kopieren.
3. Herstellerdaten-Importstrategie definieren: nur rechtmäßig nutzbare/autorisiert bereitgestellte Daten, idealerweise strukturierte Produktdaten statt manueller Copy/Paste-Tabellen.
4. Niedertemperatur-Szenarien erweitern: alternative explizite Spreizungen als Szenario statt versteckter Annahme; weiterhin klare Trennung von Wärmepumpenauslegung und Heizflächencheck.
5. Fachliche Spezifikation der einzelnen Norm-Heizlastbausteine anhand rechtmäßig zugänglicher Regelwerksunterlagen und verifizierter Referenzfälle erstellen.
6. Referenzfälle je Normmodul sammeln und den Norm-Gate-Status erst nach echter Prüfung füllen.
7. Erst nach diesen fachlichen Gates Verfahren-B-Ausgabe und normative Heizlast schrittweise freigeben.
