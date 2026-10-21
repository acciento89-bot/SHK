package de.kamilunavo.shk

import java.io.File
import java.nio.file.Files
import org.junit.Assert.*
import org.junit.Test

class ShkReportFilesTest {
    private fun rejects(block:()->Unit) {try{block()}catch(_:Exception){return};fail("Expected report write to reject")}
    @Test fun completeLargeUnicodeHistoryWritesExactRealUtf8FileInsteadOfBinderText() {
        val directory=Files.createTempDirectory("shk-full-report-").toFile()
        try {
            val text="KälteCalc · Vorher / Nachher · Δp · Überhitzung 🌡\n".repeat(40000)
            val expected=text.toByteArray(Charsets.UTF_8);assertTrue(expected.size>1024*1024)
            val file=ShkReportFiles(directory).write("kalte-service",text)
            assertEquals(directory.canonicalFile,file.parentFile.canonicalFile);assertTrue(file.name.startsWith("kalte-service-"));assertTrue(file.name.endsWith(".txt"))
            assertArrayEquals(expected,file.readBytes());assertEquals(text,file.readText(Charsets.UTF_8))
        } finally {directory.deleteRecursively()}
    }
    @Test fun failedTemporaryWriteLeavesOtherReportsAndForeignCacheBytesUntouched() {
        val directory=Files.createTempDirectory("shk-failed-report-").toFile()
        try {
            val existing=ShkReportFiles(directory).write("vent-commissioning","previous complete report")
            val foreign=File(directory,"foreign-cache.bin");foreign.writeBytes(byteArrayOf(1,2,3))
            val failing=ShkReportFiles(directory){file,_->file.writeText("partial");throw java.io.IOException("synthetic disk failure")}
            rejects {failing.write("kalte-service","new complete report")}
            assertEquals("previous complete report",existing.readText());assertArrayEquals(byteArrayOf(1,2,3),foreign.readBytes())
            assertEquals(2,directory.listFiles()!!.size)
        } finally {directory.deleteRecursively()}
    }
    @Test fun unsafeNamesEmptyOversizeAndMalformedUnicodeDoNotCreatePartialExports() {
        val directory=Files.createTempDirectory("shk-rejected-report-").toFile()
        try {
            val files=ShkReportFiles(directory)
            rejects {files.write("../outside","text")};rejects {files.write("kalte-service","")}
            rejects {files.write("kalte-service","x".repeat(16*1024*1024+1))}
            rejects {files.write("kalte-service",String(charArrayOf(0xD800.toChar())))}
            assertEquals(0,directory.listFiles()!!.size)
        } finally {directory.deleteRecursively()}
    }
}
