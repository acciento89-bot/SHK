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

object RadiatorRetrofitCodec {
    // Android writes -0 as an integer token and reads it as +0; wire zero has one canonical sign.
    private fun wire(value:Double)=if(value==0.0)0.0 else value
    const val maximumBytes=4*1024*1024
    private fun exact(value:JSONObject,vararg keys:String){require(value.keys().asSequence().toSet()==keys.toSet()){"Unexpected retrofit fields"}}
    private fun emitters(values:List<RadiatorEmitter>)=JSONArray().also {array->values.forEach{array.put(JSONObject().put("id",it.id).put("name",it.name).put("nominalW",wire(it.nominalW)).put("exponent",wire(it.exponent)).put("count",it.count))}}
    private fun emitters(array:JSONArray):List<RadiatorEmitter> {require(array.length()<=20);return (0 until array.length()).map{val value=array.getJSONObject(it);exact(value,"id","name","nominalW","exponent","count");RadiatorEmitter(value.getString("id"),value.getString("name"),value.getDouble("nominalW"),value.getDouble("exponent"),value.getInt("count"))}}
    fun encode(book:RadiatorRetrofitBook):String {
        RadiatorRetrofitRules.validate(book);val projects=JSONArray()
        book.projects.forEach {project->
            val rooms=JSONArray();project.rooms.forEach {rooms.put(JSONObject().put("id",it.id).put("name",it.name).put("heatLoadW",wire(it.heatLoadW)).put("existing",emitters(it.existing)).put("proposed",emitters(it.proposed)))}
            val scenarios=JSONArray();project.scenarios.forEach {scenarios.put(JSONObject().put("id",it.id).put("name",it.name).put("supplyC",wire(it.supplyC)).put("returnC",wire(it.returnC)).put("roomC",wire(it.roomC)))}
            projects.put(JSONObject().put("id",project.id).put("name",project.name).put("rooms",rooms).put("scenarios",scenarios))
        }
        return JSONObject().put("schema",book.schema).put("revision",book.revision).put("projects",projects).toString().also{require(it.toByteArray(Charsets.UTF_8).size<=maximumBytes){"Retrofit archive limit"}}
    }
    fun decode(text:String):RadiatorRetrofitBook {
        require(text.isNotEmpty()&&text.toByteArray(Charsets.UTF_8).size<=maximumBytes){"Invalid retrofit size"};val tokenizer=JSONTokener(text)
        val root=tokenizer.nextValue() as? JSONObject?:error("Expected retrofit object");require(tokenizer.nextClean()=='\u0000'){"Trailing retrofit bytes"};exact(root,"schema","revision","projects")
        require(root.getInt("schema")==1){"Unsupported retrofit schema"};val array=root.getJSONArray("projects");require(array.length()<=20)
        val projects=(0 until array.length()).map {index->
            val project=array.getJSONObject(index);exact(project,"id","name","rooms","scenarios")
            val roomRows=project.getJSONArray("rooms");require(roomRows.length()<=40)
            val rooms=(0 until roomRows.length()).map {i->val room=roomRows.getJSONObject(i);exact(room,"id","name","heatLoadW","existing","proposed");RadiatorRoom(room.getString("id"),room.getString("name"),room.getDouble("heatLoadW"),emitters(room.getJSONArray("existing")),emitters(room.getJSONArray("proposed")))}
            val scenarioRows=project.getJSONArray("scenarios");require(scenarioRows.length()<=6)
            val scenarios=(0 until scenarioRows.length()).map {i->val value=scenarioRows.getJSONObject(i);exact(value,"id","name","supplyC","returnC","roomC");RadiatorScenario(value.getString("id"),value.getString("name"),value.getDouble("supplyC"),value.getDouble("returnC"),value.getDouble("roomC"))}
            RadiatorRetrofitProject(project.getString("id"),project.getString("name"),rooms,scenarios)
        }
        val book=RadiatorRetrofitBook(root.getInt("schema"),root.getInt("revision"),projects);RadiatorRetrofitRules.validate(book);require(encode(book)==text){"Noncanonical retrofit archive"};return book
    }
}
class RadiatorRetrofitFile(file:File,private val writer:((File,ByteArray)->Unit)?=null) {
    private val file=file.absoluteFile
    companion object {private val gate=Any()}
    private fun readBytes():ByteArray {
        FileInputStream(file).use {stream->val size=stream.channel.size();require(size in 1..RadiatorRetrofitCodec.maximumBytes.toLong());val bytes=ByteArray(size.toInt());var offset=0
            while(offset<bytes.size){val count=stream.read(bytes,offset,bytes.size-offset);check(count>0);offset+=count};check(stream.read()==-1);return bytes}
    }
    private fun decode(bytes:ByteArray):RadiatorRetrofitBook=RadiatorRetrofitCodec.decode(StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString())
    fun load():RadiatorRetrofitBook=synchronized(gate){if(file.exists())decode(readBytes())else RadiatorRetrofitBook()}
    fun save(book:RadiatorRetrofitBook,expectedRevision:Int) {
        val text=RadiatorRetrofitCodec.encode(book);RadiatorRetrofitCodec.decode(text);val bytes=text.toByteArray(Charsets.UTF_8)
        synchronized(gate) {
            val old=if(file.exists())readBytes()else null;val current=old?.let(::decode)?:RadiatorRetrofitBook()
            if(old!=null&&bytes.contentEquals(old))return@synchronized
            require(expectedRevision>=0&&current.revision==expectedRevision&&book.revision==Math.addExact(expectedRevision,1)){"Retrofit progress changed; reload"}
            if(writer!=null)writer.invoke(file,bytes)else atomicWrite(bytes)
            check(file.exists()&&readBytes().contentEquals(bytes)){"Retrofit save could not be verified"}
        }
    }
    private fun atomicWrite(bytes:ByteArray) {
        val directory=file.parentFile?:error("Missing retrofit directory");check(directory.isDirectory||directory.mkdirs());val temporary=File(directory,".radiator-retrofit-${UUID.randomUUID()}.tmp")
        try {check(temporary.createNewFile());FileOutputStream(temporary).use{it.write(bytes);it.fd.sync()};check(temporary.readBytes().contentEquals(bytes));Files.move(temporary.toPath(),file.toPath(),StandardCopyOption.ATOMIC_MOVE,StandardCopyOption.REPLACE_EXISTING)}
        finally {if(temporary.exists())temporary.delete()}
    }
}
