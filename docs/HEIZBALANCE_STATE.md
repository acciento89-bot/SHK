# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Heizlast, Heizflächenprüfung und hydraulischen Abgleich mit nachvollziehbarer Projektdokumentation.

## Produktname
- App Store: HeizBalance
- Technischer Target-Name: HeizBalance
- Bundle Identifier: `de.kamilunavo.heizbalance`
- App Store Connect: angelegt am 25.08.2026

## Normstrategie
- Rechenverfahren werden eigenständig implementiert.
- Keine DIN-Texte, Tabellen, Grafiken oder sonstigen geschützten Norminhalte werden in die App kopiert.
- Rechenengine und Berichtsschema werden versioniert, damit Regelwerks- und Ausgabeänderungen später getrennt gepflegt werden können.
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
- Niedertemperatur-Check und minimale sinnvolle Vorlauftemperatur

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

## Aktueller Stand – Foundation Pass 10
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
- `HeizBalanceTechnicalReportSnapshot` mit Schema `technical-report-v1` friert den technischen Projektstand reproduzierbar ein: Projekt-/Quellendaten, Räume, Wärmeverluste, Heizflächen, Rohrabschnitte, Hydraulikbauteile, Soll-kv, Ventildatensätze, Kreissummen und Systembetriebspunkt.
- Der Report-Snapshot enthält harte Statusflags: Norm-Heizlast nicht freigegeben, Verfahren B nicht freigegeben, automatische Ventilvoreinstellung nicht freigegeben, Pumpenauswahl nicht freigegeben.
- Ein eigener A4-Mehrseiten-PDF-Renderer erzeugt aus dem Snapshot einen technischen Projektbericht mit Seitenkopf/-fuß und vollständiger Kennzeichnung als technische Vorbereitung.
- `Technischer Bericht & PDF` ist im Projekt verlinkt; der aktuelle Arbeitsstand kann per iOS-Dateiexport als PDF gespeichert werden. Unvollständige Werte bleiben als fehlend erkennbar und werden nicht durch Annahmen ersetzt.
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
- #78 PDF-Renderer und Exportansicht: HeizBalance und komplette iOS-Matrix grün; Core enthielt seit #73 keine Änderungen.
- #79 aktueller Link-Stand `Technischer Bericht & PDF`: HeizBalance und iOS-Builds grün; Core enthält seit #73 keine Änderungen.

## Nächster Entwicklungsschritt
1. PDF-Bericht fachlich/visuell gegen reale Beispielprojekte prüfen und Ausgabe bei langen Projekten härten; keine fremden Formularlayouts kopieren.
2. Einen versionierten Report-/Berechnungs-Snapshot beim tatsächlichen Export optional im Projekt archivieren, damit spätere Änderungen nachvollziehbar bleiben.
3. Herstellerdaten-Importstrategie definieren: nur rechtmäßig nutzbare/autorisiert bereitgestellte Daten, idealerweise strukturierte Produktdaten statt manueller Copy/Paste-Tabellen.
4. Fachliche Spezifikation der einzelnen Norm-Heizlastbausteine anhand rechtmäßig zugänglicher Regelwerksunterlagen und verifizierter Referenzfälle erstellen.
5. Referenzfälle je Normmodul sammeln und den Norm-Gate-Status erst nach echter Prüfung füllen.
6. Danach Niedertemperatur-/Wärmepumpenoptimierung auf Basis der bereits erfassten Heizflächen vorbereiten.
