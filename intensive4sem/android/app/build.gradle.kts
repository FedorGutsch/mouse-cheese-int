// Файл: android/app/build.gradle.kts
// Это правильный, современный шаблон.

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Плагин Flutter применяется автоматически через settings.gradle.kts
}

android {
    namespace = "com.example.quest_app"
    compileSdk = 34
    ndkVersion = "27.0.12077973" // Как требовали плагины

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.quest_app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true // Важная настройка для совместимости
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Этот блок больше не нужен, так как он обрабатывается автоматически
// flutter {
//     source = "../.."
// }

dependencies {
    // Версия Kotlin теперь управляется автоматически
    implementation(kotlin("stdlib"))
    
    // Наша зависимость для Яндекс Карт
    implementation("com.yandex.android:maps.mobile:4.6.1-full")
    
    // Наша зависимость для MultiDex
    implementation("androidx.multidex:multidex:2.0.1")
}
