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

object PipeCircuitCodec {
    // Android writes -0 as an integer token and reads it as +0; wire zero has one canonical sign.
    private fun wire(value:Double)=if(value==0.0)0.0 else value
    const val maximumBytes=4*1024*1024
    private fun exact(value:JSONObject,vararg fields:String){require(value.keys().asSequence().toSet()==fields.toSet()){"Unexpected circuit fields"}}
    private fun paths(values:List<PipePath>):JSONArray=JSONArray().also {array->values.forEach{path->
        val pieces=JSONArray();path.segments.forEach{pieces.put(JSONObject().put("id",it.id).put("name",it.name).put("lengthM",wire(it.lengthM)).put("insideMM",wire(it.insideMM)).put("roughnessMM",wire(it.roughnessMM)).put("zeta",wire(it.zeta)))}
        array.put(JSONObject().put("id",path.id).put("name",path.name).put("flowLPH",wire(path.flowLPH)).put("segments",pieces))
    }}
    private fun paths(array:JSONArray):List<PipePath> {
        require(array.length()<=10);return (0 until array.length()).map {index->
            val path=array.getJSONObject(index);exact(path,"id","name","flowLPH","segments");val pieces=path.getJSONArray("segments");require(pieces.length()<=30)
            val segments=(0 until pieces.length()).map{i->val value=pieces.getJSONObject(i);exact(value,"id","name","lengthM","insideMM","roughnessMM","zeta");PipeSegment(value.getString("id"),value.getString("name"),value.getDouble("lengthM"),value.getDouble("insideMM"),value.getDouble("roughnessMM"),value.getDouble("zeta"))}
            PipePath(path.getString("id"),path.getString("name"),path.getDouble("flowLPH"),segments)
        }
    }
    fun encode(book:PipeCircuitBook):String {
        PipeCircuitRules.validate(book);val projects=JSONArray();book.projects.forEach {projects.put(JSONObject().put("id",it.id).put("name",it.name).put("baseline",paths(it.baseline)).put("proposal",paths(it.proposal)))}
        return JSONObject().put("schema",book.schema).put("revision",book.revision).put("projects",projects).toString().also{require(it.toByteArray(Charsets.UTF_8).size<=maximumBytes){"Circuit archive size limit"}}
    }
    fun decode(text:String):PipeCircuitBook {
        require(text.isNotEmpty()&&text.toByteArray(Charsets.UTF_8).size<=maximumBytes);val tokenizer=JSONTokener(text);val root=tokenizer.nextValue() as? JSONObject?:error("Expected circuit object")
        require(tokenizer.nextClean()=='\u0000'){"Trailing circuit bytes"};exact(root,"schema","revision","projects");require(root.getInt("schema")==1){"Unsupported circuit schema"}
        val array=root.getJSONArray("projects");require(array.length()<=20)
        val projects=(0 until array.length()).map {index->val project=array.getJSONObject(index);exact(project,"id","name","baseline","proposal");PipeCircuitProject(project.getString("id"),project.getString("name"),paths(project.getJSONArray("baseline")),paths(project.getJSONArray("proposal")))}
        val book=PipeCircuitBook(root.getInt("schema"),root.getInt("revision"),projects);PipeCircuitRules.validate(book);require(encode(book)==text){"Noncanonical circuit archive"};return book
    }
}
class PipeCircuitFile(file:File,private val writer:((File,ByteArray)->Unit)?=null) {
    private val file=file.absoluteFile
    companion object {private val gate=Any()}
    private fun readBytes():ByteArray {
        FileInputStream(file).use {stream->val size=stream.channel.size();require(size in 1..PipeCircuitCodec.maximumBytes.toLong());val bytes=ByteArray(size.toInt());var offset=0
            while(offset<bytes.size){val count=stream.read(bytes,offset,bytes.size-offset);check(count>0);offset+=count};check(stream.read()==-1);return bytes}
    }
    private fun decode(bytes:ByteArray):PipeCircuitBook=PipeCircuitCodec.decode(StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString())
    fun load():PipeCircuitBook=synchronized(gate){if(file.exists())decode(readBytes())else PipeCircuitBook()}
    fun save(book:PipeCircuitBook,expectedRevision:Int) {
        val text=PipeCircuitCodec.encode(book);PipeCircuitCodec.decode(text);val bytes=text.toByteArray(Charsets.UTF_8)
        synchronized(gate) {
            val old=if(file.exists())readBytes()else null;val current=old?.let(::decode)?:PipeCircuitBook()
            if(old!=null&&bytes.contentEquals(old))return@synchronized
            require(expectedRevision>=0&&current.revision==expectedRevision&&book.revision==Math.addExact(expectedRevision,1)){"Circuit progress changed; reload"}
            if(writer!=null)writer.invoke(file,bytes)else atomicWrite(bytes)
            check(file.exists()&&readBytes().contentEquals(bytes)){"Circuit save could not be verified"}
        }
    }
    private fun atomicWrite(bytes:ByteArray) {
        val directory=file.parentFile?:error("Missing circuit directory");check(directory.isDirectory||directory.mkdirs());val temporary=File(directory,".pipe-circuits-${UUID.randomUUID()}.tmp")
        try {check(temporary.createNewFile());FileOutputStream(temporary).use{it.write(bytes);it.fd.sync()};check(temporary.readBytes().contentEquals(bytes));Files.move(temporary.toPath(),file.toPath(),StandardCopyOption.ATOMIC_MOVE,StandardCopyOption.REPLACE_EXISTING)}
        finally {if(temporary.exists())temporary.delete()}
    }
}
