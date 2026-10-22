package de.kamilunavo.shknativeqa;
/** Exact source label pairs map to mutually exclusive pipe form slots, never viewport positions. */
final class PipeFieldIdentity {
 static String id(String de,String en){
  if(de.equals(en)&&(de.equals("Volumenstrom")||de.equals("Freier Innendurchmesser")||de.equals("Rohrlänge")))return "shk-metric-"+de;
  if(de.equals("Bezeichnung")&&en.equals("Name"))return "pipe-field-name";
  if((de.equals("Vorgegebener Volumenstrom l/h")&&en.equals("Declared flow l/h"))||(de.equals("Reale Länge m")&&en.equals("Actual length m")))return "pipe-field-a";
  if(de.equals("Freier Innendurchmesser mm")&&en.equals("Free inside diameter mm"))return "pipe-field-b";
  if(de.equals("Rauheit mm")&&en.equals("Roughness mm"))return "pipe-field-c";
  if(de.equals("Summe örtlicher Widerstände ζ")&&en.equals("Local resistance sum ζ"))return "pipe-field-d";
  throw new IllegalArgumentException("Unknown exact pipe form field");
 }
 static boolean keyboardNumeric(String id){return "pipe-field-a".equals(id)||"pipe-field-b".equals(id)||"pipe-field-c".equals(id)||"pipe-field-d".equals(id);}
}
