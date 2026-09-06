package de.kamilunavo.shk

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.Locale
import kotlin.math.*

private val Mint = Color(0xFF63E6BE)
private val BgTop = Color(0xFF040C0E)
private val BgBottom = Color(0xFF051717)
private val Panel = Color(0x18FFFFFF)
private val Muted = Color(0xFFAAB9BA)

@Composable
fun SHKApp(kind: String, onShare: (String) -> Unit) {
    MaterialTheme(colorScheme = darkColorScheme(primary = Mint, surface = BgTop)) {
        when (kind) {
            "kaltecalc" -> KalteCalc(onShare)
            "lueftungscalc" -> LueftungsCalc(onShare)
            "heizkoerpercalc" -> HeizkoerperCalc(onShare)
            "rohrcalc" -> RohrCalc(onShare)
            else -> AnlagenCheck(onShare)
        }
    }
}

@Composable
private fun AppPage(title: String, eyebrow: String, subtitle: String, content: @Composable ColumnScope.() -> Unit) {
    Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(BgTop, BgBottom)))) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = 18.dp, vertical = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text(eyebrow, color = Mint, fontSize = 12.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.5.sp)
                    Text(title, fontSize = 31.sp, fontWeight = FontWeight.Bold)
                    Text(subtitle, color = Muted, fontSize = 15.sp)
                }
            }
            item { Column(verticalArrangement = Arrangement.spacedBy(14.dp), content = content) }
        }
    }
}

@Composable
private fun CardBlock(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card(colors = CardDefaults.cardColors(containerColor = Panel), shape = RoundedCornerShape(24.dp)) {
        Column(Modifier.fillMaxWidth().padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(title.uppercase(Locale.GERMANY), color = Muted, fontSize = 12.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
            content()
        }
    }
}

@Composable
private fun MetricField(title: String, unit: String, value: Double, onChange: (Double) -> Unit) {
    var text by remember(value) { mutableStateOf(fmt(value, 2)) }
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(title, modifier = Modifier.weight(1f), fontWeight = FontWeight.Medium)
        OutlinedTextField(
            value = text,
            onValueChange = { raw ->
                text = raw
                raw.replace(',', '.').toDoubleOrNull()?.let(onChange)
            },
            modifier = Modifier.width(150.dp),
            singleLine = true,
            suffix = { Text(unit, color = Muted, fontSize = 12.sp) },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = Mint)
        )
    }
}

@Composable
private fun Result(title: String, value: String, subtitle: String = "") {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(title.uppercase(Locale.GERMANY), color = Muted, fontSize = 11.sp, fontWeight = FontWeight.Bold)
        Text(value, color = Mint, fontSize = 31.sp, fontWeight = FontWeight.Bold)
        if (subtitle.isNotBlank()) Text(subtitle, color = Muted, fontSize = 13.sp)
    }
}

@Composable
private fun ShareButton(label: String, text: String, onShare: (String) -> Unit) {
    OutlinedButton(onClick = { onShare(text) }, modifier = Modifier.fillMaxWidth()) { Text(label) }
}

