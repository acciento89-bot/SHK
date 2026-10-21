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
 static int ordinal(String id){
  String[] fields={"evaporation","suction","condensation","liquid","suction-pressure","discharge-pressure","air-flow","entering-air","leaving-air"};
  for(int stage=0;stage<2;stage++)for(int field=0;field<fields.length;field++)
   if(("kalte-reading-"+(stage==0?"before":"after")+"-"+fields[field]).equals(id))return stage*fields.length+field;
  throw new IllegalArgumentException("Unknown explicit ordered field identity");
 }
 static int searchDirection(String target,String[] visible){
  int wanted=ordinal(target),first=18,last=-1;
  for(String id:visible){int position=ordinal(id);first=Math.min(first,position);last=Math.max(last,position);}
  if(last<0)return 1;
  return wanted<first?-1:(wanted>last?1:0);
 }
 static String keyboardCommand(String value){
  if(value==null||!value.matches("-?[0-9]+(?:[.,][0-9]+)?"))throw new IllegalArgumentException("Only static numeric keyboard input is permitted");
  return "input text "+value;
 }
}
