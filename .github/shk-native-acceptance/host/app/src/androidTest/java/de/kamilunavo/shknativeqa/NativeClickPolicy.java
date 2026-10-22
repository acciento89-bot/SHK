package de.kamilunavo.shknativeqa;
/** Passive text is not a competing action; two actual actions remain an error. */
final class NativeClickPolicy {
 static int uniqueAction(boolean[] actionable){int selected=-1;
  for(int i=0;i<actionable.length;i++)if(actionable[i]){if(selected!=-1)throw new IllegalArgumentException("Ambiguous native clickable target");selected=i;}
  if(selected<0)throw new IllegalArgumentException("No native clickable target");return selected;
 }
}
