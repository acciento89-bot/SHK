@file:OptIn(androidx.compose.ui.ExperimentalComposeUiApi::class)

package de.kamilunavo.shk

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private fun landingText(english: Boolean, de: String, en: String) = if (english) en else de
private fun countText(value: Int?) = value?.toString() ?: "—"

@Composable
private fun LanguageControl(english: Boolean, change: () -> Unit) {
    TextButton(onClick = change, modifier = Modifier.heightIn(min = 48.dp)) { Text(if (english) "DE" else "EN") }
}

@Composable
private fun RegisterCount(label: String, count: Int?, modifier: Modifier = Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(countText(count), style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.primary)
        Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

/** An inventory/commissioning board: counts are records, never invented air readings. */
@Composable
internal fun VentLandingBoard(book: VentCommissioningBook?, busy: Boolean, english: Boolean, onLanguage: () -> Unit, onTools: () -> Unit, onNew: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val terminals = book?.projects?.flatMap { it.terminals }
    Column(Modifier.fillMaxWidth().semantics { testTagsAsResourceId = true }, verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text("LüftungsCalc", style = MaterialTheme.typography.titleLarge)
                Text(landingText(english, "INBETRIEBNAHME", "COMMISSIONING"), color = colors.primary, style = MaterialTheme.typography.labelLarge)
            }
            LanguageControl(english, onLanguage)
        }
        Text(landingText(english, "Einstelltafel", "Commissioning board"), style = MaterialTheme.typography.headlineLarge)
        Row(Modifier.fillMaxWidth().background(colors.surface).border(1.dp, colors.outline).padding(14.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            RegisterCount(landingText(english, "Projekte", "Projects"), book?.projects?.size, Modifier.weight(1f))
            RegisterCount(landingText(english, "Räume", "Rooms"), book?.projects?.sumOf { it.rooms.size }, Modifier.weight(1f))
            RegisterCount(landingText(english, "Ventile", "Terminals"), terminals?.size, Modifier.weight(1f))
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            for (side in VentSide.entries) {
                val points = terminals?.filter { it.side == side }
                Column(Modifier.weight(1f).background(colors.surface).border(1.dp, colors.outline).padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(if (side == VentSide.SUPPLY) landingText(english, "ZULUFT", "SUPPLY") else landingText(english, "ABLUFT", "EXTRACT"), color = colors.primary, style = MaterialTheme.typography.titleMedium)
                    AirDirectionGlyph(side == VentSide.SUPPLY)
                    Text(if (points.isNullOrEmpty()) "—" else points.size.toString(), style = MaterialTheme.typography.headlineLarge)
                    Text(if (points == null) landingText(english, "Register lädt", "Register loading") else if (points.isEmpty()) landingText(english, "Keine Messstellen", "No terminals") else landingText(english, "Ventile erfasst", "terminals recorded"), style = MaterialTheme.typography.bodyMedium)
                    Text(if (points.isNullOrEmpty()) landingText(english, "Luftmenge nicht erfasst", "Airflow unrecorded") else "${points.count { it.measuredM3H != null }} / ${points.size} " + landingText(english, "gemessen", "measured"), style = MaterialTheme.typography.labelMedium, color = colors.onSurfaceVariant)
                }
            }
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf(landingText(english, "Räume", "Rooms"), landingText(english, "Ventile", "Terminals"), landingText(english, "Besuche", "Visits")).forEachIndexed { index, label ->
                Column(Modifier.weight(1f).border(1.dp, colors.outline).padding(10.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text("0${index + 1}", color = colors.primary, style = MaterialTheme.typography.titleMedium)
                    Text(label, style = MaterialTheme.typography.labelLarge)
                }
            }
        }
        Surface(onClick = onNew, enabled = book != null && !busy && book.projects.size < 20, shape = RoundedCornerShape(0.dp), color = colors.primary, contentColor = colors.onPrimary, modifier = Modifier.fillMaxWidth().testTag("vent-create-project")) {
            Row(Modifier.heightIn(min = 64.dp).padding(14.dp), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("+", style = MaterialTheme.typography.headlineMedium)
                Text(landingText(english, "Projekt zur Einstelltafel hinzufügen", "Add commissioning project"), Modifier.weight(1f), style = MaterialTheme.typography.titleMedium)
            }
        }
        TextButton(onClick = onTools, enabled = !busy) { Text(landingText(english, "Kanal- und Raumrechner →", "Duct and room calculators →")) }
        HorizontalDivider(color = colors.primary, thickness = 2.dp)
        Text(landingText(english, "PROJEKTREGISTER", "PROJECT REGISTER"), style = MaterialTheme.typography.labelLarge, color = colors.primary)
        if (book?.projects?.isEmpty() == true) Text(landingText(english, "Noch kein Projekt. Soll- und Istwerte beginnen mit deinen Messstellen.", "No projects yet. Add your terminals to record targets and measurements."), style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun AirDirectionGlyph(supply: Boolean) {
    val ink = MaterialTheme.colorScheme.primary
    Canvas(Modifier.fillMaxWidth().height(28.dp)) {
        val middle = size.height / 2
        val start = if (supply) 0f else size.width
        val end = if (supply) size.width else 0f
        drawLine(ink, Offset(start, middle), Offset(end, middle), 2.dp.toPx())
        val tip = if (supply) -9.dp.toPx() else 9.dp.toPx()
        drawLine(ink, Offset(end + tip, 3.dp.toPx()), Offset(end, middle), 2.dp.toPx())
        drawLine(ink, Offset(end + tip, size.height - 3.dp.toPx()), Offset(end, middle), 2.dp.toPx())
    }
}

/** A room passport with paired inventories; the plan drawing is explicitly schematic. */
@Composable
internal fun RadiatorLandingPassport(book: RadiatorRetrofitBook?, busy: Boolean, english: Boolean, onLanguage: () -> Unit, onTools: () -> Unit, onNew: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val rooms = book?.projects?.flatMap { it.rooms }
    Column(Modifier.fillMaxWidth().semantics { testTagsAsResourceId = true }, verticalArrangement = Arrangement.spacedBy(18.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("HeizkörperCalc", Modifier.weight(1f), style = MaterialTheme.typography.titleLarge)
            LanguageControl(english, onLanguage)
        }
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(landingText(english, "MODERNISIERUNG", "RETROFIT"), color = colors.primary, style = MaterialTheme.typography.labelLarge)
                Text(landingText(english, "Der Raum.\nSeine Wärme.", "The room.\nIts warmth."), style = MaterialTheme.typography.headlineLarge)
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                RoomRadiatorGlyph()
                Text(landingText(english, "RAUMSCHEMA", "ROOM SCHEMA"), style = MaterialTheme.typography.labelSmall, color = colors.onSurfaceVariant)
            }
        }
        Column(Modifier.fillMaxWidth().background(colors.surface, RoundedCornerShape(topEnd = 28.dp, bottomEnd = 4.dp)).border(1.dp, colors.outline, RoundedCornerShape(topEnd = 28.dp, bottomEnd = 4.dp)).padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text(landingText(english, "RAUMPASS", "ROOM PASSPORT"), style = MaterialTheme.typography.labelLarge, color = colors.primary)
            Text(if (book?.projects?.isEmpty() == true) landingText(english, "Dein erster Raum beginnt hier.", "Your first room starts here.") else landingText(english, "Bestand und Vorschlag im Raum.", "Existing and proposed, room by room."), style = MaterialTheme.typography.titleLarge)
            HorizontalDivider(color = colors.outline)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                for (proposed in listOf(false, true)) {
                    val count = rooms?.sumOf { room -> (if (proposed) room.proposed else room.existing).sumOf { it.count } }
                    Column(Modifier.weight(1f).background(if (proposed) colors.surfaceVariant else colors.background).padding(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(if (proposed) landingText(english, "VORSCHLAG", "PROPOSED") else landingText(english, "BESTAND", "EXISTING"), style = MaterialTheme.typography.labelLarge, color = colors.primary)
                        Text(if (rooms.isNullOrEmpty()) "—" else countText(count), style = MaterialTheme.typography.headlineLarge)
                        Text(if (rooms == null) landingText(english, "Archiv lädt", "Archive loading") else if (rooms.isEmpty()) landingText(english, "Keine Heizkörper erfasst", "No radiators recorded") else landingText(english, "Heizkörper in gespeicherten Räumen", "radiators in saved rooms"), style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }
            Text(countText(rooms?.size) + landingText(english, " Räume  ·  ", " rooms  ·  ") + countText(book?.projects?.size) + landingText(english, " Pässe", " passports"), style = MaterialTheme.typography.bodyMedium, color = colors.onSurfaceVariant)
            Surface(onClick = onNew, enabled = book != null && !busy && book.projects.size < 20, color = colors.primary, contentColor = colors.onPrimary, shape = RoundedCornerShape(topEnd = 18.dp, bottomEnd = 18.dp), modifier = Modifier.fillMaxWidth().testTag("radiator-create-project")) {
                Row(Modifier.heightIn(min = 64.dp).padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    Text("+", style = MaterialTheme.typography.headlineMedium)
                    Text(landingText(english, "Modernisierung anlegen", "Create retrofit project"), Modifier.weight(1f), style = MaterialTheme.typography.titleMedium)
                }
            }
        }
        TextButton(onClick = onTools, enabled = !busy) { Text(landingText(english, "Einzelnen Heizkörper berechnen →", "Calculate a single radiator →")) }
        Text(landingText(english, "GESPEICHERTE RAUMPÄSSE", "SAVED ROOM PASSPORTS"), style = MaterialTheme.typography.labelLarge, color = colors.primary)
    }
}

@Composable
private fun RoomRadiatorGlyph() {
    val ink = MaterialTheme.colorScheme.primary
    Canvas(Modifier.size(96.dp, 110.dp)) {
        val stroke = 2.dp.toPx()
        drawRect(ink, Offset(5.dp.toPx(), 5.dp.toPx()), Size(size.width - 10.dp.toPx(), size.height - 18.dp.toPx()), style = Stroke(stroke))
        drawLine(ink, Offset(5.dp.toPx(), size.height * .7f), Offset(size.width * .42f, size.height * .7f), stroke)
        drawArc(ink.copy(alpha = .6f), -90f, 90f, false, Offset(5.dp.toPx(), size.height * .42f), Size(size.width * .4f, size.height * .28f), style = Stroke(stroke))
        for (index in 0..4) {
            val x = size.width * .55f + index * 6.dp.toPx()
            drawLine(ink, Offset(x, size.height * .2f), Offset(x, size.height * .48f), 3.dp.toPx(), StrokeCap.Round)
        }
        drawLine(ink, Offset(size.width * .52f, size.height * .34f), Offset(size.width * .87f, size.height * .34f), stroke)
    }
}

/** Route drafting area: empty rows/dashes never stand for a declared physical network. */
@Composable
internal fun PipeLandingWorksheet(book: PipeCircuitBook?, english: Boolean, busy: Boolean, onLanguage: () -> Unit, onTools: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val pathCount = book?.projects?.sumOf { it.baseline.size + it.proposal.size }
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(18.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("RohrCalc", Modifier.weight(1f), style = MaterialTheme.typography.headlineMedium)
            LanguageControl(english, onLanguage)
        }
        Row(Modifier.fillMaxWidth().border(1.dp, colors.outline).padding(12.dp), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Text(landingText(english, "ROUTENBLATT", "ROUTE SHEET"), Modifier.weight(1f), color = colors.primary, style = MaterialTheme.typography.titleLarge)
            Text(countText(book?.projects?.size) + landingText(english, " Projekte", " projects"), style = MaterialTheme.typography.bodyLarge)
        }
        Column(Modifier.fillMaxWidth().background(colors.surface).border(1.dp, colors.outline).padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(landingText(english, "PARALLELPFADE / REIHENSEGMENTE", "PARALLEL PATHS / SERIES SEGMENTS"), color = colors.primary, style = MaterialTheme.typography.labelLarge)
            PipeBranchGlyph()
            Text(if (pathCount == null) landingText(english, "Routenschema · Archiv noch nicht geladen", "Route schema · archive not loaded yet") else if (pathCount == 0) landingText(english, "Leeres Routenschema · keine Pfade deklariert", "Empty route schema · no declared paths") else landingText(english, "Symbolisches Schema · kein Projekt ausgewählt", "Symbolic schema · no project selected"), style = MaterialTheme.typography.bodyMedium, color = colors.onSurfaceVariant)
        }
        Column(Modifier.fillMaxWidth().border(1.dp, colors.outline).padding(14.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(Modifier.fillMaxWidth()) {
                Text(landingText(english, "PFAD", "PATH"), Modifier.weight(1f), style = MaterialTheme.typography.labelLarge, color = colors.primary)
                Text(landingText(english, "LÄNGE", "LENGTH"), Modifier.weight(1f), style = MaterialTheme.typography.labelLarge, color = colors.primary)
                Text(landingText(english, "INHALT", "VOLUME"), Modifier.weight(1f), style = MaterialTheme.typography.labelLarge, color = colors.primary)
            }
            HorizontalDivider(color = colors.outline)
            Row(Modifier.fillMaxWidth()) { repeat(3) { Text("—", Modifier.weight(1f), style = MaterialTheme.typography.headlineMedium) } }
            Text(landingText(english, "Projekt öffnen oder anlegen, dann reale Pfade und Segmente eintragen.", "Open or create a project, then enter actual paths and segments."), style = MaterialTheme.typography.bodyMedium)
        }
        TextButton(onClick = onTools, enabled = !busy) { Text(landingText(english, "Rohr-Schnellrechner →", "Quick pipe calculator →")) }
        Text(landingText(english, "PROJEKTABLAGE", "PROJECT FILES"), color = colors.primary, style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
private fun PipeBranchGlyph() {
    val ink = MaterialTheme.colorScheme.primary
    val muted = MaterialTheme.colorScheme.outline
    Canvas(Modifier.fillMaxWidth().height(140.dp)) {
        val left = size.width * .12f
        val right = size.width * .88f
        val stroke = 2.dp.toPx()
        drawLine(ink, Offset(left, size.height * .2f), Offset(left, size.height * .8f), stroke)
        drawLine(ink, Offset(right, size.height * .2f), Offset(right, size.height * .8f), stroke)
        for (fraction in listOf(.2f, .8f)) {
            val y = size.height * fraction
            drawLine(ink, Offset(left, y), Offset(right, y), stroke)
            for (index in 1..3) {
                val x = left + (right - left) * index / 4
                drawRect(muted, Offset(x - 10.dp.toPx(), y - 7.dp.toPx()), Size(20.dp.toPx(), 14.dp.toPx()), style = Stroke(stroke))
            }
        }
        drawLine(ink, Offset(0f, size.height / 2), Offset(left, size.height / 2), stroke)
        drawLine(ink, Offset(right, size.height / 2), Offset(size.width, size.height / 2), stroke)
    }
}

@Composable
internal fun PipeLandingDock(enabled: Boolean, english: Boolean, onNew: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    Surface(color = colors.surface, border = BorderStroke(1.dp, colors.outline), modifier = Modifier.fillMaxWidth()) {
        Button(onClick = onNew, enabled = enabled, shape = RoundedCornerShape(0.dp), modifier = Modifier.fillMaxWidth().navigationBarsPadding().padding(horizontal = 18.dp, vertical = 12.dp).heightIn(min = 58.dp).testTag("pipe-create-project").semantics { testTagsAsResourceId = true }) {
            Text(landingText(english, "+  Rohrkreisprojekt anlegen", "+  Create circuit project"), textAlign = TextAlign.Center, style = MaterialTheme.typography.titleMedium)
        }
    }
}

/** A folio spine, actual saved agenda, and paired installation/checklist actions. */
@Composable
internal fun CheckLandingDocket(book: ServiceHistoryBook?, busy: Boolean, english: Boolean, onLanguage: () -> Unit, onTools: () -> Unit, onInstallation: () -> Unit, onChecklist: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val due = book?.let { ServiceHistoryRules.nextServices(it) }
    Column(Modifier.fillMaxWidth().semantics { testTagsAsResourceId = true }, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text("AnlagenCheck", style = MaterialTheme.typography.titleLarge)
                Text(landingText(english, "PRÜFAKTE / SERVICEFOLGE", "INSPECTION FILE / SERVICE DOCKET"), color = colors.primary, style = MaterialTheme.typography.labelLarge)
            }
            LanguageControl(english, onLanguage)
        }
        Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
            Box(Modifier.width(9.dp).fillMaxHeight().background(colors.primary))
            Column(Modifier.weight(1f).background(colors.surface).border(1.dp, colors.outline).padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text(landingText(english, "Nächste Services", "Next services"), style = MaterialTheme.typography.headlineMedium)
                Row(Modifier.fillMaxWidth()) {
                    Text(landingText(english, "DATUM", "DATE"), Modifier.weight(1f), color = colors.primary, style = MaterialTheme.typography.labelLarge)
                    Text(landingText(english, "ANLAGE / AKTE", "INSTALLATION / FILE"), Modifier.weight(2f), color = colors.primary, style = MaterialTheme.typography.labelLarge)
                }
                HorizontalDivider(color = colors.outline)
                if (due.isNullOrEmpty()) {
                    Row(Modifier.fillMaxWidth()) { Text("—", Modifier.weight(1f), style = MaterialTheme.typography.headlineMedium); Text(if (book == null) landingText(english, "Archiv lädt", "Archive loading") else landingText(english, "Kein Folgetermin gespeichert", "No next-service date saved"), Modifier.weight(2f), style = MaterialTheme.typography.bodyLarge) }
                    Text(landingText(english, "Termine entstehen aus deinen gespeicherten Servicebesuchen.", "Dates come from your saved service visits."), style = MaterialTheme.typography.bodyMedium, color = colors.onSurfaceVariant)
                } else due.forEach { ServiceAgendaLine(it.date, it.name) }
            }
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Surface(onClick = onInstallation, enabled = book != null && !busy && book.installations.size < 40, color = colors.primary, contentColor = colors.onPrimary, shape = RoundedCornerShape(2.dp), modifier = Modifier.weight(1f).testTag("service-create-installation")) {
                Column(Modifier.padding(14.dp).heightIn(min = 76.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) { Text("+ A", style = MaterialTheme.typography.titleLarge); Text(landingText(english, "Anlage anlegen", "Add installation"), style = MaterialTheme.typography.titleMedium) }
            }
            Surface(onClick = onChecklist, enabled = book != null && !busy && book.templates.size < 30, color = colors.surface, border = BorderStroke(1.dp, colors.primary), shape = RoundedCornerShape(2.dp), modifier = Modifier.weight(1f).testTag("service-create-checklist")) {
                Column(Modifier.padding(14.dp).heightIn(min = 76.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) { Text("+ C", color = colors.primary, style = MaterialTheme.typography.titleLarge); Text(landingText(english, "Eigene Checkliste", "Own checklist"), style = MaterialTheme.typography.titleMedium) }
            }
        }
        Text(countText(book?.installations?.size) + landingText(english, " Anlagen  ·  ", " installations  ·  ") + countText(book?.templates?.size) + landingText(english, " Vorlagen  ·  ", " templates  ·  ") + countText(book?.visits?.size) + landingText(english, " Besuche", " visits"), style = MaterialTheme.typography.bodyMedium, color = colors.onSurfaceVariant)
        TextButton(onClick = onTools, enabled = !busy) { Text(landingText(english, "Messwerte einzeln prüfen →", "Check individual readings →")) }
        HorizontalDivider(color = colors.primary, thickness = 2.dp)
        Text(landingText(english, "ANLAGENREGISTER", "INSTALLATION REGISTER"), color = colors.primary, style = MaterialTheme.typography.labelLarge)
        if (book?.installations?.isEmpty() == true) Text(landingText(english, "Noch keine Anlagenakte angelegt.", "No installation file created yet."), style = MaterialTheme.typography.bodyMedium)
    }
}

/** A diagnostic bench, with the appliance register and visit archive as separate instruments. */
@Composable
internal fun KalteLandingBench(book: KalteServiceBook?, busy: Boolean, english: Boolean, onLanguage: () -> Unit, onTools: () -> Unit, onNew: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    Column(Modifier.fillMaxWidth().semantics { testTagsAsResourceId = true }, verticalArrangement = Arrangement.spacedBy(18.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("KälteCalc", Modifier.weight(1f), style = MaterialTheme.typography.headlineMedium)
            LanguageControl(english, onLanguage)
        }
        Text(landingText(english, "SERVICEBANK", "SERVICE BENCH"), color = colors.primary, style = MaterialTheme.typography.labelLarge)
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Column(Modifier.weight(1f).background(colors.surfaceVariant).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) { Text(landingText(english, "ANLAGEN", "APPLIANCES"), style = MaterialTheme.typography.labelLarge); Text(countText(book?.assets?.size), color = colors.primary, style = MaterialTheme.typography.displaySmall); Text(landingText(english, "Serviceobjekte", "Service assets"), style = MaterialTheme.typography.bodyMedium) }
            Column(Modifier.weight(1f).border(1.dp, colors.outline).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) { Text(landingText(english, "BESUCHE", "VISITS"), style = MaterialTheme.typography.labelLarge); Text(countText(book?.visits?.size), color = colors.primary, style = MaterialTheme.typography.displaySmall); Text(landingText(english, "Messprotokolle", "Reading records"), style = MaterialTheme.typography.bodyMedium) }
        }
        Column(Modifier.fillMaxWidth().border(1.dp, colors.outline).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(landingText(english, "BESUCHSVERGLEICH", "VISIT COMPARISON"), color = colors.primary, style = MaterialTheme.typography.labelLarge)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) { Text(landingText(english, "VORHER", "BEFORE")); Text("—", style = MaterialTheme.typography.headlineLarge) }
                Text("→", color = colors.primary, style = MaterialTheme.typography.headlineMedium)
                Column(Modifier.weight(1f)) { Text(landingText(english, "NACHHER", "AFTER")); Text("—", style = MaterialTheme.typography.headlineLarge) }
            }
            Text(landingText(english, "Keine Besuchsmessung ausgewählt", "No visit readings selected"), color = colors.onSurfaceVariant, style = MaterialTheme.typography.bodyMedium)
        }
        Surface(onClick = onNew, enabled = book != null && !busy && book.assets.size < 40, color = colors.primary, contentColor = colors.onPrimary, shape = RoundedCornerShape(3.dp), modifier = Modifier.fillMaxWidth().testTag("kalte-create-asset")) {
            Row(Modifier.heightIn(min = 64.dp).padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) { Text("+ K", style = MaterialTheme.typography.titleLarge); Text(landingText(english, "Serviceanlage aufnehmen", "Register service appliance"), Modifier.weight(1f), style = MaterialTheme.typography.titleMedium) }
        }
        TextButton(onClick = onTools, enabled = !busy) { Text(landingText(english, "Kältekreis & Einheiten berechnen →", "Refrigeration & unit tools →")) }
        HorizontalDivider(color = colors.outline)
        Text(landingText(english, "ANLAGENREGISTER", "APPLIANCE REGISTER"), color = colors.primary, style = MaterialTheme.typography.labelLarge)
        if (book?.assets?.isEmpty() == true) Text(landingText(english, "Noch keine Serviceanlage gespeichert.", "No service appliances saved yet."), style = MaterialTheme.typography.bodyMedium)
    }
}
