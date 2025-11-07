plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.SmartCart"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.SmartCart"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Copy APK to the location Flutter expects
tasks.register("copyApkToFlutterBuild") {
    doLast {
        val flutterApkDir = File(project.rootDir.parent, "build/app/outputs/flutter-apk")
        val androidApkDir = File(project.buildDir, "outputs/flutter-apk")
        
        if (androidApkDir.exists()) {
            flutterApkDir.mkdirs()
            androidApkDir.listFiles()?.forEach { apkFile ->
                if (apkFile.isFile) {
                    apkFile.copyTo(File(flutterApkDir, apkFile.name), overwrite = true)
                    println("Copied ${apkFile.name} to ${flutterApkDir.absolutePath}")
                }
            }
        }
    }
}

tasks.whenTaskAdded {
    if (name == "assembleDebug" || name == "assembleRelease" || name == "assembleProfile") {
        finalizedBy("copyApkToFlutterBuild")
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