@Composable
private fun KalteCalc(onShare: (String) -> Unit) {
    var evaporation by remember { mutableDoubleStateOf(4.0) }
    var suction by remember { mutableDoubleStateOf(11.0) }
    var condensation by remember { mutableDoubleStateOf(42.0) }
    var liquid by remember { mutableDoubleStateOf(36.0) }
    var suctionPressure by remember { mutableDoubleStateOf(7.5) }
    var dischargePressure by remember { mutableDoubleStateOf(24.0) }
    var airFlow by remember { mutableDoubleStateOf(800.0) }
    var enteringAir by remember { mutableDoubleStateOf(27.0) }
    var leavingAir by remember { mutableDoubleStateOf(19.0) }
    var celsius by remember { mutableDoubleStateOf(20.0) }
    var bar by remember { mutableDoubleStateOf(10.0) }
    var vacuumMbar by remember { mutableDoubleStateOf(1.0) }
    val superheat = suction - evaporation
    val subcooling = condensation - liquid
    val ratio = if (suctionPressure + 1.01325 > 0) (dischargePressure + 1.01325) / (suctionPressure + 1.01325) else 0.0
    val capacity = max(0.0, airFlow) * abs(enteringAir - leavingAir) * 0.000335
    AppPage("KälteCalc", "SERVICE CONSOLE", "Kältekreis, Luftseite und Service-Einheiten offline berechnen.") {
        CardBlock("Kältekreis") {
            MetricField("Verdampfung", "°C", evaporation) { evaporation = it }
            MetricField("Sauggas", "°C", suction) { suction = it }
            MetricField("Kondensation", "°C", condensation) { condensation = it }
            MetricField("Flüssigkeitsleitung", "°C", liquid) { liquid = it }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Result("Überhitzung", "${fmt(superheat, 1)} K")
                Result("Unterkühlung", "${fmt(subcooling, 1)} K")
            }
            Text("Sättigungstemperaturen aus Messgerät, Hersteller- oder verifizierter P/T-Quelle übernehmen.", color = Muted, fontSize = 12.sp)
        }
        CardBlock("Verdichter") {
            MetricField("Saugdruck", "bar(g)", suctionPressure) { suctionPressure = it }
            MetricField("Hochdruck", "bar(g)", dischargePressure) { dischargePressure = it }
            Result("Druckverhältnis", if (ratio > 0) "${fmt(ratio, 2)} : 1" else "–", "aus Absolutdrücken")
        }
        CardBlock("Luftseitige Leistung") {
            MetricField("Volumenstrom", "m³/h", airFlow) { airFlow = it }
            MetricField("Luft Eintritt", "°C", enteringAir) { enteringAir = it }
            MetricField("Luft Austritt", "°C", leavingAir) { leavingAir = it }
            Result("Sensible Leistung", "${fmt(capacity, 2)} kW", "Näherung ohne latente Leistung")
        }
        CardBlock("Umrechnungen") {
            MetricField("Temperatur", "°C", celsius) { celsius = it }
            Text("${fmt(celsius * 9 / 5 + 32, 2)} °F", color = Mint, fontWeight = FontWeight.Bold)
            MetricField("Druck", "bar", bar) { bar = it }
            Text("${fmt(bar * 14.5037738, 2)} psi · ${fmt(bar * 100, 1)} kPa", color = Mint, fontWeight = FontWeight.Bold)
            MetricField("Vakuum", "mbar(abs)", vacuumMbar) { vacuumMbar = it }
            Text("${fmt(vacuumMbar * 750.061683, 0)} micron · ${fmt(vacuumMbar * 100, 1)} Pa", color = Mint, fontWeight = FontWeight.Bold)
        }
        ShareButton("Servicewerte teilen", "KälteCalc\nÜberhitzung ${fmt(superheat,1)} K\nUnterkühlung ${fmt(subcooling,1)} K\nDruckverhältnis ${fmt(ratio,2)}:1\nLuftleistung ${fmt(capacity,2)} kW", onShare)
    }
}

