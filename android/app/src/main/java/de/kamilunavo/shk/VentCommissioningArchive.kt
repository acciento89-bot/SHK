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

object VentCommissioningCodec {
    // Android writes -0 as an integer token and reads it as +0; wire zero has one canonical sign.
    private fun wire(value:Double)=if(value==0.0)0.0 else value
    const val maximumBytes=4*1024*1024
    private fun exact(value:JSONObject,vararg fields:String) {require(value.keys().asSequence().toSet()==fields.toSet()){"Unexpected commissioning fields"}}
    private fun rooms(values:List<VentRoom>)=JSONArray().also{array->values.forEach{array.put(JSONObject().put("id",it.id).put("name",it.name))}}
    private fun terminals(values:List<VentTerminal>)=JSONArray().also{array->values.forEach{array.put(JSONObject().put("id",it.id).put("roomID",it.roomID).put("name",it.name).put("side",it.side.name).put("targetM3H",wire(it.targetM3H)).put("measuredM3H",it.measuredM3H?.let(::wire)?:JSONObject.NULL))}}
    private fun rooms(array:JSONArray):List<VentRoom> {
        require(array.length()<=40);return (0 until array.length()).map{val value=array.getJSONObject(it);exact(value,"id","name");VentRoom(value.getString("id"),value.getString("name"))}
    }
    private fun terminals(array:JSONArray):List<VentTerminal> {
        require(array.length()<=80)
        return (0 until array.length()).map {
            val value=array.getJSONObject(it)
            val fields=arrayOf("id","roomID","name","side","targetM3H")
            if(value.has("measuredM3H"))exact(value,*fields,"measuredM3H")else exact(value,*fields)
            val measured=if(!value.has("measuredM3H")||value.isNull("measuredM3H"))null else {
                require(value.get("measuredM3H") is Number){"Invalid measured air flow"}
                value.getDouble("measuredM3H")
            }
            VentTerminal(value.getString("id"),value.getString("roomID"),value.getString("name"),VentSide.valueOf(value.getString("side")),value.getDouble("targetM3H"),measured)
        }
    }
    // Preserve optional omissions only for canonical input verification; new writes use explicit null.
    private fun preserveOmittedMeasurements(source:JSONArray,canonical:JSONArray) {
        for(index in 0 until source.length())if(!source.getJSONObject(index).has("measuredM3H"))canonical.getJSONObject(index).remove("measuredM3H")
    }
    fun encode(book:VentCommissioningBook):String {
        VentCommissioningRules.validate(book)
        val projects=JSONArray();book.projects.forEach{project->
            val visits=JSONArray();project.visits.forEach{visit->visits.put(JSONObject().put("id",visit.id).put("recordedAt",visit.recordedAt).put("note",visit.note).put("rooms",rooms(visit.rooms)).put("terminals",terminals(visit.terminals)))}
            projects.put(JSONObject().put("id",project.id).put("name",project.name).put("rooms",rooms(project.rooms)).put("terminals",terminals(project.terminals)).put("visits",visits))
        }
        return JSONObject().put("schema",book.schema).put("revision",book.revision).put("projects",projects).toString().also{require(it.toByteArray(Charsets.UTF_8).size<=maximumBytes){"Commissioning archive limit"}}
    }
    fun decode(text:String):VentCommissioningBook {
        require(text.isNotEmpty()&&text.toByteArray(Charsets.UTF_8).size<=maximumBytes){"Invalid commissioning archive size"}
        val tokenizer=JSONTokener(text);val root=tokenizer.nextValue() as? JSONObject?:error("Expected commissioning object")
        require(tokenizer.nextClean()=='\u0000'){"Trailing commissioning bytes"};exact(root,"schema","revision","projects")
        val sourceSchema=root.getInt("schema");require(sourceSchema in 1..2){"Unsupported commissioning schema"};val array=root.getJSONArray("projects");require(array.length()<=20)
        val projects=(0 until array.length()).map {index->
            val project=array.getJSONObject(index);exact(project,"id","name","rooms","terminals","visits")
            val rows=project.getJSONArray("visits");require(rows.length()<=40)
            val visits=(0 until rows.length()).map {i->val visit=rows.getJSONObject(i);exact(visit,"id","recordedAt","note","rooms","terminals");VentVisit(visit.getString("id"),visit.getString("recordedAt"),rooms(visit.getJSONArray("rooms")),terminals(visit.getJSONArray("terminals")),visit.getString("note"))}
            VentProject(project.getString("id"),project.getString("name"),rooms(project.getJSONArray("rooms")),terminals(project.getJSONArray("terminals")),visits)
        }
        // Schema1 numeric values, including zero, are kept exactly; migration does not write the file.
        val book=VentCommissioningBook(2,root.getInt("revision"),projects);VentCommissioningRules.validate(book)
        val canonical=JSONObject(encode(book)).put("schema",sourceSchema)
        val canonicalProjects=canonical.getJSONArray("projects")
        for(index in 0 until array.length()) {
            val source=array.getJSONObject(index);val target=canonicalProjects.getJSONObject(index)
            preserveOmittedMeasurements(source.getJSONArray("terminals"),target.getJSONArray("terminals"))
            val sourceVisits=source.getJSONArray("visits");val targetVisits=target.getJSONArray("visits")
            for(visit in 0 until sourceVisits.length())preserveOmittedMeasurements(sourceVisits.getJSONObject(visit).getJSONArray("terminals"),targetVisits.getJSONObject(visit).getJSONArray("terminals"))
        }
        require(canonical.toString()==text){"Noncanonical or damaged commissioning archive"};return book
    }
}

