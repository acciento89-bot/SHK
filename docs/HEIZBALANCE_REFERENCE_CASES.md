# HeizBalance – Referenzfall-Validierung

## Zweck
Diese Datei sammelt reproduzierbare technische Referenz- und Regressionsfälle für HeizBalance. Sie ersetzt keine DIN-Norm und enthält keine geschützten Normtabellen oder -texte.

## Status der Referenzfälle
- Technische Rechenkerne werden mit transparenten, selbst definierten Eingaben getestet.
- Normative Referenzfälle werden erst ergänzt, wenn die zugrunde liegende Spezifikation rechtmäßig verfügbar, fachlich verifiziert und dokumentiert ist.
- Aktuelle technische Regressionen dürfen nicht als DIN-/GEG-/BEG-Nachweis bezeichnet werden.

## Technischer kv-Referenzfall
Eingaben:
- Volumenstrom: 0,6 m³/h
- Ventil-Druckverlust: 12 kPa
- Dichte: 1.000 kg/m³

Erwartung:
- erforderlicher kv ≈ 1,73 m³/h

Der Fall dient nur der mathematischen Prüfung der technischen kv-Vorbereitung.

## Technisches Niedertemperatur-Musterprojekt `technical-low-temp-demo-001`
Das Entwicklungsprojekt enthält drei Räume und bewusst unterschiedlich dimensionierte Heizflächen. Die Wasserspreizung beträgt 10 K.

Erwartete Minimaltemperaturen:
- Wohnzimmer: ca. 43,8 / 33,8 °C
- Schlafzimmer: ca. 42,7 / 32,7 °C
- Bad: ca. 47,4 / 37,4 °C

Erwartete Systemaussage:
- Das Bad ist thermisch begrenzend.
- 45 / 35 °C reicht für das Gesamtprojekt bewusst nicht aus.
- Eine System-Minimaltemperatur darf nur ausgegeben werden, wenn alle erfassten Heizflächen vollständig auswertbar sind.

Dieser Fall ist eine technische Regression für Heizflächenleistung und fixed-spread-Minimaltemperatur, keine Wärmepumpenauslegung und kein normativer Heizlastfall.

## Technisches 45/35-Szenario
Für dasselbe Musterprojekt wird das explizite Szenario 45 / 35 °C geprüft.

Erwartungen:
- Wohnzimmer: ca. 760 W verfügbar bei 700 W Bedarf → ca. 109 % Deckung.
- Schlafzimmer: ca. 583 W verfügbar bei 500 W Bedarf → ca. 117 % Deckung.
- Bad: ca. 500 W verfügbar bei 600 W Bedarf → ca. 83 % Deckung.
- Bad ist die thermisch schwächste Heizfläche.
- Für das Bad werden bei 45 / 35 °C ungefähr 2.639 W erforderliche ΔT50-Nennleistung ausgewiesen.
- Gegenüber der vorhandenen ΔT50-Nennleistung von 2.200 W ergibt sich ungefähr Faktor ×1,20.

Die App darf daraus ohne autorisierten Herstellerdatensatz kein konkretes Ersatzmodell oder Abmessungen erfinden.

## Persistentes Sanierungsziel / Dashboard
Wenn 45 / 35 °C im Musterprojekt als Sanierungsziel gespeichert wird, muss derselbe fachliche Zustand projektweit wiederverwendet werden:
- Zieltemperatur bleibt nach erneutem Öffnen des Projekts erhalten.
- Szenarioauswertung, PDF-Szenario-Snapshot und Archiv verwenden denselben gespeicherten Zielwert.
- Das Dashboard zeigt `Upgradebedarf`, weil nicht alle Heizflächen ausreichend sind.
- Begrenzende Heizfläche ist das Bad.
- Dashboard-Ausgabe für das Bad bleibt ungefähr 2.639 W erforderliche ΔT50-Nennleistung und Faktor ×1,20.
- Bei unvollständigen Heizflächendaten muss statt einer positiven/negativen Zielaussage `Daten unvollständig` erscheinen.

Auch diese Prüfung ist eine technische Regression und keine normative Aussage.

## Technischer Pumpenkennlinien-Referenzfall
Der Pumpenvergleich verwendet das Rechenprofil `linear-documented-pump-curve-v1`.

