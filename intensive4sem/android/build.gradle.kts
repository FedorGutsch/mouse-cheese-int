// Файл: android/build.gradle.kts
// Это правильный, современный шаблон.

plugins {
    // Определяем плагины, которые будут доступны во всем проекте.
    // Версии управляются автоматически плагином Flutter.
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