@Composable
private fun LueftungsCalc(onShare: (String) -> Unit) {
    var flow by remember { mutableDoubleStateOf(250.0) }
    var targetVelocity by remember { mutableDoubleStateOf(3.0) }
    var diameter by remember { mutableDoubleStateOf(180.0) }
    var width by remember { mutableDoubleStateOf(300.0) }
    var height by remember { mutableDoubleStateOf(200.0) }
    var roomLength by remember { mutableDoubleStateOf(5.0) }
    var roomWidth by remember { mutableDoubleStateOf(4.0) }
    var roomHeight by remember { mutableDoubleStateOf(2.5) }
    var airChanges by remember { mutableDoubleStateOf(1.5) }
    val q = max(0.0, flow) / 3600
    val requiredDiameter = if (q > 0 && targetVelocity > 0) sqrt(4 * q / (PI * targetVelocity)) * 1000 else 0.0
    val roundVelocity = if (diameter > 0) q / (PI * (diameter / 1000).pow(2) / 4) else 0.0
    val rectangularVelocity = if (width > 0 && height > 0) q / (width / 1000 * height / 1000) else 0.0
    val requiredHeight = if (width > 0 && targetVelocity > 0) q / (width / 1000 * targetVelocity) * 1000 else 0.0
    val equivalentDiameter = if (width > 0 && height > 0) 1.30 * (width * height).pow(0.625) / (width + height).pow(0.25) else 0.0
    val roomVolume = max(0.0, roomLength) * max(0.0, roomWidth) * max(0.0, roomHeight)
    val roomFlow = roomVolume * max(0.0, airChanges)
    AppPage("LüftungsCalc", "AIRFLOW STUDIO", "Kanalquerschnitt und Raumluftwechsel getrennt bearbeiten.") {
        CardBlock("Rundkanal") {
            MetricField("Volumenstrom", "m³/h", flow) { flow = it }
            MetricField("Zielgeschwindigkeit", "m/s", targetVelocity) { targetVelocity = it }
            Result("Erforderlicher Durchmesser", "${fmt(requiredDiameter, 0)} mm")
            MetricField("Vorhandener Durchmesser", "mm", diameter) { diameter = it }
            Result("Ist-Geschwindigkeit", "${fmt(roundVelocity, 2)} m/s")
        }
        CardBlock("Rechteckkanal") {
            MetricField("Breite", "mm", width) { width = it }
            MetricField("Höhe", "mm", height) { height = it }
            Result("Geschwindigkeit", "${fmt(rectangularVelocity, 2)} m/s")
            Text("Erforderliche Höhe ${fmt(requiredHeight,0)} mm · äquivalenter Rund-Ø ${fmt(equivalentDiameter,0)} mm", color = Muted)
        }
        CardBlock("Raumluftwechsel") {
            MetricField("Raumlänge", "m", roomLength) { roomLength = it }
            MetricField("Raumbreite", "m", roomWidth) { roomWidth = it }
            MetricField("Raumhöhe", "m", roomHeight) { roomHeight = it }
            MetricField("Luftwechsel", "1/h", airChanges) { airChanges = it }
            Result("Raumvolumen", "${fmt(roomVolume, 1)} m³")
            Result("Erforderliche Luftmenge", "${fmt(roomFlow, 0)} m³/h")
        }
        CardBlock("Einheiten") { Text("${fmt(flow,0)} m³/h = ${fmt(flow/3.6,1)} l/s = ${fmt(flow*0.588577779,0)} CFM", color = Mint, fontWeight = FontWeight.Bold) }
        ShareButton("Luftberechnung teilen", "LüftungsCalc\nVolumenstrom ${fmt(flow,0)} m³/h\nRund-Ø ${fmt(requiredDiameter,0)} mm\nRaumluft ${fmt(roomFlow,0)} m³/h", onShare)
    }
}

