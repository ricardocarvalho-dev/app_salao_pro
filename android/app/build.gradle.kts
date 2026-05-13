import java.util.Properties
import java.io.FileInputStream

// ⚠️ BLOCO PARA CORREÇÃO DO UNI_LINKS
subprojects {
    afterEvaluate {
        if (name == "uni_links") {
            project.extensions.configure(com.android.build.api.dsl.LibraryExtension::class) {
                namespace = "plugins.flutter.io.uni_links"
            }
        }
    }
}

// Carregar as propriedades da chave de assinatura
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.projectDir.resolve("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Ajustado para o novo namespace
    namespace = "com.salaopro.sistema" 
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.salaopro.sistema"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Agora usando a assinatura oficial em vez da 'debug'
            signingConfig = signingConfigs.getByName("release")
            
            // Ative estas opções se quiser otimizar o app (opcional)
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}