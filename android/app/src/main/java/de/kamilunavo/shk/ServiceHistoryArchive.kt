package de.kamilunavo.shk

import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.util.UUID
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener

object ServiceHistoryCodec {
    // Android writes -0 as an integer token and reads it as +0; wire zero has one canonical sign.
    private fun wire(value:Double)=if(value==0.0)0.0 else value
    const val maximumBytes=4*1024*1024
    private fun exact(value:JSONObject,vararg fields:String){require(value.keys().asSequence().toSet()==fields.toSet()){"Unexpected history fields"}}
    private fun template(value:ServiceTemplate):JSONObject {
        val items=JSONArray();value.items.forEach{items.put(JSONObject().put("id",it.id).put("label",it.label))}
        return JSONObject().put("id",value.id).put("name",value.name).put("version",value.version).put("items",items)
    }
    private fun template(value:JSONObject):ServiceTemplate {
        exact(value,"id","name","version","items");val items=value.getJSONArray("items");require(items.length()<=30)
        return ServiceTemplate(value.getString("id"),value.getString("name"),value.getInt("version"),(0 until items.length()).map{val item=items.getJSONObject(it);exact(item,"id","label");ServiceChecklistItem(item.getString("id"),item.getString("label"))})
    }
    fun encode(book:ServiceHistoryBook):String {
        ServiceHistoryRules.validate(book);val installations=JSONArray();val templates=JSONArray();val visits=JSONArray()
        book.installations.forEach{installations.put(JSONObject().put("id",it.id).put("name",it.name))};book.templates.forEach{templates.put(template(it))}
        book.visits.forEach {v->val m=v.measurements
            val measurements=JSONObject().put("flowC",wire(m.flowC)).put("returnC",wire(m.returnC)).put("coldBar",wire(m.coldBar)).put("hotBar",wire(m.hotBar)).put("staticHeightM",wire(m.staticHeightM)).put("safetyValveBar",wire(m.safetyValveBar))
            visits.put(JSONObject().put("id",v.id).put("installationID",v.installationID).put("recordedAt",v.recordedAt).put("measurements",measurements).put("limits",JSONObject().put("minColdBar",wire(v.limits.minColdBar)).put("maxColdBar",wire(v.limits.maxColdBar))).put("template",template(v.template)).put("checked",JSONArray(v.checked)).put("notes",v.notes).put("nextServiceDate",v.nextServiceDate?:JSONObject.NULL))
        }
        return JSONObject().put("schema",book.schema).put("revision",book.revision).put("installations",installations).put("templates",templates).put("visits",visits).toString().also{require(it.toByteArray(Charsets.UTF_8).size<=maximumBytes)}
    }
    fun decode(text:String):ServiceHistoryBook {
        require(text.isNotEmpty()&&text.toByteArray(Charsets.UTF_8).size<=maximumBytes);val tokenizer=JSONTokener(text);val root=tokenizer.nextValue() as? JSONObject?:error("Expected history object");require(tokenizer.nextClean()=='\u0000'){"Trailing history bytes"}
        exact(root,"schema","revision","installations","templates","visits");require(root.getInt("schema")==1)
        val ia=root.getJSONArray("installations");val ta=root.getJSONArray("templates");val va=root.getJSONArray("visits");require(ia.length()<=40&&ta.length()<=30&&va.length()<=400)
        val installations=(0 until ia.length()).map{val v=ia.getJSONObject(it);exact(v,"id","name");ServiceInstallation(v.getString("id"),v.getString("name"))}
        val templates=(0 until ta.length()).map{template(ta.getJSONObject(it))}
        val visits=(0 until va.length()).map {i->val v=va.getJSONObject(i);exact(v,"id","installationID","recordedAt","measurements","limits","template","checked","notes","nextServiceDate")
            val m=v.getJSONObject("measurements");exact(m,"flowC","returnC","coldBar","hotBar","staticHeightM","safetyValveBar");val l=v.getJSONObject("limits");exact(l,"minColdBar","maxColdBar");val checked=v.getJSONArray("checked");require(checked.length()<=30)
            ServiceVisit(v.getString("id"),v.getString("installationID"),v.getString("recordedAt"),ServiceMeasurements(m.getDouble("flowC"),m.getDouble("returnC"),m.getDouble("coldBar"),m.getDouble("hotBar"),m.getDouble("staticHeightM"),m.getDouble("safetyValveBar")),ServiceLimits(l.getDouble("minColdBar"),l.getDouble("maxColdBar")),template(v.getJSONObject("template")),(0 until checked.length()).map{checked.getString(it)},v.getString("notes"),if(v.isNull("nextServiceDate"))null else v.getString("nextServiceDate"))
        }
        return ServiceHistoryBook(root.getInt("schema"),root.getInt("revision"),installations,templates,visits).also{ServiceHistoryRules.validate(it);require(encode(it)==text){"Noncanonical history archive"}}
    }
}
class ServiceHistoryFile(file:File,private val writer:((File,ByteArray)->Unit)?=null) {
    private val file=file.absoluteFile
    companion object {private val gate=Any()}
    private fun readBytes():ByteArray {FileInputStream(file).use{stream->val size=stream.channel.size();require(size in 1..ServiceHistoryCodec.maximumBytes.toLong());val bytes=ByteArray(size.toInt());var offset=0;while(offset<bytes.size){val count=stream.read(bytes,offset,bytes.size-offset);check(count>0);offset+=count};check(stream.read()==-1);return bytes}}
    private fun decode(bytes:ByteArray):ServiceHistoryBook=ServiceHistoryCodec.decode(StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString())
    fun load():ServiceHistoryBook=synchronized(gate){if(file.exists())decode(readBytes())else ServiceHistoryBook()}
    fun save(book:ServiceHistoryBook,expectedRevision:Int) {
        val text=ServiceHistoryCodec.encode(book);ServiceHistoryCodec.decode(text);val bytes=text.toByteArray(Charsets.UTF_8)
        synchronized(gate){val old=if(file.exists())readBytes()else null;val current=old?.let(::decode)?:ServiceHistoryBook();if(old!=null&&old.contentEquals(bytes))return@synchronized
            require(expectedRevision>=0&&current.revision==expectedRevision&&book.revision==Math.addExact(expectedRevision,1)){"Service history changed; reload"}
            if(writer!=null)writer.invoke(file,bytes)else atomicWrite(bytes);check(file.exists()&&readBytes().contentEquals(bytes)){"Service save could not be verified"}}
    }
    private fun atomicWrite(bytes:ByteArray){val directory=file.parentFile?:error("Missing service directory");check(directory.isDirectory||directory.mkdirs());val temporary=File(directory,".service-history-${UUID.randomUUID()}.tmp")
        try{check(temporary.createNewFile());FileOutputStream(temporary).use{it.write(bytes);it.fd.sync()};check(temporary.readBytes().contentEquals(bytes));Files.move(temporary.toPath(),file.toPath(),StandardCopyOption.ATOMIC_MOVE,StandardCopyOption.REPLACE_EXISTING)}finally{if(temporary.exists())temporary.delete()}}
}