@Composable
private fun HeizkoerperCalc(onShare: (String) -> Unit) {
    var nominal by remember { mutableDoubleStateOf(2000.0) }
    var required by remember { mutableDoubleStateOf(1500.0) }
    var flow by remember { mutableDoubleStateOf(55.0) }
    var ret by remember { mutableDoubleStateOf(45.0) }
    var room by remember { mutableDoubleStateOf(20.0) }
    var exponent by remember { mutableDoubleStateOf(1.30) }
    val arithmetic = max(0.0, (flow + ret) / 2 - room)
    val ratioC = if (flow > room) (ret - room) / (flow - room) else 0.0
    val logarithmic = if (flow >= ret && flow > room && ret > room && abs(flow-ret) > 1e-6) (flow-ret)/ln((flow-room)/(ret-room)) else arithmetic
    val delta = if (ratioC > 0 && ratioC < 0.7) logarithmic else arithmetic
    val ref = if (ratioC > 0 && ratioC < 0.7) (75.0-65.0)/ln((75.0-20.0)/(65.0-20.0)) else 50.0
    val actual = if (nominal > 0 && delta > 0 && exponent > 0) nominal * (delta/ref).pow(exponent) else 0.0
    val requiredNominal = if (required > 0 && delta > 0 && exponent > 0) required / (delta/ref).pow(exponent) else 0.0
    val count = if (required > 0 && actual > 0) ceil(required/actual).toInt() else 0
    val waterFlow = if (actual > 0 && flow > ret) actual/(1.163*(flow-ret)) else 0.0
    AppPage("HeizkörperCalc", "RAUM & HEIZFLÄCHE", "Heizkörper passend zum realen Betriebspunkt bewerten.") {
        CardBlock("Betriebspunkt") {
            MetricField("Hersteller-Nennleistung ΔT50", "W", nominal) { nominal = it }
            Text("ΔT50 ist die mittlere Heizkörper-Übertemperatur zum Raum, nicht die Vor-/Rücklauf-Spreizung.", color = Muted, fontSize = 12.sp)
            MetricField("Vorlauf", "°C", flow) { flow = it }
            MetricField("Rücklauf", "°C", ret) { ret = it }
            MetricField("Raum", "°C", room) { room = it }
            MetricField("Hersteller-Exponent n", "", exponent) { exponent = it }
            Result("Leistung am Betriebspunkt", "${fmt(actual, 0)} W", "ΔT ${fmt(delta,1)} K · ${if (ratioC > 0 && ratioC < 0.7) "logarithmisch" else "arithmetisch"}")
            Result("Volumenstrom", "${fmt(waterFlow, 0)} l/h")
        }
        CardBlock("Auslegung") {
            MetricField("Gewünschte Raumleistung", "W", required) { required = it }
            Result("Erforderliche Nennleistung ΔT50", "${fmt(requiredNominal, 0)} W")
            Result("Heizkörperanzahl", "$count")
        }
        CardBlock("Temperaturvergleich") {
            TemperatureLevel("75 / 65 / 20 °C", nominal)
            TemperatureLevel("55 / 45 / 20 °C", nominal * (30.0 / 50.0).pow(exponent))
            TemperatureLevel("45 / 35 / 20 °C", nominal * (20.0 / 50.0).pow(exponent))
            Text("Vergleich mit arithmetischer mittlerer Übertemperatur.", color = Muted, fontSize = 12.sp)
        }
        Text("Herstellerdaten zu Nennleistung und Exponent n sowie die objektspezifische Heizlast haben Vorrang.", color = Muted, fontSize = 12.sp)
        ShareButton("Auslegung teilen", "HeizkörperCalc\nBetriebspunkt ${fmt(flow,0)}/${fmt(ret,0)}/${fmt(room,0)} °C\nLeistung ${fmt(actual,0)} W\nErforderlich ΔT50 ${fmt(requiredNominal,0)} W", onShare)
    }
}

private data class PipeResult(val velocity: Double, val volume: Double, val reynolds: Double, val dpPerM: Double, val total: Double, val head: Double)
private fun pipeResult(flowLPH: Double, diameterMM: Double, lengthM: Double, roughnessMM: Double, zeta: Double): PipeResult {
    if (flowLPH <= 0 || diameterMM <= 0) return PipeResult(0.0,0.0,0.0,0.0,0.0,0.0)
    val d=diameterMM/1000; val area=PI*d*d/4; val q=flowLPH/1000/3600; val v=q/area; val re=v*d/1.004e-6
    val f=if(re in 0.0..2299.999) 64/re else 1/(-1.8*log10((max(0.0,roughnessMM/1000)/d/3.7).pow(1.11)+6.9/re)).pow(2)
    val dp=f*(998*v*v/2)/d; val local=max(0.0,zeta)*(998*v*v/2)/1000; val total=dp*max(0.0,lengthM)/1000+local
    return PipeResult(v,area*max(0.0,lengthM)*1000,re,dp,total,total*1000/(998*9.80665))
}

