package de.kamilunavo.shk

import android.content.Intent
import android.content.ClipData
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.content.FileProvider
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.Locale

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            SHKApp(BuildConfig.APP_KIND, onShare = { text ->
                startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, text)
                }, null))
            }, onReportShare = ::shareWorkflowReport)
        }
    }
    private fun shareWorkflowReport(text:String) {
        lifecycleScope.launch {
            try {
                val prefix=when(BuildConfig.APP_KIND) {"kaltecalc"->"kalte-service";"lueftungscalc"->"vent-commissioning";"heizkoerpercalc"->"radiator-survey";"rohrcalc"->"pipe-circuits";else->"service-visits"}
                val file=withContext(Dispatchers.IO){ShkReportFiles(File(cacheDir,"shk-reports")).write(prefix,text)}
                val uri=FileProvider.getUriForFile(this@MainActivity,"${packageName}.reports",file)
                val intent=Intent(Intent.ACTION_SEND).apply {
                    type="text/plain";putExtra(Intent.EXTRA_STREAM,uri)
                    clipData=ClipData.newRawUri("SHK report",uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(Intent.createChooser(intent,null).apply{addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)})
            } catch(cancelled:CancellationException) {throw cancelled}
            catch(_:Exception) {Toast.makeText(this@MainActivity,if(Locale.getDefault().language.startsWith("de"))"Bericht konnte nicht geteilt werden. Gespeicherte Daten bleiben erhalten." else "Report could not be shared. Saved data is kept.",Toast.LENGTH_LONG).show()}
        }
    }
}
