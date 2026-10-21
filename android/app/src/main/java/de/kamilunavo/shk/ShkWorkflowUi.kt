package de.kamilunavo.shk

import androidx.compose.runtime.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

internal class ShkWorkflowStore<T>(private val scope:CoroutineScope,private val read:()->T,private val write:(T,Int)->Unit) {
    var book by mutableStateOf<T?>(null);private set
    var busy by mutableStateOf(false);private set
    var error by mutableStateOf(false);private set
    fun reload(done:()->Unit={}) {
        if(busy)return;busy=true
        scope.launch {try{val saved=withContext(Dispatchers.IO){read()};book=saved;error=false;done()}catch(_:Exception){error=true}finally{busy=false}}
    }
    fun commit(value:T,revision:Int,done:()->Unit) {
        if(busy)return;busy=true
        scope.launch {try{withContext(Dispatchers.IO){write(value,revision)};book=value;error=false;done()}catch(_:Exception){error=true}finally{busy=false}}
    }
}
@Composable
internal fun <T> rememberShkWorkflowStore(key:Any,read:()->T,write:(T,Int)->Unit):ShkWorkflowStore<T> {
    val scope=rememberCoroutineScope();val store=remember(key){ShkWorkflowStore(scope,read,write)}
    LaunchedEffect(store){store.reload()};return store
}
internal fun shkNumber(raw:String):Double?=raw.trim().replace(',','.').toDoubleOrNull()?.takeIf(Double::isFinite)
