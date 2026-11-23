import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is read from android/app/key.properties (never committed):
//   storeFile=..., storePassword=..., keyAlias=..., keyPassword=...
val keyProperties = Properties().apply {
    val file = project.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "net.mynet.mynet_staff"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Separate from the customer app (net.mynet.app): both can sit on one phone.
        applicationId = "net.mynet.staff"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Release must use the MyNet keystore — never fall back to debug.
            // Missing key.properties is refused when a release is actually
            // built (see the task-graph check below), not here: this block
            // runs for every build, and debug builds need no keystore.
            signingConfig = signingConfigs.findByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Refuse to build a release without the MyNet keystore, but only when a
// release task is really going to run (so `flutter run` and debug builds
// work without key.properties).
gradle.taskGraph.whenReady {
    val releaseBuild = allTasks.any { task ->
        task.project == project &&
            task.name.endsWith("Release") &&
            (task.name.startsWith("assemble") ||
                task.name.startsWith("bundle") ||
                task.name.startsWith("package"))
    }
    if (releaseBuild && android.signingConfigs.findByName("release") == null) {
        throw GradleException(
            "Release signing requires android/app/key.properties " +
                "(storeFile, storePassword, keyAlias, keyPassword).",
        )
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

// Push: applied only when android/app/google-services.json is present
// (kept out of git). Without it the app builds and push stays off.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
