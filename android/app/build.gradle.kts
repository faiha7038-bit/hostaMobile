// import java.util.Properties
// import java.io.FileInputStream

// plugins {
//     id("com.android.application")
//     id("com.google.gms.google-services")
//     id("kotlin-android")
//     id("dev.flutter.flutter-gradle-plugin")
// }

// val keystoreProperties = Properties()
// val keystorePropertiesFile = rootProject.file("key.properties")
// if (keystorePropertiesFile.exists()) {
//     keystoreProperties.load(FileInputStream(keystorePropertiesFile))
// }

// android {
//     namespace = "com.zorrowtech.hostamanagers"
//     compileSdk = flutter.compileSdkVersion.toInt()
//     ndkVersion = flutter.ndkVersion

//     compileOptions {
//         isCoreLibraryDesugaringEnabled = true
//         sourceCompatibility = JavaVersion.VERSION_1_8
//         targetCompatibility = JavaVersion.VERSION_1_8
//     }

//     kotlinOptions {
//         jvmTarget = "1.8"
//     }

//     defaultConfig {
//         applicationId = "com.zorrowtech.hostamanagers"
//         minSdk = flutter.minSdkVersion.toInt()
//         targetSdk = flutter.targetSdkVersion.toInt()
//         versionCode = flutter.versionCode.toInt()
//         versionName = flutter.versionName
//         multiDexEnabled = true
//     }


//  signingConfigs {
//         create("release") {
//             keyAlias = keystoreProperties["keyAlias"] as String
//             keyPassword = keystoreProperties["keyPassword"] as String
//             storeFile = keystoreProperties["storeFile"]?.let { file(it) }
//             storePassword = keystoreProperties["storePassword"] as String
//         }
//     }
//     buildTypes {
//         release {
//             // TODO: Add your own signing config for the release build.
//             // Signing with the debug keys for now,
//             // so `flutter run --release` works.
//             signingConfig = signingConfigs.getByName("debug")
//             signingConfig = signingConfigs.getByName("release")
//         }
//     }


    
// }

// flutter {
//     source = "../.."
// }

// dependencies {
//     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
//     implementation("androidx.window:window:1.0.0")
//     implementation("androidx.window:window-java:1.0.0")
// }

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.zorrowtech.hostamanagers"
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.zorrowtech.hostamanagers"
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            // Use release signing config for release builds
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            // Use debug signing config for debug builds
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
}