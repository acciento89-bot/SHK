package de.kamilunavo.shk

import java.io.File
import java.io.FileOutputStream
import java.nio.CharBuffer
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.util.UUID

class ShkReportFiles(private val directory:File,private val temporaryWriter:((File,ByteArray)->Unit)?=null) {
    private val prefixes=setOf("kalte-service","vent-commissioning","radiator-survey","pipe-circuits","service-visits")
    fun write(prefix:String,text:String):File {
        require(prefix in prefixes&&text.isNotEmpty()&&text.length<=16*1024*1024){"Invalid report export"}
        val encoded=StandardCharsets.UTF_8.newEncoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT).encode(CharBuffer.wrap(text))
        require(encoded.remaining() in 1..16*1024*1024){"Report export size limit"}
        val bytes=ByteArray(encoded.remaining());encoded.get(bytes)
        check(directory.isDirectory||directory.mkdirs()){"Report directory unavailable"}
        val token=UUID.randomUUID().toString()
        val temporary=File(directory,".$prefix-$token.tmp");val result=File(directory,"$prefix-$token.txt")
        var verified=false
        try {
            check(temporary.createNewFile())
            if(temporaryWriter!=null)temporaryWriter.invoke(temporary,bytes)
            else FileOutputStream(temporary).use{it.write(bytes);it.fd.sync()}
            check(temporary.readBytes().contentEquals(bytes)){"Incomplete report export"}
            Files.move(temporary.toPath(),result.toPath(),StandardCopyOption.ATOMIC_MOVE)
            check(result.readBytes().contentEquals(bytes)){"Report export verification failed"};verified=true
            return result
        } finally {
            if(temporary.exists())temporary.delete()
            if(!verified&&result.exists())result.delete()
        }
    }
}