@Composable
private fun RohrCalc(onShare: (String) -> Unit) {
    var flow by remember { mutableDoubleStateOf(1000.0) }
    var diameter by remember { mutableDoubleStateOf(20.0) }
    var length by remember { mutableDoubleStateOf(10.0) }
    var roughness by remember { mutableDoubleStateOf(0.01) }
    var zeta by remember { mutableDoubleStateOf(0.0) }
    var targetVelocity by remember { mutableDoubleStateOf(1.0) }
    val r=pipeResult(flow,diameter,length,roughness,zeta)
    val q=max(0.0,flow)/1000/3600
    val requiredDiameter=if(q>0 && targetVelocity>0) sqrt(4*q/(PI*targetVelocity))*1000 else 0.0
    val maximumFlow=if(diameter>0 && targetVelocity>0) PI*(diameter/1000).pow(2)/4*targetVelocity*3600*1000 else 0.0
    val regime=when { r.reynolds<2300 -> "laminar"; r.reynolds<4000 -> "Übergangsbereich"; else -> "turbulent" }
    AppPage("RohrCalc", "HYDRAULIC WORKSHEET", "Freier Innendurchmesser · reale Länge · ζ-Widerstände") {
        CardBlock("Rohrstrecke 01") {
            MetricField("Volumenstrom", "l/h", flow) { flow = it }
            MetricField("Freier Innendurchmesser", "mm", diameter) { diameter = it }
            MetricField("Rohrlänge", "m", length) { length = it }
            MetricField("Rauheit", "mm", roughness) { roughness = it }
            MetricField("ζ-Summe", "", zeta) { zeta = it }
        }
        CardBlock("Hydraulik") {
            Result("Gesamtdruckverlust", "${fmt(r.total,2)} kPa")
            Text("${fmt(r.dpPerM,0)} Pa/m · ${fmt(r.head,2)} mWS", color = Muted)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Result("Geschwindigkeit", "${fmt(r.velocity,2)} m/s")
                Result("Reynolds", fmt(r.reynolds,0), regime)
            }
            Result("Rohrinhalt", "${fmt(r.volume,2)} l")
        }
        CardBlock("Dimensionierung") {
            MetricField("Zielgeschwindigkeit", "m/s", targetVelocity) { targetVelocity = it }
            Result("Erforderlicher freier Ø", "${fmt(requiredDiameter,1)} mm")
            Result("Max. Volumenstrom bei vorhandenem Ø", "${fmt(maximumFlow,0)} l/h")
        }
        CardBlock("Schnellvergleich") {
            Text("Freier Ø · Geschwindigkeit · Druckverlust", color = Muted, fontSize = 12.sp)
            listOf(15.0, 20.0, 25.0, 32.0).forEach { d ->
                val row = pipeResult(flow, d, 1.0, roughness, 0.0)
                Text("${fmt(d,0)} mm   ${fmt(row.velocity,2)} m/s   ${fmt(row.dpPerM,0)} Pa/m", color = if(abs(d-diameter)<0.1) Mint else Color.White)
            }
        }
        Text("Wasserwerte nahe 20 °C. Temperatur, Glykol und andere Medien verändern Reynolds-Zahl und Druckverlust.", color = Muted, fontSize = 12.sp)
        ShareButton("Hydraulikblatt teilen", "RohrCalc\nØi ${fmt(diameter,1)} mm · ${fmt(flow,0)} l/h\nv ${fmt(r.velocity,2)} m/s\nΔp ${fmt(r.total,2)} kPa", onShare)
    }
}

