# Python script to overwrite build.gradle.kts with the fully corrected content.

import os

gradle_file_path = "flutter_dashboard_app/android/app/build.gradle.kts"

# Define the fully corrected content for build.gradle.kts
# This incorporates all fixes:
# - java.util.Properties import
# - Keystore logic placement inside android {} and before signingConfigs {}
# - Kotlin DSL .set() syntax for signingConfig and isMinifyEnabled
# - Correct namespace and applicationId

corrected_gradle_content = '''import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.jules.flutter_dashboard_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.jules.flutter_dashboard_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // Keystore properties loading logic
    val keystorePropertiesFile = rootProject.file("keystore.properties")
    val keystoreProperties = java.util.Properties()
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: System.getenv("KEY_ALIAS")
            keyPassword = keystoreProperties["keyPassword"] as String? ?: System.getenv("KEY_PASSWORD")
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) } ?: System.getenv("STORE_FILE")?.let { rootProject.file(it) }
            storePassword = keystoreProperties["storePassword"] as String? ?: System.getenv("STORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig.set(signingConfigs.getByName("release"))
            isMinifyEnabled.set(false) // Or .set(true) if preferred
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
'''

try:
    with open(gradle_file_path, "w") as f:
        f.write(corrected_gradle_content)
    print(f"Successfully overwrote {gradle_file_path} with fully corrected content.")
except Exception as e:
    print(f"Error overwriting {gradle_file_path}: {e}")
