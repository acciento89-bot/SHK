package de.kamilunavo.shk

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontSynthesis
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/** Each product packages only its own original licensed static faces. */
@Composable
internal fun shkTypography(kind: String): Typography {
    val assets = LocalContext.current.assets
    val family = remember(assets, kind) {
        when (kind) {
            "kaltecalc" -> FontFamily(
                Font(assetManager = assets, path = "fonts/Rambla-Regular.ttf", weight = FontWeight.Normal),
                Font(assetManager = assets, path = "fonts/Rambla-Bold.ttf", weight = FontWeight.Bold),
            )
            "lueftungscalc" -> FontFamily(
                Font(assetManager = assets, path = "fonts/Hind-Regular.ttf", weight = FontWeight.Normal),
                Font(assetManager = assets, path = "fonts/Hind-Bold.ttf", weight = FontWeight.Bold),
            )
            "heizkoerpercalc" -> FontFamily(
                Font(assetManager = assets, path = "fonts/Questrial-Regular.ttf", weight = FontWeight.Normal),
            )
            "rohrcalc" -> FontFamily(
                Font(assetManager = assets, path = "fonts/AsapCondensed-Regular.ttf", weight = FontWeight.Normal),
                Font(assetManager = assets, path = "fonts/AsapCondensed-Bold.ttf", weight = FontWeight.Bold),
            )
            "anlagencheck" -> FontFamily(
                Font(assetManager = assets, path = "fonts/Gudea-Regular.ttf", weight = FontWeight.Normal),
                Font(assetManager = assets, path = "fonts/Gudea-Bold.ttf", weight = FontWeight.Bold),
            )
            else -> error("Unknown calculator product: $kind")
        }
    }
    val base = Typography()
    return remember(family, kind) {
        base.copy(
            displayLarge = base.displayLarge.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.displayLarge.fontWeight),
            displayMedium = base.displayMedium.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.displayMedium.fontWeight),
            displaySmall = base.displaySmall.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.displaySmall.fontWeight),
            headlineLarge = base.headlineLarge.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.headlineLarge.fontWeight),
            headlineMedium = base.headlineMedium.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.headlineMedium.fontWeight),
            headlineSmall = base.headlineSmall.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.headlineSmall.fontWeight),
            titleLarge = base.titleLarge.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.titleLarge.fontWeight),
            titleMedium = base.titleMedium.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.titleMedium.fontWeight),
            titleSmall = base.titleSmall.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.titleSmall.fontWeight),
            bodyLarge = base.bodyLarge.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.bodyLarge.fontWeight),
            bodyMedium = base.bodyMedium.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.bodyMedium.fontWeight),
            bodySmall = base.bodySmall.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.bodySmall.fontWeight),
            labelLarge = base.labelLarge.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.labelLarge.fontWeight),
            labelMedium = base.labelMedium.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.labelMedium.fontWeight),
            labelSmall = base.labelSmall.copy(fontFamily = family, fontSynthesis = FontSynthesis.None, fontWeight = if (kind == "heizkoerpercalc") FontWeight.Normal else base.labelSmall.fontWeight),
        )
    }
}

