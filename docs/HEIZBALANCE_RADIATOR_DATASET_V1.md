# HeizBalance – Heizkörper-Produktdatensatz v1

Schema-ID: `radiator-product-dataset-v1`

## Zweck
Dieses Format ist die neutrale Import-Schnittstelle für dokumentierte Heizkörperdaten. HeizBalance liefert selbst keine ungeklärten Herstellerlisten aus und übernimmt keine Daten durch Scraping. Ein Datensatz muss eine nachvollziehbare Quelle und Nutzungsgrundlage enthalten.

## Pflichtfelder Datensatz
- `schema`: exakt `radiator-product-dataset-v1`
- `id`: dauerhaft eindeutige Datensatz-ID
- `manufacturer`: Herstellername
- `datasetName`: Bezeichnung des Datenpakets
- `datasetVersion`: Datenstand / Version
- `source.reference`: nachvollziehbare Quellenreferenz
- `source.usageBasis`: eine der erlaubten Nutzungsgrundlagen
- `products`: mindestens ein Produkt

Erlaubte `usageBasis`-Werte:
- `manufacturerAuthorized`
- `licensed`
- `userProvided`
- `otherDocumented`

## Pflichtfelder Produkt
- `id`: innerhalb des Datensatzes eindeutig
- `series`
- `model`
- `nominalPowerDeltaT50W`: dokumentierte Nennleistung bei ΔT50 in W
- `exponent`: dokumentierter Heizkörperexponent

Optional:
- `kind`
- `widthMM`
- `heightMM`
- `depthMM`
- `articleNumber`
- `sourceReference`

Wenn in HeizBalance ein Abmessungsfilter gesetzt wird, wird ein Produkt ohne das entsprechende dokumentierte Maß nicht als passend behandelt.

## Fiktives Beispiel
Der folgende Datensatz dient **nur zur Formatdokumentation**. Hersteller, Serie, Artikel und Werte sind erfunden und dürfen nicht als reale Produktdaten genutzt werden.

```json
{
  "schema": "radiator-product-dataset-v1",
  "id": "example-heating-demo-2026-01",
  "manufacturer": "Example Heating GmbH (FIKTIV)",
  "datasetName": "Demo Panel Radiators",
  "datasetVersion": "2026-01-demo",
  "source": {
    "reference": "Fiktiver Testdatensatz – keine Herstellerquelle",
    "url": null,
    "usageBasis": "userProvided",
    "rightsNote": "Nur für Entwicklung und Schema-Tests"
  },
  "products": [
    {
      "id": "demo-22-600-1000",
      "series": "DemoPanel",
      "model": "Typ 22 600x1000",
      "kind": "panelRadiator",
      "nominalPowerDeltaT50W": 2700,
      "exponent": 1.3,
      "widthMM": 1000,
      "heightMM": 600,
      "depthMM": 105,
      "articleNumber": "DEMO-226010",
      "sourceReference": "Fiktiver Testwert"
    }
  ]
}
```

## Matching-Regeln
`HeizBalanceRadiatorProductMatchingCalculator` bewertet Kandidaten mit der bestehenden Temperatur-Szenario-Engine. Für jeden gültigen Kandidaten werden unter anderem berechnet:
- verfügbare Leistung am Ziel-VL/RL,
- Deckungsgrad,
- Leistungsreserve,
- ausreichende / nicht ausreichende Leistung.

Ausreichende Kandidaten werden nach kleinster positiver Leistungsreserve sortiert. Das ist ausdrücklich **keine automatische Produktempfehlung**, keine Einbaufreigabe und keine Herstellerfreigabe.

## Rechte / Datenpflege
Vor dem Verteilen eines Datensatzes mit der App oder über einen Server muss geklärt sein, dass die konkrete Quelle und Lizenz die Weiterverarbeitung und Distribution der Produktdaten erlaubt. Gekaufte PDF-Unterlagen oder geschützte Herstellerkataloge dürfen nicht allein wegen des Kaufs als App-Datenbank weiterverteilt werden.
