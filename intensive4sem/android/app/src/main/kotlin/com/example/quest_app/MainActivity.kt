package com.example.quest_app

import io.flutter.embedding.android.FlutterFragmentActivity // <-- ИЗМЕНЕНИЕ 1
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import com.yandex.mapkit.MapKitFactory // <-- ИЗМЕНЕНИЕ 2

class MainActivity: FlutterFragmentActivity() { // <-- ИЗМЕНЕНИЕ 3
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // MapKitFactory.setLocale("YOUR_LOCALE") // Необязательно, но полезно
        MapKitFactory.setApiKey("ВАШ_API_КЛЮЧ_ЗДЕСЬ") // <-- ИЗМЕНЕНИЕ 4
        super.configureFlutterEngine(flutterEngine)
    }
}