internal fun shkColors(kind: String): ColorScheme {
    val colors = when (kind) {
    "kaltecalc" -> darkColorScheme(primary = Color(0xFF6FDFEB), onPrimary = Color(0xFF06262D), secondary = Color(0xFFB8CDD1), background = Color(0xFF0C202A), onBackground = Color(0xFFEAF7F9), surface = Color(0xFF15303B), onSurface = Color(0xFFEAF7F9), surfaceVariant = Color(0xFF22424D), onSurfaceVariant = Color(0xFFB8CDD1), outline = Color(0xFF64838C))
    "lueftungscalc" -> lightColorScheme(primary = Color(0xFF145D81), onPrimary = Color.White, secondary = Color(0xFF22625D), background = Color(0xFFEDF6FA), onBackground = Color(0xFF183744), surface = Color.White, onSurface = Color(0xFF183744), surfaceVariant = Color(0xFFDCECF1), onSurfaceVariant = Color(0xFF425D6A), outline = Color(0xFF6C8A98))
    "heizkoerpercalc" -> lightColorScheme(primary = Color(0xFF963F28), onPrimary = Color.White, secondary = Color(0xFF785139), background = Color(0xFFF5EEE4), onBackground = Color(0xFF382B24), surface = Color(0xFFFFFCF6), onSurface = Color(0xFF382B24), surfaceVariant = Color(0xFFEADCCE), onSurfaceVariant = Color(0xFF68534A), outline = Color(0xFF9D8375))
    "rohrcalc" -> darkColorScheme(primary = Color(0xFFF7D170), onPrimary = Color(0xFF283449), secondary = Color(0xFFB5D5EB), background = Color(0xFF102A43), onBackground = Color(0xFFF0F6FC), surface = Color(0xFF163E5B), onSurface = Color(0xFFF0F6FC), surfaceVariant = Color(0xFF244F6C), onSurfaceVariant = Color(0xFFC0D3E1), outline = Color(0xFF769DB5))
    else -> lightColorScheme(primary = Color(0xFF4D5E2C), onPrimary = Color.White, secondary = Color(0xFF7B5423), background = Color(0xFFF4F1DC), onBackground = Color(0xFF313521), surface = Color(0xFFFFFEF5), onSurface = Color(0xFF313521), surfaceVariant = Color(0xFFE6E7CD), onSurfaceVariant = Color(0xFF555E43), outline = Color(0xFF858C6A))
    }
    return colors.copy(
        primaryContainer = colors.surfaceVariant, onPrimaryContainer = colors.onSurface,
        secondaryContainer = colors.surfaceVariant, onSecondaryContainer = colors.onSurface,
        onSecondary = colors.onPrimary,
        surfaceContainerLowest = colors.background, surfaceContainerLow = colors.surface,
        surfaceContainer = colors.surface, surfaceContainerHigh = colors.surfaceVariant,
        surfaceContainerHighest = colors.surfaceVariant,
    )
}

internal fun shkShapes(kind: String): Shapes {
    val corner = when (kind) { "kaltecalc" -> 3.dp; "lueftungscalc" -> 6.dp; "heizkoerpercalc" -> 12.dp; "rohrcalc" -> 0.dp; else -> 2.dp }
    return Shapes(extraSmall = RoundedCornerShape(corner), small = RoundedCornerShape(corner), medium = RoundedCornerShape(corner), large = RoundedCornerShape(corner), extraLarge = RoundedCornerShape(corner))
}

@Composable
internal fun WorkflowHeading(code: String, title: String, subtitle: String) {
    val kind = BuildConfig.APP_KIND
    val colors = MaterialTheme.colorScheme
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        when (kind) {
            "kaltecalc" -> Row(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.Top) {
                Text(code, style = MaterialTheme.typography.headlineMedium, color = colors.primary)
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(title, style = MaterialTheme.typography.headlineMedium)
                    Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = colors.onSurfaceVariant)
                }
            }
            "lueftungscalc" -> {
                Text(code, style = MaterialTheme.typography.labelLarge, color = colors.primary)
                Text(title, style = MaterialTheme.typography.headlineMedium)
                HorizontalDivider(color = colors.primary, thickness = 3.dp)
                Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = colors.onSurfaceVariant)
            }
            "heizkoerpercalc" -> {
                Text(code, style = MaterialTheme.typography.labelLarge, color = colors.primary)
                Text(title, style = MaterialTheme.typography.headlineLarge)
                Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = colors.onSurfaceVariant)
                HorizontalDivider(color = colors.outline)
            }
            "rohrcalc" -> {
                Text("─┬─  $code", style = MaterialTheme.typography.titleLarge, color = colors.primary)
                Text(title, style = MaterialTheme.typography.headlineLarge)
                Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = colors.onSurfaceVariant)
            }
            else -> {
                Text(code, style = MaterialTheme.typography.labelLarge, color = colors.primary)
                HorizontalDivider(color = colors.primary, thickness = 2.dp)
                Text(title, style = MaterialTheme.typography.headlineMedium)
                Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = colors.onSurfaceVariant)
            }
        }
    }
}

