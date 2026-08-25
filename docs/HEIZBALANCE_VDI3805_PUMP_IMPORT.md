# HeizBalance – VDI 3805 Pumpen-Mapping

## Zweck

HeizBalance unterstützt einen versionierten Importadapter für **normalisierte, dokumentierte Pumpendaten mit Bezug auf VDI 3805 Blatt 4**.

Das Schema `vdi-3805-part4-mapped-v1` ist **kein Rohparser der Richtlinie**. Es bildet keine geschützte Satzbeschreibung der VDI 3805 nach und ersetzt keine Lizenz für Richtlinien- oder Herstellerdaten.

Zulässig vorgesehen sind nur Daten, die rechtmäßig erzeugt bzw. bereitgestellt wurden, zum Beispiel:

- vom Hersteller freigegebene Daten,
- lizenzierte Daten,
- vom Benutzer rechtmäßig bereitgestellte Daten,
- andere dokumentierte und rechtmäßig nutzbare Quellen.

Nach erfolgreicher Validierung wird das Mapping in das stabile interne Schema `pump-product-dataset-v1` konvertiert.

## Pflichtmetadaten

Ein Mapping enthält mindestens:

- `schema`: `vdi-3805-part4-mapped-v1`
- eindeutige Datensatz-ID
- Hersteller
- Datensatzname
- Datenstand / Version
- `standardReference` mit Bezug auf `VDI 3805 Blatt 4`
- `mappingProfileVersion`
- Quellenreferenz
- dokumentierte Nutzungsgrundlage
- mindestens ein Pumpenprodukt

## Pumpenprodukte

Ein Produkt enthält mindestens:

- eindeutige Produkt-ID
- Produktname
- mindestens eine Kennlinie

Optional können Serie, Artikelnummer und produktspezifische Quellenreferenz dokumentiert werden.

## Kennlinien

Jede Kennlinie enthält mindestens:

- eindeutige Kennlinien-ID
- Bezeichnung
- mindestens zwei Kennlinienpunkte

Optional können Regel-/Betriebsart, Drehzahl und kennlinienspezifische Quellenreferenz dokumentiert werden.

Ein Kennlinienpunkt enthält:

- eindeutige Punkt-ID
- Volumenstrom in `m³/h`
- Förderhöhe in `m`
- optional elektrische Aufnahmeleistung in `W`

## Betriebspunktvergleich

Der Core-Baustein `HeizBalancePumpCurveOperatingPointCalculator` wertet eine dokumentierte Kennlinie ausschließlich **innerhalb ihres vorhandenen Volumenstrombereichs** aus.

Regeln:

1. Liegt der Projektvolumenstrom exakt auf einem dokumentierten Punkt, wird dieser Punkt unverändert verwendet.
2. Liegt er zwischen zwei dokumentierten Punkten, wird die Förderhöhe linear zwischen genau diesen beiden Punkten interpoliert.
3. Die elektrische Aufnahmeleistung wird nur interpoliert, wenn beide begrenzenden Punkte einen dokumentierten Wert enthalten.
4. Unterhalb oder oberhalb des dokumentierten Volumenstrombereichs wird **nicht extrapoliert**.
5. Das Ergebnis zeigt verfügbare Förderhöhe, erforderliche Förderhöhe, Förderhöhenreserve und technisch ausreichend / nicht ausreichend.
6. Daraus folgt **keine automatische Pumpenauswahl, Effizienzfreigabe oder Herstellerfreigabe**.

## Fiktives Beispiel

Das folgende Beispiel enthält ausschließlich erfundene Produktdaten und dient nur zur Beschreibung des HeizBalance-Mappings:

```json
{
  "schema": "vdi-3805-part4-mapped-v1",
  "id": "fictional-pump-catalog-2026",
  "manufacturer": "Beispiel Pumpen GmbH",
  "datasetName": "Fiktiver Heizungs-Pumpenkatalog",
  "datasetVersion": "2026-08",
  "standardReference": "VDI 3805 Blatt 4",
  "mappingProfileVersion": "example-mapper-1",
  "source": {
    "reference": "Fiktive Beispieldaten – keine Herstellerdaten",
    "url": null,
    "usageBasis": "userProvided",
    "rightsNote": "Nur Demonstrationsdaten."
  },
  "products": [
    {
      "id": "pump-25-60-example",
      "productName": "Example 25-60",
      "series": "DemoLine",
      "articleNumber": "DEMO-2560",
      "sourceReference": "Fiktive Produktkarte",
      "originalRecordReference": "demo-record-1",
      "curves": [
        {
          "id": "curve-max",
          "label": "Maximale Kennlinie",
          "controlMode": "Demo",
          "speedRPM": 3000,
          "sourceReference": "Fiktive Kennlinie",
          "originalRecordReference": "demo-curve-1",
          "points": [
            {
              "id": "p0",
              "volumeFlowM3H": 0.0,
              "headM": 6.0,
              "electricalInputPowerW": 22,
              "originalRecordReference": "demo-point-0"
            },
            {
              "id": "p1",
              "volumeFlowM3H": 1.0,
              "headM": 5.0,
              "electricalInputPowerW": 30,
              "originalRecordReference": "demo-point-1"
            },
            {
              "id": "p2",
              "volumeFlowM3H": 2.0,
              "headM": 3.0,
              "electricalInputPowerW": 42,
              "originalRecordReference": "demo-point-2"
            }
          ]
        }
      ]
    }
  ]
}
```

## Bewusst nicht freigegeben

- Nachbau der originalen VDI-3805-Rohdatensatzstruktur ohne rechtlich und technisch verifizierte Grundlage
- ungeprüftes Scraping von Herstellerdaten
- Extrapolation von Pumpenkennlinien
- automatische Wahl eines Pumpenprodukts
- automatische Wahl einer Regelart oder Pumpeneinstellung
- vollständige energetische Pumpenbewertung
- Herstellerfreigabe oder Verfahren-B-/GEG-/BEG-Konformitätsaussage
