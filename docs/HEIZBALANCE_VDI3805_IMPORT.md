# HeizBalance – VDI 3805 Heizkörper-Import

## Zweck

HeizBalance unterstützt eine Adapter-Schicht für Heizkörper-/Konvektordaten mit Bezug auf **VDI 3805 Blatt 6**.

Der Adapter ist bewusst **kein im Repository nachgebauter Rohparser der Richtlinie**. Er verarbeitet nur eine normalisierte Mappingdatei, die aus einer rechtmäßig nutzbaren Hersteller-/Lizenzquelle oder einem entsprechend autorisierten Konverter erzeugt wurde.

Intern wird das Mapping anschließend in das stabile HeizBalance-Schema `radiator-product-dataset-v1` überführt. Dadurch bleiben Matching, Sanierungsziel, Ersatzwahl, Bericht und Archiv unabhängig von der ursprünglichen Datenquelle.

## Unterstütztes Mappingprofil

Schema:

`vdi-3805-part6-mapped-v1`

Pflichtmetadaten:

- eindeutige Datensatz-ID
- Hersteller
- Datensatzname
- Datenstand/Version
- Standardbezug mit `VDI 3805 Blatt 6`
- Version des verwendeten Mappingprofils/Konverters
- Quellenreferenz
- dokumentierte Nutzungsgrundlage
- mindestens ein Produkt

Pflichtdaten je Produkt:

- eindeutige Produkt-ID
- Serie und/oder Modell
- Nennleistung bei ΔT50 in W
- Heizkörperexponent `n`

Optionale Produktdaten:

- Produkttyp
- Breite, Höhe, Tiefe in mm
- Artikelnummer
- produktspezifische Quellenreferenz
- Referenz auf den Ursprungsdatensatz/-record

## Fiktives Beispiel

Das folgende Beispiel enthält **keine realen Herstellerdaten** und dient ausschließlich als technische Formatvorlage.

```json
{
  "schema": "vdi-3805-part6-mapped-v1",
  "id": "example-vdi3805-radiators",
  "manufacturer": "Beispiel Hersteller",
  "datasetName": "Fiktiver Mapping-Test",
  "datasetVersion": "2026-08-25",
  "standardReference": "VDI 3805 Blatt 6:2022-01",
  "mappingProfileVersion": "authorized-converter-v1",
  "source": {
    "reference": "Fiktive Testquelle",
    "url": null,
    "usageBasis": "userProvided",
    "rightsNote": "Nur Testdaten"
  },
  "products": [
    {
      "id": "product-1",
      "series": "Testserie",
      "model": "22-600-1200",
      "kind": "Plattenheizkörper",
      "nominalPowerDeltaT50W": 2500,
      "exponent": 1.3,
      "widthMM": 1200,
      "heightMM": 600,
      "depthMM": 102,
      "articleNumber": "TEST-4711",
      "sourceReference": null,
      "originalRecordReference": "record-4711"
    }
  ]
}
```

## Validierung

Vor dem Import prüft HeizBalance unter anderem:

- korrektes Mapping-Schema
- Standardbezug auf VDI 3805 Blatt 6
- vorhandene Mappingprofil-Version
- Quellen- und Rechteangaben
- doppelte oder leere Produkt-IDs
- positive, endliche Nennleistung und Exponent
- positive, endliche Abmessungen, sofern angegeben

Erst ein vollständig validiertes Mapping wird in `radiator-product-dataset-v1` konvertiert und lokal gespeichert.

## Nachvollziehbarkeit

Bei der Konvertierung schreibt HeizBalance Standardbezug und Mappingprofil-Version in den dokumentierten Quellen-/Rechtehinweis des internen Datensatzes. Wird später ein Ersatzheizkörper ausdrücklich ausgewählt, werden Hersteller, Datensatzversion, Quelle, Produktwerte, Sanierungsziel und berechnete Leistung als eigener versionierter Auswahl-Snapshot im Projekt gespeichert.

## Nicht Bestandteil dieses Adapters

- keine eingebauten Herstellerkataloge
- keine ungeprüfte Web-/PDF-Datenextraktion
- kein Nachbau geschützter VDI-Satzbeschreibungen im Repository
- keine automatische Produktauswahl
- keine Montage- oder Herstellerfreigabe

Ein späterer Rohdaten-Konverter muss separat gegen eine rechtmäßig nutzbare Spezifikation bzw. Hersteller-/Lizenzquelle umgesetzt und mit Referenzdateien validiert werden.
