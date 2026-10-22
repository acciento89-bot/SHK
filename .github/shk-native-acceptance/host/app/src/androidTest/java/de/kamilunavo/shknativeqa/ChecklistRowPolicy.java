package de.kamilunavo.shknativeqa;
/** Resolve a checkbox in the same visual row when Compose exposes sibling semantics. */
final class ChecklistRowPolicy {
 static int uniqueLeftOfLabel(int[] label,int[][] boxes){
  if(label.length!=4||label[2]<=label[0]||label[3]<=label[1])throw new IllegalArgumentException("Invalid checklist label bounds");
  long y=((long)label[1]+label[3])/2;int selected=-1;
  for(int i=0;i<boxes.length;i++){int[] b=boxes[i];
   if(b.length!=4||b[2]<=b[0]||b[3]<=b[1])continue;
   long x=((long)b[0]+b[2])/2;
   if(x<label[0]&&b[1]<=y&&b[3]>=y){if(selected!=-1)throw new IllegalArgumentException("Ambiguous checklist row");selected=i;}
  }
  if(selected<0)throw new IllegalArgumentException("No checkbox in checklist row");return selected;
 }
}