class VentCommissioningFile(file:File,private val writer:((File,ByteArray)->Unit)?=null) {
    private val file=file.absoluteFile
    companion object {private val gate=Any()}
    private fun readBytes():ByteArray {
        FileInputStream(file).use {stream->
            val size=stream.channel.size();require(size in 1..VentCommissioningCodec.maximumBytes.toLong()){"Invalid commissioning archive size"}
            val bytes=ByteArray(size.toInt());var offset=0
            while(offset<bytes.size) {val count=stream.read(bytes,offset,bytes.size-offset);check(count>0);offset+=count}
            check(stream.read()==-1);return bytes
        }
    }
    private fun decode(bytes:ByteArray):VentCommissioningBook {
        val text=StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString()
        return VentCommissioningCodec.decode(text)
    }
    fun load():VentCommissioningBook=synchronized(gate){if(file.exists())decode(readBytes())else VentCommissioningBook()}
    fun save(book:VentCommissioningBook,expectedRevision:Int) {
        val text=VentCommissioningCodec.encode(book);VentCommissioningCodec.decode(text);val bytes=text.toByteArray(Charsets.UTF_8)
        synchronized(gate) {
            val oldBytes=if(file.exists())readBytes()else null;val current=oldBytes?.let(::decode)?:VentCommissioningBook()
            if(oldBytes!=null&&bytes.contentEquals(oldBytes))return@synchronized
            require(expectedRevision>=0&&current.revision==expectedRevision&&book.revision==Math.addExact(expectedRevision,1)){"Commissioning progress changed; reload"}
            if(writer!=null)writer.invoke(file,bytes)else atomicWrite(bytes)
            check(file.exists()&&readBytes().contentEquals(bytes)){"Commissioning save could not be verified"}
        }
    }
    private fun atomicWrite(bytes:ByteArray) {
        val directory=file.parentFile?:error("Missing commissioning directory");check(directory.isDirectory||directory.mkdirs())
        val temporary=File(directory,".vent-commissioning-${UUID.randomUUID()}.tmp")
        try {
            check(temporary.createNewFile());FileOutputStream(temporary).use{it.write(bytes);it.fd.sync()}
            check(temporary.readBytes().contentEquals(bytes));Files.move(temporary.toPath(),file.toPath(),StandardCopyOption.ATOMIC_MOVE,StandardCopyOption.REPLACE_EXISTING)
        }finally{if(temporary.exists())temporary.delete()}
    }
}