@Composable
private fun AnlagenCheck(onShare: (String) -> Unit) {
    var objectName by remember { mutableStateOf("") }
    var flow by remember { mutableDoubleStateOf(55.0) }
    var ret by remember { mutableDoubleStateOf(45.0) }
    var cold by remember { mutableDoubleStateOf(1.5) }
    var hot by remember { mutableDoubleStateOf(1.9) }
    var minPressure by remember { mutableDoubleStateOf(1.2) }
    var maxPressure by remember { mutableDoubleStateOf(2.0) }
    var staticHeight by remember { mutableDoubleStateOf(8.0) }
    var safetyValve by remember { mutableDoubleStateOf(3.0) }
    var tightness by remember { mutableStateOf(false) }
    var vented by remember { mutableStateOf(false) }
    var pumpChecked by remember { mutableStateOf(false) }
    var filtersChecked by remember { mutableStateOf(false) }
    var notes by remember { mutableStateOf("") }
    val spread=flow-ret; val rise=hot-cold; val minStatic=max(0.0,staticHeight)*0.0980665+0.3; val margin=safetyValve-hot
    val warnings=listOf(spread<0 || spread<5 || spread>20, cold<minPressure || cold>maxPressure, cold<minStatic, rise<0 || rise>1, margin<0.5).count{it}
    AppPage("AnlagenCheck", "SERVICE INSPECTION", "Messwerte erfassen, gegen eigene Vorgaben prüfen und dokumentieren.") {
        CardBlock("Objekt / Anlage") { OutlinedTextField(objectName,{objectName=it},Modifier.fillMaxWidth(),placeholder={Text("z. B. Heizzentrale Nord")}) }
        CardBlock("Messwerte") {
            MetricField("Vorlauf", "°C", flow) { flow = it }
            MetricField("Rücklauf", "°C", ret) { ret = it }
            MetricField("Kaltfülldruck", "bar", cold) { cold = it }
            MetricField("Warmdruck", "bar", hot) { hot = it }
            MetricField("Statische Anlagenhöhe", "m", staticHeight) { staticHeight = it }
            MetricField("Sicherheitsventil", "bar", safetyValve) { safetyValve = it }
        }
        CardBlock("Eigene Prüfvorgaben") {
            MetricField("Kaltfülldruck min.", "bar", minPressure) { minPressure = it }
            MetricField("Kaltfülldruck max.", "bar", maxPressure) { maxPressure = it }
        }
        CardBlock("Plausibilisierung") {
            Result(if(warnings==0) "Status" else "Prüfhinweise", if(warnings==0) "Plausibel" else "$warnings prüfen")
            CheckLine("Temperaturspreizung", "${fmt(spread,1)} K", spread in 5.0..20.0)
            CheckLine("Kaltfülldruck", "${fmt(cold,2)} bar", cold in minPressure..maxPressure)
            CheckLine("Statische Mindestvorgabe", "${fmt(minStatic,2)} bar", cold>=minStatic)
            CheckLine("Druckanstieg warm", "+${fmt(rise,2)} bar", rise in 0.0..1.0)
            CheckLine("Reserve Sicherheitsventil", "${fmt(margin,2)} bar", margin>=0.5)
        }
        CardBlock("Service-Checkliste") {
            ChecklistRow("Sichtprüfung / Dichtheit", tightness) { tightness = it }
            ChecklistRow("Anlage entlüftet", vented) { vented = it }
            ChecklistRow("Umwälzpumpe geprüft", pumpChecked) { pumpChecked = it }
            ChecklistRow("Filter / Schmutzfänger geprüft", filtersChecked) { filtersChecked = it }
            OutlinedTextField(notes, { notes = it }, Modifier.fillMaxWidth(), label = { Text("Freie Notizen") }, minLines = 3)
        }
        Text("Keine Sicherheitsfreigabe. Herstellerangaben, Normen, Messgeräte und fachliche Beurteilung haben Vorrang.", color = Muted, fontSize = 12.sp)
        ShareButton("Servicebericht teilen", "AnlagenCheck · ${objectName.ifBlank{"Ohne Objektbezeichnung"}}\nVorlauf/Rücklauf ${fmt(flow,1)}/${fmt(ret,1)} °C\nKalt/Warm ${fmt(cold,2)}/${fmt(hot,2)} bar\n$warnings Prüfhinweise\nCheckliste ${listOf(tightness,vented,pumpChecked,filtersChecked).count{it}}/4\n${notes.ifBlank{"Keine Notizen"}}", onShare)
    }
}

@Composable
private fun CheckLine(title: String, value: String, ok: Boolean) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
        Text(if(ok) "✓ $title" else "! $title", color=if(ok) Mint else Color(0xFFFFB74D), fontWeight=FontWeight.SemiBold)
        Text(value, color=Muted)
    }
}

@Composable
private fun TemperatureLevel(label: String, watts: Double) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = Muted)
        Text("${fmt(watts,0)} W", color = Mint, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun ChecklistRow(label: String, checked: Boolean, onChecked: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Checkbox(checked = checked, onCheckedChange = onChecked, colors = CheckboxDefaults.colors(checkedColor = Mint))
        Text(label, modifier = Modifier.weight(1f))
    }
}

private fun fmt(value: Double, digits: Int): String = String.format(Locale.GERMANY, "%.${digits}f", if(value.isFinite()) value else 0.0)
