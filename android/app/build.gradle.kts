plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}

val uploadKeystorePath = System.getenv("ANDROID_UPLOAD_KEYSTORE_PATH")
val uploadStorePassword = System.getenv("ANDROID_UPLOAD_STORE_PASSWORD")
val uploadKeyAlias = System.getenv("ANDROID_UPLOAD_KEY_ALIAS")
val uploadKeyPassword = System.getenv("ANDROID_UPLOAD_KEY_PASSWORD")

android {
    namespace = "de.kamilunavo.shk"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
        targetSdk = 36
        versionCode = 2
        versionName = "1.0.1"
    }

    flavorDimensions += "calculator"
    productFlavors {
        create("kaltecalc") {
            dimension = "calculator"
            applicationId = "de.kamilunav.kaltecalc"
            buildConfigField("String", "APP_KIND", "\"kaltecalc\"")
            resValue("string", "app_name", "KälteCalc")
        }
        create("lueftungscalc") {
            dimension = "calculator"
            applicationId = "de.kamilunavo.luftungscalc"
            buildConfigField("String", "APP_KIND", "\"lueftungscalc\"")
            resValue("string", "app_name", "LüftungsCalc")
        }
        create("heizkoerpercalc") {
            dimension = "calculator"
            applicationId = "de.kamilunavo.heizkorpercalc"
            buildConfigField("String", "APP_KIND", "\"heizkoerpercalc\"")
            resValue("string", "app_name", "HeizkörperCalc")
        }
        create("rohrcalc") {
            dimension = "calculator"
            applicationId = "de.kamilunavo.rohrcalc"
            buildConfigField("String", "APP_KIND", "\"rohrcalc\"")
            resValue("string", "app_name", "RohrCalc")
        }
        create("anlagencheck") {
            dimension = "calculator"
            applicationId = "de.kamilunavo.servicecheck"
            buildConfigField("String", "APP_KIND", "\"anlagencheck\"")
            resValue("string", "app_name", "AnlagenCheck")
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
        resValues = true
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    signingConfigs {
        create("releaseUpload") {
            if (!uploadKeystorePath.isNullOrBlank()) {
                storeFile = file(uploadKeystorePath)
                storeType = "JKS"
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
            }
        }
    }
    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            if (!uploadKeystorePath.isNullOrBlank()) {
                signingConfig = signingConfigs.getByName("releaseUpload")
            }
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.activity:activity-compose:1.12.4")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.10.0")
    implementation(platform("androidx.compose:compose-bom:2026.06.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    debugImplementation("androidx.compose.ui:ui-tooling")
}
