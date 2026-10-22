package de.kamilunavo.shknativeqa;
/** Exact form identities; flow and return never share a viewport-derived editor. */
final class ServiceFieldIdentity {
 static String id(String de,String en){
  if(de.equals(en)&&(de.equals("Vorlauf")||de.equals("Rücklauf")))return "shk-metric-"+de;
  if(de.equals("Bezeichnung")&&en.equals("Name"))return "service-field-name";
  if(de.equals("Prüffragen (1–30)")&&en.equals("Checklist items (1–30)"))return "service-field-checklist";
  if(de.equals("Vorlauf °C")&&en.equals("Supply °C"))return "service-field-flow";
  if(de.equals("Rücklauf °C")&&en.equals("Return °C"))return "service-field-return";
  if(de.equals("Kaltfülldruck bar")&&en.equals("Cold pressure bar"))return "service-field-cold";
  if(de.equals("Warmdruck bar")&&en.equals("Hot pressure bar"))return "service-field-hot";
  if(de.equals("Statische Höhe m")&&en.equals("Static height m"))return "service-field-height";
  if(de.equals("Sicherheitsventil bar")&&en.equals("Safety valve bar"))return "service-field-valve";
  if(de.equals("Eigener Kaltfülldruck min. bar")&&en.equals("Own cold pressure min. bar"))return "service-field-minimum";
  if(de.equals("Eigener Kaltfülldruck max. bar")&&en.equals("Own cold pressure max. bar"))return "service-field-maximum";
  if(de.equals("Tätigkeit / Messquelle / Notiz (max.2000)")&&en.equals("Work / measurement source / note (max.2000)"))return "service-field-note";
  if(de.equals("Nächster Service YYYY-MM-DD (optional)")&&en.equals("Next service YYYY-MM-DD (optional)"))return "service-field-date";
  throw new IllegalArgumentException("Unknown exact service form field");
 }
 static boolean keyboardNumeric(String id){return "service-field-flow".equals(id)||"service-field-return".equals(id)||"service-field-cold".equals(id)||"service-field-hot".equals(id)||"service-field-height".equals(id)||"service-field-valve".equals(id)||"service-field-minimum".equals(id)||"service-field-maximum".equals(id);}
}
