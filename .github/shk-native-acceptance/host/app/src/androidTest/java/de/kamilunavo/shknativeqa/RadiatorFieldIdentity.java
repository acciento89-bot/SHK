package de.kamilunavo.shknativeqa;
/** Exact form slots are mutually exclusive; localized labels never select a neighboring editor. */
final class RadiatorFieldIdentity {
 static String id(String de,String en){
  if(de.equals(en)&&(de.equals("Hersteller-Nennleistung ΔT50")||de.equals("Vorlauf")||de.equals("Rücklauf")||de.equals("Raum")||de.equals("Hersteller-Exponent n")))return "shk-metric-"+de;
  if(de.equals("Bezeichnung")&&en.equals("Name"))return "radiator-field-name";
  if((de.equals("Raum-Heizlast W")&&en.equals("Room heat requirement W"))||(de.equals("Hersteller-Nennleistung ΔT50 W je Stück")&&en.equals("Manufacturer nominal ΔT50 W per unit"))||(de.equals("Vorlauf °C")&&en.equals("Supply °C")))return "radiator-field-a";
  if((de.equals("Hersteller-Exponent n")&&en.equals("Manufacturer exponent n"))||(de.equals("Rücklauf °C")&&en.equals("Return °C")))return "radiator-field-b";
  if((de.equals("Anzahl (ganze Zahl)")&&en.equals("Count (whole number)"))||(de.equals("Raum °C")&&en.equals("Room °C")))return "radiator-field-c";
  throw new IllegalArgumentException("Unknown exact radiator form field");
 }
 static boolean keyboardNumeric(String id){return "radiator-field-a".equals(id)||"radiator-field-b".equals(id)||"radiator-field-c".equals(id);}
}
