import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Flutter doit être appliqué après Android et Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.winnyking.winboard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "26.1.10909125"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    signingConfigs {
        create("release") {
            // Initialisation de key.properties
            val keyProperties =
                rootProject.file("key.properties").takeIf { it.exists() }?.let {
                    Properties().apply { load(it.inputStream()) }
                }

            keyAlias = keyProperties?.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            keyPassword = keyProperties?.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            storeFile = file(keyProperties?.getProperty("storeFile") ?: System.getenv("STORE_FILE"))
            storePassword =
                keyProperties?.getProperty("storePassword") ?: System.getenv("STORE_PASSWORD")
        }
    }

    defaultConfig {
        applicationId = "com.winnyking.winboard"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Minification et réduction des ressources désactivées
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}