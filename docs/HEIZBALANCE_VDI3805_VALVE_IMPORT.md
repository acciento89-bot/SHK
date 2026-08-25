# HeizBalance – VDI 3805 Armaturen-Import

## Zweck

HeizBalance unterstützt eine Adapter-Schicht für Heizungsarmaturen mit Bezug auf **VDI 3805 Blatt 2**.

Der Adapter ist bewusst **kein im Repository nachgebauter Rohparser der Richtlinie**. Er verarbeitet ausschließlich eine normalisierte Mappingdatei, die aus einer rechtmäßig nutzbaren Hersteller-/Lizenzquelle oder einem entsprechend autorisierten Konverter erzeugt wurde.

Intern wird das Mapping in das stabile HeizBalance-Schema `valve-product-dataset-v1` überführt. Projektventile können anschließend ausdrücklich mit einem Produkt aus diesem Katalog verknüpft werden. Die vorhandene Soll-kv-Berechnung und der Vergleich mit diskreten Voreinstellung/kv-Datenpunkten bleiben davon getrennt.

## Unterstütztes Mappingprofil

Schema:

`vdi-3805-part2-mapped-v1`

Pflichtmetadaten:

- eindeutige Datensatz-ID
- Hersteller
- Datensatzname
- Datenstand/Version
- Standardbezug mit `VDI 3805 Blatt 2`
- Version des verwendeten Mappingprofils/Konverters
- Quellenreferenz
- dokumentierte Nutzungsgrundlage
- mindestens ein Armaturenprodukt

Pflichtdaten je Produkt:

- eindeutige Produkt-ID
- Produktname/Typ
- mindestens ein diskreter Voreinstellung/kv-Datenpunkt

Pflichtdaten je Datenpunkt:

- eindeutige Punkt-ID innerhalb des Produktes
- Voreinstellungsbezeichnung
- positiver, endlicher kv-Wert in m³/h

Optionale Produktdaten:

- Armaturenart
- Artikelnummer
- produktspezifische Quellenreferenz
- Referenz auf den Ursprungsdatensatz/-record

## Fiktives Beispiel

Das folgende Beispiel enthält **keine realen Herstellerdaten** und dient ausschließlich als technische Formatvorlage.

```json
{
  "schema": "vdi-3805-part2-mapped-v1",
  "id": "example-vdi3805-valves",
  "manufacturer": "Beispiel Armaturen",
  "datasetName": "Fiktiver Armaturen-Mapping-Test",
  "datasetVersion": "2026-08-25",
  "standardReference": "VDI 3805 Blatt 2:2021-12",
  "mappingProfileVersion": "authorized-valve-converter-v1",
  "source": {
    "reference": "Fiktive Testquelle",
    "url": null,
    "usageBasis": "userProvided",
    "rightsNote": "Nur Testdaten"
  },
  "products": [
    {
      "id": "valve-1",
      "productName": "Thermostatventil Test",
      "kind": "Thermostatventil",
      "articleNumber": "VALVE-TEST-1",
      "sourceReference": null,
      "originalRecordReference": "record-valve-1",
      "presetPoints": [
        {
          "id": "p1",
          "setting": "1",
          "kvM3H": 0.20,
          "originalRecordReference": null
        },
        {
          "id": "p2",
          "setting": "2",
          "kvM3H": 0.35,
          "originalRecordReference": null
        },
        {
          "id": "p3",
          "setting": "3",
          "kvM3H": 0.50,
          "originalRecordReference": null
        }
      ]
    }
  ]
}
```

## Validierung

Vor dem Import prüft HeizBalance unter anderem:

- korrektes Mapping-Schema
- Standardbezug auf VDI 3805 Blatt 2
- vorhandene Mappingprofil-Version
- Quellen- und Nutzungsangaben
- leere oder doppelte Produkt-IDs
- vorhandenen Produktnamen
- mindestens einen Voreinstellung/kv-Datenpunkt
- doppelte Voreinstellungsbezeichnungen innerhalb eines Produkts
- positive, endliche kv-Werte

Erst ein vollständig validiertes Mapping wird in `valve-product-dataset-v1` konvertiert und lokal gespeichert.

## Verwendung im Projekt

1. Ventilkatalog global importieren.
2. Im Heizflächenkreis ein Thermostat- oder Rücklaufventil erfassen.
3. Den technischen Soll-kv aus Zielvolumenstrom, explizitem Ventil-Δp und Fluiddichte berechnen lassen.
4. Ein dokumentiertes Produkt ausdrücklich aus dem Katalog übernehmen.
5. HeizBalance zeigt unteren/oberen und mathematisch nächstliegenden Datenpunkt sowie den Bereichsstatus.

**Wichtig:** Die Übernahme eines Produktes setzt keine Voreinstellung automatisch. Auch der mathematisch nächstliegende Datenpunkt ist keine Herstellerfreigabe, keine Montageanweisung und keine Verfahren-B-Bestätigung.

## Nachvollziehbarkeit

Katalogherkunft wird beim Übernehmen eines Produktes in die Projektdaten kopiert. Der technische Report-Snapshot speichert neben Hersteller, Produkt, Datenstand und Quellenreferenz optional auch Datensatz-ID, Produkt-ID, Artikelnummer, Quellen-URL, Nutzungsgrundlage und Rechtehinweis. Dadurch bleibt ein Projekt nachvollziehbar, selbst wenn ein lokaler Katalog später ersetzt oder gelöscht wird.

## Nicht Bestandteil dieses Adapters

- keine eingebauten Herstellerkataloge
- keine ungeprüfte Web-/PDF-Datenextraktion
- kein Nachbau geschützter VDI-Satzbeschreibungen im Repository
- keine automatische Ventilvoreinstellung
- keine Montage- oder Herstellerfreigabe

Ein späterer Rohdaten-Konverter muss separat gegen eine rechtmäßig nutzbare Spezifikation bzw. Hersteller-/Lizenzquelle umgesetzt und mit Referenzdateien validiert werden.