Dokumentierte Kennlinienpunkte:
- Punkt P1: 1,0 m³/h → 4,0 m Förderhöhe → 28 W elektrische Aufnahme
- Punkt P2: 2,0 m³/h → 2,0 m Förderhöhe → 40 W elektrische Aufnahme

Projekt-Betriebspunkt:
- Volumenstrom: 1,5 m³/h
- erforderliche Förderhöhe: 3,2 m

Erwartete technische Zwischenwerte:
- Kennlinien-Förderhöhe bei 1,5 m³/h: 3,0 m
- elektrische Aufnahme bei 1,5 m³/h: 34 W
- Förderhöhenreserve: −0,2 m
- Ergebnis: hydraulisch nicht ausreichend
- verwendete Begrenzungspunkte: P1 und P2
- der Wert ist ein linearer technischer Zwischenwert, keine Herstellerfreigabe

Zusätzliche harte Regeln:
- Ein exakt dokumentierter Volumenstrompunkt wird unverändert verwendet.
- Unterhalb des kleinsten oder oberhalb des größten dokumentierten Volumenstroms wird kein Ergebnis erzeugt; HeizBalance extrapoliert Pumpenkennlinien nicht.
- Die elektrische Aufnahme wird nur interpoliert, wenn beide begrenzenden Punkte einen dokumentierten Leistungswert enthalten.
- Aus dem Vergleich folgt keine automatische Pumpenauswahl, Regelartwahl oder Effizienzfreigabe.

## Technische Pumpen-Leistungskennzahlen `pump-technical-metrics-v1`
Eingaben:
- Volumenstrom: 1,5 m³/h
- erforderliche Förderhöhe: 3,2 m
- verfügbare Kennlinien-Förderhöhe: 4,0 m
- Fluiddichte: 998 kg/m³
- dokumentierte elektrische Aufnahme P₁: 34 W
- dokumentierter Kennlinienbereich: 0,0 bis 2,0 m³/h

Erwartungen:
- erforderliche hydraulische Leistung: ca. 13,05 W
- hydraulische Leistung bei 4,0 m Kennlinien-Förderhöhe: ca. 16,31 W
- Förderhöhenreserve: 0,8 m
- Förderhöhenreserve bezogen auf den Bedarf: 25 %
- Verhältnis `Pₕ,erf / P₁`: ca. 38,4 %
- Position des Betriebspunkts im dokumentierten Volumenstrombereich: 75 %

Harte Interpretationsregeln:
- `Pₕ,erf / P₁` ist lediglich eine technische Verhältniskennzahl aus Projektbedarf und dokumentierter elektrischer Aufnahme.
- Die Kennzahl ist **kein** geprüfter Pumpenwirkungsgrad, kein EEI-/ErP-Nachweis und keine Hersteller-Effizienzfreigabe.
- Ohne dokumentierte elektrische Aufnahme wird kein Verhältniswert erfunden.
- Ohne explizite gültige Fluiddichte wird keine hydraulische Leistungskennzahl ausgegeben.
- Die Kennlinienbereichsposition wird nur berechnet, wenn Minimum und Maximum dokumentiert sind und der Betriebspunkt innerhalb dieses Bereichs liegt.

## Direkter katalogübergreifender Pumpenvergleich
Für einen vollständigen Projekt-Betriebspunkt muss der Vergleich alle importierten Kennlinien in drei technisch nachvollziehbare Zustände aufteilen:
- Förderhöhe technisch ausreichend
- Förderhöhe technisch nicht ausreichend
- Betriebspunkt außerhalb des dokumentierten Kennlinienbereichs

Die App darf ausreichende Kennlinien zur besseren Lesbarkeit zuerst gruppieren. Innerhalb der Gruppen erfolgt nur eine deterministische alphabetische Sortierung; daraus darf keine Rangliste oder automatische Produktempfehlung abgeleitet werden. Nur eine technisch ausreichende Kennlinie darf durch einen ausdrücklichen Benutzer-Tap als Projektauswahl festgehalten werden.

## Vor-Ort-Aufnahme – Copy-/Vorlagen-Invarianten
Diese Regeln schützen vor verstecktem Mitkopieren alter technischer Entscheidungen. Sie sind Workflow-Regressionen, keine normativen Rechenfälle.

