// ⚠️ ESTE BLOCO DE CONFIGURAÇÃO DEVE FICAR NO TOPO DO ARQUIVO!
// Ele força a definição do namespace para o pacote 'uni_links' (versão 0.5.1),
// resolvendo o erro de "Namespace not specified" no Gradle moderno.
subprojects {
    afterEvaluate {
        // O nome do módulo do pacote é 'uni_links'
        if (name == "uni_links") {
            // Configura a extensão 'android' do tipo LibraryExtension
            project.extensions.configure(com.android.build.api.dsl.LibraryExtension::class) {
                // Define o namespace esperado
                namespace = "plugins.flutter.io.uni_links"
            }
        }
    }
}
// ----------------------------------------------------------------------

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
    namespace = "com.example.app_salao_pro"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.app_salao_pro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
