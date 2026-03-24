plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.hobit.hobit_worker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion


    signingConfigs {
        create("release") {
            storeFile = file("key.jks")
            storePassword = "hobit123"
            keyAlias = "my_key_alias"
            keyPassword = "hobit123"
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.hobit.hobit_worker"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔥 REQUIRED for desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

}