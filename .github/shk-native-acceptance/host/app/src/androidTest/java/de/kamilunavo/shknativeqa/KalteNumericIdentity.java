package de.kamilunavo.shknativeqa;
/** Explicit section+field identity; never inferred from values or viewport order. */
final class KalteNumericIdentity {
 static String id(String stage,String label){
  if(!"before".equals(stage)&&!"after".equals(stage))throw new IllegalArgumentException("Explicit Before/After context required");
  String key;
  if("Verdampfung °C".equals(label)||"Evaporation \u00b0C".equals(label))key="evaporation";
  else if("Sauggas °C".equals(label)||"Suction gas \u00b0C".equals(label))key="suction";
  else if("Kondensation °C".equals(label)||"Condensation \u00b0C".equals(label))key="condensation";
  else if("Flüssigkeit °C".equals(label)||"Liquid \u00b0C".equals(label))key="liquid";
  else if("Saugdruck bar(g)".equals(label)||"Suction pressure bar(g)".equals(label))key="suction-pressure";
  else if("Hochdruck bar(g)".equals(label)||"Discharge pressure bar(g)".equals(label))key="discharge-pressure";
  else if("Luftvolumenstrom m³/h".equals(label)||"Air volume m\u00b3/h".equals(label))key="air-flow";
  else if("Luft Eintritt °C".equals(label)||"Entering air \u00b0C".equals(label))key="entering-air";
  else if("Luft Austritt °C".equals(label)||"Leaving air \u00b0C".equals(label))key="leaving-air";
  else throw new IllegalArgumentException("Unknown static numeric field label");
  return "kalte-reading-"+stage+"-"+key;
 }
 static String legacyId(String label){
  if(!"Verdampfung".equals(label)&&!"Sauggas".equals(label))throw new IllegalArgumentException("Unknown legacy Kälte field");
  return "shk-metric-"+label;
 }
 static String legacyValue(String value){
  if(value==null)throw new IllegalArgumentException("Missing numeric value");
  try{return new java.math.BigDecimal(value.replace(',','.')).stripTrailingZeros().toPlainString();}
  catch(NumberFormatException transientEditorText){return value;}
 }
}
