// Файл: android/settings.gradle.kts
// Это правильный, современный шаблон.

// Определяем корень Flutter-проекта относительно этого файла
val flutterProjectRoot = settings.rootDir.parentFile

// Функция для применения плагинов из Flutter SDK
fun applyPlugins(project: org.gradle.api.Project) {
    project.apply(from = flutterProjectRoot.resolve("packages/flutter_tools/gradle/app_plugin_loader.gradle"))
}

// Включаем наш модуль :app
include(":app")

// Применяем плагины к модулю :app
applyPlugins(project(":app"))

// Настраиваем, где Gradle будет искать плагины
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
