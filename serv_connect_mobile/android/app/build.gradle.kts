plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.john.serv_connect_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.john.serv_connect_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "flavor"

    productFlavors {
        create("dev") {
            dimension = "flavor"
            applicationId = "com.john.serv_connect_mobile.dev"
            resValue("string", "app_name", "ServeConnect Dev")
        }
        create("staging") {
            dimension = "flavor"
            applicationId = "com.john.serv_connect_mobile.staging"
            resValue("string", "app_name", "ServeConnect Staging")
        }
        create("prod") {
            dimension = "flavor"
            applicationId = "com.john.serv_connect_mobile"
            resValue("string", "app_name", "ServeConnect")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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
