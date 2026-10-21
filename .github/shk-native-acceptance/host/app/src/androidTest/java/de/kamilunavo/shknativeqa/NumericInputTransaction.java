package de.kamilunavo.shknativeqa;
/** Numeric QA only: snapshots carry no native node. Actions are never retried. */
final class NumericInputTransaction {
 static final class Failure extends AssertionError { Failure(String message){super(message);} }
 static final class StaleRead extends RuntimeException {}
 static final class Snapshot {
  final int count;final String owner,value;final boolean enabled,positive,focused;
  Snapshot(int count,String owner,boolean enabled,boolean positive,boolean focused,String value){this.count=count;this.owner=owner;this.enabled=enabled;this.positive=positive;this.focused=focused;this.value=value;}
 }
 interface Port {
  Snapshot observe(String label);void focus(String label);void write(String label,String value);
  long now();void pause(long milliseconds);
 }
 private final Port port;private final String owner;private final long budget;
 NumericInputTransaction(Port port,String owner,long budget){if(port==null||owner==null||owner.isEmpty()||budget<=0)throw new Failure("Explicit numeric owner/time budget required");this.port=port;this.owner=owner;this.budget=budget;}
 private void await(String label,boolean focus,String value){
  long deadline=port.now()+budget;
  do{
   try{
    Snapshot s=port.observe(label);
    if(s.count>1)throw new Failure("Ambiguous exact numeric editor: "+label);
    if(s.count==1){
     if(!owner.equals(s.owner))throw new Failure("Wrong numeric editor owner: "+label);
     if(s.enabled&&s.positive&&(!focus||s.focused)&&(value==null||value.equals(s.value)))return;
    }
   }catch(StaleRead transientRead){/* Read-only query is retried, never a focus/write. */}
   if(port.now()>=deadline)break;
   port.pause(Math.min(100,deadline-port.now()));
  }while(port.now()<=deadline);
  throw new Failure("Numeric editor condition not established: "+label);
 }
 void enter(String label,String value){
  await(label,false,null);
  port.focus(label); // one freshly resolved actual action; any failure propagates.
  await(label,true,null);
  port.write(label,value); // one freshly resolved actual write; uncertain writes never repeat.
  await(label,true,value);
 }
 void verify(String label,String value){await(label,false,value);}
}