### Geschoss duplizieren
- Das neue Geschoss erhält eine neue ID.
- Jeder kopierte Raum erhält eine neue ID.
- Jedes kopierte Bauteil und jede kopierte Heizfläche erhält eine neue ID.
- Raumgeometrie, Solltemperatur, Luftwechsel-Eingaben, Bauteil-U-Werte und physische Heizflächendaten dürfen als Aufnahmehilfe übernommen werden.
- Raumnummern werden nicht übernommen.
- Heizflächen-Zuordnung der erforderlichen Leistung, Rohrabschnitte, hydraulische Bauteilverluste, Hydraulik-Vollständigkeitsstatus und Ersatzheizkörper-Auswahl werden nicht übernommen.

### Raum duplizieren
- Die neue Raum-ID muss sich vom Ursprung unterscheiden.
- Ein eindeutiger Kopiename wird erzeugt.
- Bauteile und Heizflächen werden über dieselben Sicherheitsregeln wie beim Geschosskopieren neu erzeugt.

### Bauteil duplizieren
- Neue ID.
- Art, Bezeichnung, Fläche, U-Wert, U-Wert-Quelle, thermische Randbedingung und Notiz dürfen übernommen werden.
- Es entsteht keine gemeinsame Referenz auf das Ursprungsbauteil.

### Heizfläche duplizieren
- Neue ID.
- Physische Daten wie Art, Hersteller, Modell, Nennleistung ΔT50, Exponent, Quelle und Notiz dürfen übernommen werden.
- `assignedRequiredPowerW`, Rohrnetz, hydraulische Verlustbauteile, Hydraulik-Vollständigkeit und `replacementSelection` müssen leer sein.

### Raum-Schnellvorlagen und Bauteilsätze
- Raum-Schnellvorlagen dürfen nur Name/Typ als Aufnahmehilfe setzen und keine normativen Luftwechsel-/U-Wert-Annahmen einführen.
- Bauteilsätze erzeugen nur Bauteilarten; Fläche und U-Wert bleiben leer bzw. 0/nil.

### Eigene Bauteilvorlage `component-favorite-v1`
Eine gespeicherte Vorlage darf enthalten:
- Bauteilart
- Bezeichnung
- U-Wert
- dokumentierte U-Wert-Quelle
- Notiz / Aufbauhinweis

Sie darf **nicht** enthalten:
- Bauteilfläche
- raumspezifische Gegenseitentemperatur

Beim Anwenden auf ein bestehendes Bauteil bleibt die bereits erfasste Fläche bestehen. Die thermische Randbedingung wird auf den Standard der gewählten Bauteilart gesetzt; eine erforderliche Gegenseitentemperatur muss anschließend explizit im Projekt geprüft/eingegeben werden. Ein ungültiger U-Wert ≤ 0 darf nicht als Favorit persistiert werden.

## Hydraulik-Wiederverwendung – Invarianten `hydraulic-capture-template-v1`
Eine Hydraulikvorlage darf als reine Aufnahmehilfe enthalten:
- Rohrabschnittsname und Rolle
- realen Innendurchmesser
- hydraulische Länge
- Rauheit
- explizite ζ-Summe
- Rohrnotiz
- Art/Name eines hydraulischen Bauteils
- Bauteilnotiz
- dokumentierte Ventilprodukt-Identität und deren Provenienz

Sie darf **nicht** als fertige Entscheidung wiederverwenden:
- expliziten Abschnittsvolumenstrom einer gemeinsamen Verteilung
- Quelle dieses Abschnittsvolumenstroms
- Bauteil-Druckverlust Δp
- Quelle des Bauteil-Druckverlusts
- Vollständigkeitsbestätigung des Kreises
- konkrete Thermostat-/Rücklaufeinstellung

Beim Anwenden einer Vorlage werden neue Rohr-/Bauteil-IDs erzeugt. Bestehende festgehaltene Ventileinstellungen der ersetzten Bauteile müssen aus dem Selection-Store entfernt werden, damit keine verwaiste Entscheidung weiter angezeigt wird.

