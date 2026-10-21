package de.kamilunavo.shknativeqa;
import java.util.List;
/** Pure policy for facts collected from actual AccessibilityWindowInfo, never dumpsys history. */
final class NativeWindowPolicy {
 static final int APPLICATION=1,INPUT_METHOD=2;
 static final class Window {
  final int type,left,top,right,bottom;final String owner;final boolean active,focused;
  Window(int type,String owner,boolean active,boolean focused,int left,int top,int right,int bottom){this.type=type;this.owner=owner;this.active=active;this.focused=focused;this.left=left;this.top=top;this.right=right;this.bottom=bottom;}
  boolean visible(){return right>left&&bottom>top;}
  int[] bounds(){return new int[]{left,top,right,bottom};}
 }
 static boolean imeVisible(List<Window> windows){for(Window w:windows)if(w.type==INPUT_METHOD&&w.visible())return true;return false;}
 static int[] requireApp(List<Window> windows,String expected){
  if(expected==null||expected.isEmpty())throw new AssertionError("No explicit expected owner");
  Window app=null;
  for(Window w:windows){
   if(!w.visible())continue;
   if((w.active||w.focused)&&w.type!=INPUT_METHOD&&!expected.equals(w.owner))throw new AssertionError("Unexpected active window: "+w.owner);
   if(w.type==APPLICATION&&expected.equals(w.owner)&&(w.active||w.focused))app=w;
  }
  if(app==null)throw new AssertionError("Expected application has no focused/active window: "+expected);
  return app.bounds();
 }
 static final class UnexpectedTransitionWindow extends AssertionError {UnexpectedTransitionWindow(String owner){super("Unexpected share-transition window: "+owner);}}
 static boolean transitionReady(List<Window> windows,String from,String target){
  if(from==null||target==null||from.equals(target))throw new AssertionError("Explicit distinct transition owners required");
  boolean previousStillActive=false,targetActive=false;
  for(Window w:windows){
   if(!w.visible()||w.type==INPUT_METHOD||(!w.active&&!w.focused))continue;
   if(!from.equals(w.owner)&&!target.equals(w.owner))throw new UnexpectedTransitionWindow(w.owner);
   if(from.equals(w.owner))previousStillActive=true;
   if(w.type==APPLICATION&&target.equals(w.owner))targetActive=true;
  }
  return targetActive&&!previousStillActive;
 }
 static int[] scrollBounds(int[] app,List<int[]> candidates){
  if(candidates.isEmpty())return null; // A fitting screen legitimately has no scroll container.
  int[] best=null;long area=0;
  for(int[] c:candidates){int[] clipped={Math.max(app[0],c[0]),Math.max(app[1],c[1]),Math.min(app[2],c[2]),Math.min(app[3],c[3])};
   int width=clipped[2]-clipped[0],height=clipped[3]-clipped[1];long size=(long)width*height;
   if(width>=80&&height>=160&&size>area){area=size;best=clipped;}
  }
  if(best==null)throw new AssertionError("No visible scrollable app container with safe bounds");return best;
 }
}
