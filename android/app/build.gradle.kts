plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStorePath = System.getenv("ANDROID_KEYSTORE_PATH")
val releaseStorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = System.getenv("ANDROID_KEY_ALIAS")
val releaseKeyPassword = System.getenv("ANDROID_KEY_PASSWORD")

val persistentSigningReady =
    !releaseStorePath.isNullOrBlank() &&
        !releaseStorePassword.isNullOrBlank() &&
        !releaseKeyAlias.isNullOrBlank() &&
        !releaseKeyPassword.isNullOrBlank() &&
        file(releaseStorePath!!).exists()

gradle.taskGraph.whenReady {
    val releaseArtifactTaskSelected = allTasks.any { task ->
        val taskName = task.name.lowercase()
        taskName.contains("release") &&
            (
                taskName.startsWith("package") ||
                    taskName.startsWith("bundle") ||
                    taskName.startsWith("assemble")
            )
    }

    if (releaseArtifactTaskSelected && !persistentSigningReady) {
        throw GradleException(
            "Persistent signing is required for Battery Guard release artifacts.",
        )
    }
}

android {
    namespace = "com.riccardopinato.batteryguard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.riccardopinato.batteryguard"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["ADMOB_APP_ID"] =
            System.getenv("ADMOB_APP_ID")
                ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("persistent") {
            if (persistentSigningReady) {
                storeFile = file(releaseStorePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (persistentSigningReady) {
                signingConfig = signingConfigs.getByName("persistent")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
