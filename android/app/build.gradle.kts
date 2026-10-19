import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Der Upload-Schlüssel für den Play Store. `key.properties` und die
// `.jks`-Datei liegen nur auf dem Rechner, der hochlädt, und sind
// gitignored. Fehlt die Datei, signiert der Release-Build wie bisher mit
// dem Debug-Schlüssel — ein APK zum Selbst-Installieren geht dann weiter,
// nur der Store nimmt es nicht. Vorlage: `android/key.properties.example`.
val uploadKey = Properties().apply {
    val datei = rootProject.file("key.properties")
    if (datei.exists()) datei.inputStream().use { load(it) }
}
val hatUploadKey = uploadKey.getProperty("storeFile") != null

android {
    namespace = "dev.prozesstek.lifes_game"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.prozesstek.lifes_game"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hatUploadKey) {
            create("upload") {
                storeFile = rootProject.file(uploadKey.getProperty("storeFile"))
                storePassword = uploadKey.getProperty("storePassword")
                keyAlias = uploadKey.getProperty("keyAlias")
                keyPassword = uploadKey.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (hatUploadKey) "upload" else "debug",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
