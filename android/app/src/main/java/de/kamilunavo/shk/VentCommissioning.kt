package de.kamilunavo.shk

import java.time.Instant
import java.util.Locale
import java.util.UUID

enum class VentSide { SUPPLY,EXTRACT }
data class VentRoom(val id:String,val name:String)
data class VentTerminal(val id:String,val roomID:String,val name:String,val side:VentSide,val targetM3H:Double,val measuredM3H:Double?)
data class VentVisit(val id:String,val recordedAt:String,val rooms:List<VentRoom>,val terminals:List<VentTerminal>,val note:String)
data class VentProject(val id:String,val name:String,val rooms:List<VentRoom> = emptyList(),val terminals:List<VentTerminal> = emptyList(),val visits:List<VentVisit> = emptyList())
data class VentCommissioningBook(val schema:Int=2,val revision:Int=0,val projects:List<VentProject> = emptyList())
data class VentTotals(val targetM3H:Double,val measuredM3H:Double?,val deviationM3H:Double?,val deviationPercent:Double?,val measuredLitresPerSecond:Double?,val measuredCFM:Double?,val unmeasuredCount:Int,val terminalCount:Int)

object VentCommissioningRules {
    private fun id(value:String) {require(runCatching {UUID.fromString(value).toString()==value}.getOrDefault(false)){"Invalid commissioning identity"}}
    private fun name(value:String) {require(value.isNotBlank()&&value==value.trim()&&value.length<=120){"Invalid commissioning name"}}
    private fun terminal(value:VentTerminal) {
        id(value.id);id(value.roomID);name(value.name)
        require(value.targetM3H.isFinite()&&value.targetM3H in 0.0..100000.0&&(value.measuredM3H?.let{it.isFinite()&&it in 0.0..100000.0}?:true)){"Invalid air volume flow"}
    }
    fun totals(terminals:List<VentTerminal>,side:VentSide):VentTotals {
        terminals.forEach(::terminal);val matching=terminals.filter{it.side==side}
        val target=matching.sumOf{it.targetM3H};val missing=matching.count{it.measuredM3H==null}
        // A partial set is not a measured total. Recorded zero is still a real reading.
        val measured=if(matching.isNotEmpty()&&missing==0)matching.sumOf{it.measuredM3H!!}else null
        val delta=measured?.minus(target)
        val percent=if(target==0.0)null else delta?.let{(it/target*100).takeIf(Double::isFinite)}
        return VentTotals(target,measured,delta,percent,measured?.div(3.6),measured?.times(.588577779),missing,matching.size)
    }
    internal fun validate(book:VentCommissioningBook) {
        require(book.schema==2&&book.revision>=0&&book.projects.size<=20){"Unsupported commissioning archive"}
        val claims=HashMap<String,Pair<String,String>>()
        fun claim(value:String,kind:String,owner:String,repeated:Boolean=false) {id(value);val old=claims[value];require(old==null||repeated&&old==Pair(kind,owner)){"Duplicate or foreign commissioning identity"};claims[value]=Pair(kind,owner)}
        fun contents(projectID:String,rooms:List<VentRoom>,terminals:List<VentTerminal>) {
            require(rooms.size<=40&&terminals.size<=80){"Commissioning capacity"}
            val roomIDs=HashSet<String>();val terminalIDs=HashSet<String>()
            rooms.forEach {claim(it.id,"room",projectID,true);name(it.name);require(roomIDs.add(it.id)){"Duplicate room"}}
            terminals.forEach {terminal(it);claim(it.id,"terminal",projectID,true);require(terminalIDs.add(it.id)&&it.roomID in roomIDs){"Duplicate terminal or foreign room"}}
        }
        book.projects.forEach {claim(it.id,"project",it.id);name(it.name)}
        book.projects.forEach {project->
            contents(project.id,project.rooms,project.terminals);require(project.visits.size<=40){"Commissioning history capacity"}
            project.visits.forEach {visit->
                claim(visit.id,"visit",project.id);require(visit.terminals.isNotEmpty()&&visit.note.length<=2000){"Invalid commissioning visit"}
                require(runCatching{Instant.parse(visit.recordedAt).toString()==visit.recordedAt}.getOrDefault(false)){"Invalid visit UTC time"}
                contents(project.id,visit.rooms,visit.terminals)
            }
        }
    }
    private fun update(book:VentCommissioningBook,projectID:String,action:(VentProject)->VentProject):VentCommissioningBook {
        validate(book);require(book.projects.any{it.id==projectID}){"Unknown commissioning project"}
        return book.copy(revision=Math.addExact(book.revision,1),projects=book.projects.map{if(it.id==projectID)action(it)else it.copy(rooms=it.rooms.toList(),terminals=it.terminals.toList(),visits=it.visits.toList())}).also(::validate)
    }
    fun addProject(book:VentCommissioningBook,id:String,name:String):VentCommissioningBook {
        validate(book);return book.copy(revision=Math.addExact(book.revision,1),projects=book.projects+VentProject(id,name)).also(::validate)
    }
    fun putRoom(book:VentCommissioningBook,projectID:String,room:VentRoom)=update(book,projectID) {project->project.copy(rooms=if(project.rooms.any{it.id==room.id})project.rooms.map{if(it.id==room.id)room else it}else project.rooms+room)}
    fun putTerminal(book:VentCommissioningBook,projectID:String,terminal:VentTerminal)=update(book,projectID) {project->project.copy(terminals=if(project.terminals.any{it.id==terminal.id})project.terminals.map{if(it.id==terminal.id)terminal else it}else project.terminals+terminal)}
    fun removeRoom(book:VentCommissioningBook,projectID:String,roomID:String)=update(book,projectID) {project->require(project.rooms.any{it.id==roomID}&&project.terminals.none{it.roomID==roomID}){"Room still contains terminals"};project.copy(rooms=project.rooms.filterNot{it.id==roomID})}
    fun removeTerminal(book:VentCommissioningBook,projectID:String,terminalID:String)=update(book,projectID) {project->require(project.terminals.any{it.id==terminalID}){"Unknown terminal"};project.copy(terminals=project.terminals.filterNot{it.id==terminalID})}
    fun recordVisit(book:VentCommissioningBook,projectID:String,id:String,recordedAt:String,note:String)=update(book,projectID) {project->
        project.copy(visits=project.visits+VentVisit(id,recordedAt,project.rooms.toList(),project.terminals.toList(),note))
    }
    fun report(book:VentCommissioningBook,projectID:String,english:Boolean):String {
        validate(book);val project=book.projects.single{it.id==projectID};val locale=if(english)Locale.US else Locale.GERMANY
        fun t(de:String,en:String)=if(english)en else de
        fun number(value:Double?)=value?.let{String.format(locale,"%.2f",it)}?:t("Nicht gemessen","Unmeasured")
        fun side(value:VentSide)=if(value==VentSide.SUPPLY)t("Zuluft","Supply") else t("Abluft","Extract")
        fun percent(value:VentTotals)=if(value.terminalCount==0)t("Keine Messstellen erfasst","No terminals recorded")else if(value.measuredM3H==null)t("Unvollständig","Incomplete")else value.deviationPercent?.let{number(it)+"%"}?:if(value.targetM3H==0.0)t("ohne Soll / Prozent nicht berechenbar","no target / percentage unavailable")else t("Prozent außerhalb des Zahlenbereichs","Percentage outside numeric range")
        return buildString {
            appendLine("LüftungsCalc · "+t("Inbetriebnahme","Commissioning"));appendLine(project.name)
            fun summary(label:String,terminals:List<VentTerminal>) {
                appendLine(label)
                for(direction in VentSide.entries) {
                    val values=totals(terminals,direction)
                    if(values.unmeasuredCount>0)appendLine(t("Messpunkte offen: ","Unmeasured terminals: ")+values.unmeasuredCount)
                    appendLine(side(direction)+" · "+t("Soll / Ist / Abweichung","Target / Measured / Deviation")+": ${number(values.targetM3H)} / ${number(values.measuredM3H)} / ${number(values.deviationM3H)} m³/h · ${percent(values)}")
                    appendLine(t("Ist: ","Measured: ")+"${number(values.measuredLitresPerSecond)} l/s · ${number(values.measuredCFM)} CFM")
                }
            }
            fun sheet(rooms:List<VentRoom>,terminals:List<VentTerminal>) {
                summary(t("Projekt gesamt (Zuluft und Abluft getrennt)","Project totals (supply and extract separate)"),terminals)
                rooms.forEach {room->
                    val selected=terminals.filter{it.roomID==room.id};summary(room.name,selected)
                    selected.forEach {terminal->
                        val values=totals(listOf(terminal),terminal.side)
                        appendLine("  ${terminal.name} · ${side(terminal.side)} · "+t("Soll / Ist","Target / Measured")+": ${number(terminal.targetM3H)} / ${number(terminal.measuredM3H)} m³/h · ${percent(values)}")
                    }
                }
            }
            appendLine(t("Aktueller Einstellstand","Current adjustment"));sheet(project.rooms,project.terminals)
            project.visits.sortedBy{Instant.parse(it.recordedAt)}.forEach {visit->appendLine();appendLine(visit.recordedAt+" UTC · "+visit.note);sheet(visit.rooms,visit.terminals)}
            append(t("Sollwerte vom Anwender. Keine automatische Norm- oder Sicherheitsfreigabe; Zuluft/Abluft werden nicht verrechnet.","User-supplied targets. No automatic standards or safety approval; supply and extract are not netted."))
        }
    }
}