## Sichere komplette Heizkreiskopie
Beim Kopieren eines kompletten Heizflächenkreises im Hydraulik-Workspace gilt:
- neue Heizflächen-ID
- neue Rohrabschnitts-IDs
- neue hydraulische Bauteil-IDs
- physische Heizflächendaten dürfen übernommen werden
- sichere Rohrstruktur und Ventilprodukt-Identität dürfen übernommen werden
- `assignedRequiredPowerW` wird gelöscht
- explizite gemeinsame Abschnittsvolumenströme und deren Quellen werden gelöscht
- Bauteil-Δp und deren Quellen werden gelöscht
- Vollständigkeitsstatus wird `false`
- Ersatzheizkörperauswahl wird gelöscht
- konkrete TV-/RL-Einstellungs-Snapshots werden aufgrund neuer Komponenten-IDs nicht übernommen

Damit kann ein wiederkehrender Strang schnell aufgenommen werden, ohne den hydraulischen Zustand des Ursprungs als Ergebnis zu kopieren.

## Explizite Ventileinstellung `valve-setting-selection-v1`
Eine konkrete Thermostat- oder Rücklaufeinstellung darf nur durch ausdrücklichen Benutzer-Tap auf einen dokumentierten Hersteller-Datenpunkt erzeugt werden.

Zum Zeitpunkt der Auswahl werden mindestens eingefroren:
- Projekt-, Heizflächen- und Bauteil-ID
- Bauteilart und Name
- gewählte Einstellung
- kv des gewählten Datenpunkts
- damals erforderlicher Soll-kv
- Zielvolumenstrom
- Ventil-Δp
- Fluiddichte
- Hersteller / Produkt / Datensatzversion
- Produkt-/Datensatz-ID soweit vorhanden
- Quelle, Nutzungsgrundlage und Rechtehinweis

### Stale-/Neu-bewerten-Regel
Eine festgehaltene Einstellung ist nur `aktuell`, solange unter anderem unverändert bleiben:
- dasselbe hydraulische Bauteil
- Zielvolumenstrom
- Ventil-Δp
- Fluiddichte
- daraus berechneter Soll-kv
- Hersteller-/Produkt-/Datensatzidentität
- der gewählte Einstellpunkt mit demselben dokumentierten kv

Ändert sich einer dieser relevanten Werte, muss die Auswahl als `neu bewerten` erscheinen. HeizBalance darf weder die alte Auswahl still aktualisieren noch automatisch einen anderen Datenpunkt festhalten.

## Baustellen-Einstellliste `technical-adjustment-list-v1`
Die technische Einstellliste ist ein eigener Arbeitsnachweis und kein normativer Verfahren-B-Nachweis.

Pro Heizflächenkreis erwartet der Snapshot:
- Geschoss, Raum, Heizfläche
- Zielvolumenstrom, soweit berechenbar
- vollständiger Kreis-Δp, soweit freigegeben
- erfasste Thermostatventile
- erfasste Rücklaufventile
- aktueller Soll-kv je auswertbarem Ventil
- ausdrücklich festgehaltene Einstellung/kv
- Status `aktuell`, `neu bewerten` oder nicht festgehalten
- offene/missing Hinweise

Projektweit kann zusätzlich die ausdrücklich festgehaltene Pumpen-/Kennlinienentscheidung mit ihrem Aktualitätsstatus erscheinen.

### Harte Listenregeln
- Fehlt der Zielvolumenstrom, wird `Q offen` bzw. ein entsprechender Hinweis ausgegeben.
- Fehlt ein vollständiger Kreis-Δp, wird kein vollständiger Druckverlust behauptet.
- Ein erfasstes Ventil ohne ausdrückliche Auswahl bleibt `nicht festgehalten`.
- Eine veraltete Ventil- oder Pumpenauswahl wird sichtbar als `neu bewerten` markiert.
- Der PDF-Footer bezeichnet das Dokument dauerhaft als technische Vorbereitung und schließt Verfahren-B-/GEG-/BEG-/Herstellerfreigabe aus.
- Das Layout ist eine eigene kompakte Baustellenliste und kein kopiertes VdZ-Formular.
- Erst nach erfolgreichem PDF-Export wird exakt derselbe `technical-adjustment-list-v1`-Snapshot archiviert.
- Abgebrochene/fehlgeschlagene Exporte erzeugen keinen falschen Archivstand.
- Pro Projekt werden maximal die letzten 10 Einstelllisten-Snapshots gehalten.
