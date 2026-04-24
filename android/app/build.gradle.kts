import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Release signing — loaded from android/key.properties (NOT committed to git)
//
// To generate a production keystore:
//   keytool -genkey -v -keystore clockly-release.jks \
//     -keyalg RSA -keysize 2048 -validity 10000 \
//     -alias clockly-key
//
// Then create android/key.properties with:
//   storePassword=<your-store-password>
//   keyPassword=<your-key-password>
//   keyAlias=clockly-key
//   storeFile=../clockly-release.jks   (path relative to android/app/)
//
// key.properties and *.jks are already excluded by android/.gitignore.
// ---------------------------------------------------------------------------
val keyPropertiesFile = rootProject.file("key.properties")
val useReleaseKeystore = keyPropertiesFile.exists()

android {
    namespace = "com.clockly.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    if (useReleaseKeystore) {
        val keyProperties = Properties().apply {
            load(FileInputStream(keyPropertiesFile))
        }
        signingConfigs {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.clockly.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (useReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // IMPORTANT: key.properties not found — using debug signing.
                // This build CANNOT be uploaded to Play Store.
                // Create android/key.properties before building for distribution.
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
