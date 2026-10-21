package de.kamilunavo.shknativeqa;
/** Static locale aliases only; no values or viewport indices define identity. */
final class VentFieldIdentity {
 static String id(String label){
  if("Raumlänge".equals(label)||"Raumbreite".equals(label)||"Raumhöhe".equals(label)||"Luftwechsel".equals(label))return "shk-metric-"+label;
  if("Bezeichnung".equals(label)||"Name".equals(label))return "vent-field-name";
  if("Soll m³/h".equals(label)||"Target m³/h".equals(label))return "vent-field-target";
  if("Ist m³/h".equals(label)||"Measured m³/h".equals(label))return "vent-field-measured";
  if("Tätigkeit / Messquelle / Notiz".equals(label)||"Work / measurement source / note".equals(label))return "vent-field-note";
  throw new IllegalArgumentException("Unknown static ventilation field");
 }
 static boolean keyboardNumeric(String id){return "vent-field-target".equals(id)||"vent-field-measured".equals(id);}
}
