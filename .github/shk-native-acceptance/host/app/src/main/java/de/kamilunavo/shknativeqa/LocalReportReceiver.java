package de.kamilunavo.shknativeqa;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.ScrollView;
import android.widget.TextView;
import org.json.JSONObject;
import java.io.*;
import java.nio.ByteBuffer;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Set;

/** QA-only local receiver, no networking, no customer destinations or broad storage permission. */
public final class LocalReportReceiver extends Activity {
 private static final Set<String> AUTHORITIES=Set.of("de.kamilunav.kaltecalc.reports","de.kamilunavo.luftungscalc.reports","de.kamilunavo.heizkorpercalc.reports","de.kamilunavo.rohrcalc.reports","de.kamilunavo.servicecheck.reports");
 @Override public void onCreate(Bundle state){super.onCreate(state);File directory=new File(getFilesDir(),"shk-native-qa");directory.mkdirs();try{
  Intent intent=getIntent();Uri uri=intent.getParcelableExtra(Intent.EXTRA_STREAM,Uri.class);
  if(!Intent.ACTION_SEND.equals(intent.getAction())||!"text/plain".equals(intent.getType())||uri==null||!"content".equals(uri.getScheme())||!AUTHORITIES.contains(uri.getAuthority()))throw new IOException("Unexpected QA input");
  if((intent.getFlags()&Intent.FLAG_GRANT_READ_URI_PERMISSION)==0)throw new IOException("Missing temporary read grant");
  if(intent.hasExtra(Intent.EXTRA_TEXT))throw new IOException("New workflow must use full attachment, not duplicate Binder text");
  if(intent.getClipData()==null||intent.getClipData().getItemCount()!=1||!uri.equals(intent.getClipData().getItemAt(0).getUri()))throw new IOException("Missing scoped ClipData");
  ByteArrayOutputStream all=new ByteArrayOutputStream();try(InputStream input=getContentResolver().openInputStream(uri)){if(input==null)throw new IOException("No stream");byte[] buffer=new byte[8192];int count;while((count=input.read(buffer))!=-1){if(all.size()+count>16*1024*1024)throw new IOException("Report too large");all.write(buffer,0,count);}}
  byte[] bytes=all.toByteArray();String text=StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString();
  StringBuilder hash=new StringBuilder();for(byte value:MessageDigest.getInstance("SHA-256").digest(bytes))hash.append(String.format(java.util.Locale.ROOT,"%02x",value&255));
  try(FileOutputStream out=new FileOutputStream(new File(directory,"last-report.txt"))){out.write(bytes);out.getFD().sync();}
  JSONObject facts=new JSONObject().put("uri",uri.toString()).put("authority",uri.getAuthority()).put("filename",uri.getLastPathSegment()).put("byteCount",bytes.length).put("sha256",hash.toString()).put("mime",intent.getType()).put("temporaryReadGrant",true).put("clipDataMatches",true);
  try(FileOutputStream out=new FileOutputStream(new File(directory,"last-report.json"))){out.write(facts.toString().getBytes(StandardCharsets.UTF_8));out.getFD().sync();}
  TextView body=new TextView(this);body.setText("SHK local report captured\n"+hash+"\n\n"+text);body.setTextSize(14);body.setPadding(24,40,24,40);ScrollView scroll=new ScrollView(this);scroll.addView(body);setContentView(scroll);
 }catch(Exception error){try(FileOutputStream out=new FileOutputStream(new File(directory,"receiver-error.txt"))){out.write(error.toString().getBytes(StandardCharsets.UTF_8));}catch(Exception ignored){}TextView body=new TextView(this);body.setText("SHK QA receiver failed: "+error);setContentView(body);}}
}
