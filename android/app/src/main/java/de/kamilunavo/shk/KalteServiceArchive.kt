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

object KalteServiceCodec {
    // Android writes -0 as an integer token and reads it as +0; wire zero has one canonical sign.
    private fun wire(value:Double)=if(value==0.0)0.0 else value
    const val maximumBytes=2*1024*1024
    private fun exact(value:JSONObject,vararg fields:String) {
        val actual=value.keys().asSequence().toSet();require(actual==fields.toSet()){"Unexpected service archive fields"}
    }
    private fun reading(value:KalteReading)=JSONObject().put("evaporationC",wire(value.evaporationC)).put("suctionC",wire(value.suctionC)).put("condensationC",wire(value.condensationC)).put("liquidC",wire(value.liquidC))
        .put("suctionGaugeBar",wire(value.suctionGaugeBar)).put("dischargeGaugeBar",wire(value.dischargeGaugeBar)).put("airFlowM3H",wire(value.airFlowM3H)).put("enteringAirC",wire(value.enteringAirC)).put("leavingAirC",wire(value.leavingAirC))
    private fun reading(value:JSONObject):KalteReading {
        exact(value,"evaporationC","suctionC","condensationC","liquidC","suctionGaugeBar","dischargeGaugeBar","airFlowM3H","enteringAirC","leavingAirC")
        return KalteReading(value.getDouble("evaporationC"),value.getDouble("suctionC"),value.getDouble("condensationC"),value.getDouble("liquidC"),value.getDouble("suctionGaugeBar"),value.getDouble("dischargeGaugeBar"),value.getDouble("airFlowM3H"),value.getDouble("enteringAirC"),value.getDouble("leavingAirC"))
    }
    fun encode(book:KalteServiceBook):String {
        KalteServiceRules.validate(book)
        val assets=JSONArray();book.assets.forEach {assets.put(JSONObject().put("id",it.id).put("name",it.name))}
        val visits=JSONArray();book.visits.forEach {visits.put(JSONObject().put("id",it.id).put("assetID",it.assetID).put("recordedAt",it.recordedAt).put("before",reading(it.before)).put("after",reading(it.after)).put("notes",it.notes))}
        return JSONObject().put("schema",book.schema).put("revision",book.revision).put("assets",assets).put("visits",visits).toString().also {require(it.toByteArray(Charsets.UTF_8).size<=maximumBytes){"Service archive size limit"}}
    }
    fun decode(text:String):KalteServiceBook {
        require(text.isNotEmpty() && text.toByteArray(Charsets.UTF_8).size<=maximumBytes){"Invalid service archive size"}
        val tokenizer=JSONTokener(text);val root=tokenizer.nextValue() as? JSONObject?:error("Expected service object")
        require(tokenizer.nextClean()=='\u0000'){"Unexpected trailing service bytes"};exact(root,"schema","revision","assets","visits")
        require(root.getInt("schema")==1){"Unsupported service schema"}
        val rawAssets=root.getJSONArray("assets");val rawVisits=root.getJSONArray("visits")
        require(rawAssets.length()<=40 && rawVisits.length()<=400){"Service archive limit"}
        val assets=(0 until rawAssets.length()).map {index->val value=rawAssets.getJSONObject(index);exact(value,"id","name");KalteAsset(value.getString("id"),value.getString("name"))}
        val visits=(0 until rawVisits.length()).map {index->val value=rawVisits.getJSONObject(index);exact(value,"id","assetID","recordedAt","before","after","notes");KalteVisit(value.getString("id"),value.getString("assetID"),value.getString("recordedAt"),reading(value.getJSONObject("before")),reading(value.getJSONObject("after")),value.getString("notes"))}
        val book=KalteServiceBook(root.getInt("schema"),root.getInt("revision"),assets,visits);KalteServiceRules.validate(book)
        // The app writes a single canonical document. Reject coercion, duplicates,
        // missing/unknown fields or parser-tolerated changes instead of normalizing old bytes.
        require(encode(book)==text){"Noncanonical or damaged service archive"}
        return book
    }
}

class KalteServiceFile(file:File,private val writer:((File,ByteArray)->Unit)?=null) {
    private val file=file.absoluteFile
    companion object {private val gate=Any()}
    private fun readBytes():ByteArray {
        FileInputStream(file).use {stream->
            val size=stream.channel.size();require(size in 1..KalteServiceCodec.maximumBytes.toLong()){"Invalid service archive size"}
            val bytes=ByteArray(size.toInt());var offset=0
            while(offset<bytes.size) {val count=stream.read(bytes,offset,bytes.size-offset);check(count>0){"Truncated service archive"};offset+=count}
            check(stream.read()==-1){"Service archive changed during reading"};return bytes
        }
    }
    private fun decode(bytes:ByteArray):KalteServiceBook {
        val text=StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString()
        return KalteServiceCodec.decode(text)
    }
    fun load():KalteServiceBook=synchronized(gate) {if(file.exists())decode(readBytes()) else KalteServiceBook()}
    fun save(book:KalteServiceBook,expectedRevision:Int) {
        val text=KalteServiceCodec.encode(book);KalteServiceCodec.decode(text);val bytes=text.toByteArray(Charsets.UTF_8)
        synchronized(gate) {
            val oldBytes=if(file.exists())readBytes() else null
            val current=oldBytes?.let(::decode)?:KalteServiceBook()
            if(oldBytes!=null && bytes.contentEquals(oldBytes))return@synchronized
            require(expectedRevision>=0 && current.revision==expectedRevision && book.revision==Math.addExact(expectedRevision,1)){"Saved service progress changed; reload before saving"}
            if(writer!=null)writer.invoke(file,bytes) else atomicWrite(bytes)
            check(file.exists() && readBytes().contentEquals(bytes)){"Service save could not be verified"}
        }
    }
    private fun atomicWrite(bytes:ByteArray) {
        val parent=file.parentFile?:error("Missing service directory");check(parent.isDirectory || parent.mkdirs()){"Service directory unavailable"}
        val temporary=File(parent,".kalte-service-${UUID.randomUUID()}.tmp")
        try {
            check(temporary.createNewFile()){"Service temporary file unavailable"}
            FileOutputStream(temporary).use {it.write(bytes);it.fd.sync()}
            check(temporary.readBytes().contentEquals(bytes)){"Temporary service save mismatch"}
            Files.move(temporary.toPath(),file.toPath(),StandardCopyOption.ATOMIC_MOVE,StandardCopyOption.REPLACE_EXISTING)
        } finally {if(temporary.exists())temporary.delete()}
    }
}