@Composable
internal fun DocketEntry(code: String, title: String, detail: String, enabled: Boolean = true, onClick: () -> Unit) {
    Surface(onClick = onClick, enabled = enabled, color = MaterialTheme.colorScheme.surface, shape = MaterialTheme.shapes.medium, border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline)) {
        Row(Modifier.fillMaxWidth().heightIn(min = 64.dp).padding(16.dp), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.Top) {
            Text(code, color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.titleLarge)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                Text(title, style = MaterialTheme.typography.titleMedium)
                Text(detail, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Text("→", color = MaterialTheme.colorScheme.primary)
        }
    }
}

@Composable
internal fun WorkflowCount(label: String, value: String) {
    Column(Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surfaceVariant, MaterialTheme.shapes.medium).padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(label, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary)
    }
}

@Composable
internal fun VentProjectBoard(name: String, rooms: Int, terminals: Int, english: Boolean, enabled: Boolean, onOpen: () -> Unit) {
    Surface(onClick = onOpen, enabled = enabled, color = MaterialTheme.colorScheme.surface, border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline), shape = MaterialTheme.shapes.medium) {
        Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(name, style = MaterialTheme.typography.titleLarge)
            HorizontalDivider(color = MaterialTheme.colorScheme.primary)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                Column(Modifier.weight(1f)) { Text(if (english) "ROOMS" else "RÄUME", style = MaterialTheme.typography.labelLarge); Text(rooms.toString(), style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.primary) }
                Column(Modifier.weight(1f)) { Text(if (english) "TERMINALS" else "VENTILE", style = MaterialTheme.typography.labelLarge); Text(terminals.toString(), style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.primary) }
            }
            Text(if (english) "Open commissioning board →" else "Einstelltafel öffnen →", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
        }
    }
}

@Composable
internal fun RoomPassportCover(name: String, rooms: Int, scenarios: Int, english: Boolean, enabled: Boolean, onOpen: () -> Unit) {
    Surface(onClick = onOpen, enabled = enabled, color = MaterialTheme.colorScheme.surface, border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline), shape = MaterialTheme.shapes.large) {
        Column(Modifier.fillMaxWidth().padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(if (english) "RETROFIT PASSPORT" else "MODERNISIERUNGSPASS", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
            Text(name, style = MaterialTheme.typography.headlineSmall)
            HorizontalDivider()
            Text("$rooms " + (if (english) "rooms" else "Räume") + "  /  $scenarios " + (if (english) "temperature alternatives" else "Temperaturalternativen"), style = MaterialTheme.typography.bodyLarge)
            Text(if (english) "Existing → proposed radiators" else "Bestand → geplante Heizkörper", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
internal fun PipeRouteCover(name: String, baseline: Int, proposal: Int, english: Boolean, onOpen: () -> Unit) {
    Surface(onClick = onOpen, color = MaterialTheme.colorScheme.surface, border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline), shape = MaterialTheme.shapes.medium) {
        Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(9.dp)) {
            Text(name, style = MaterialTheme.typography.headlineSmall, color = MaterialTheme.colorScheme.primary)
            HorizontalDivider()
            Text("├─ " + (if (english) "BASELINE" else "BESTAND") + "  /  $baseline " + (if (english) "parallel paths" else "Parallelpfade"), style = MaterialTheme.typography.titleMedium)
            Text("└─ " + (if (english) "PROPOSAL" else "VORSCHLAG") + "  /  $proposal " + (if (english) "parallel paths" else "Parallelpfade"), style = MaterialTheme.typography.titleMedium)
            Text(if (english) "Open route sheet →" else "Routenblatt öffnen →", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
internal fun ServiceAgendaLine(date: String, name: String) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.Top) {
        Text(date, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
        Text(name, Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
    }
    HorizontalDivider()
}
