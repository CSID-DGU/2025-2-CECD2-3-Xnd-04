import java.util.Properties
import java.io.FileInputStream

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        load(FileInputStream(file))
    }
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.Xnd"
    //flutter.compileSdkVersion -> 36으로 수정
    compileSdk = 36
    // ndkVersion = "29.0.13113456"  // NDK 버전 문제로 주석 처리

    compileOptions {
        // 👇 desugaring 활성화 추가
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.Xnd"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 카카오 앱 키 추가
        manifestPlaceholders["KAKAO_APP_KEY"] =
            localProperties.getProperty("KAKAO_APP_KEY")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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

// 👇 dependencies 블록 추가
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
    implementation("com.kakao.sdk:v2-user:2.20.3") // ✅ 카카오 SDK 추가
}
