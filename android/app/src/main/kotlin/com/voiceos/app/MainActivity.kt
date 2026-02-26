package com.voiceos.app

import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.voiceos.app/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityServiceEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(null)
                    }
                    "getScreenContext" -> {
                        val context = getScreenContext()
                        result.success(context)
                    }
                    "executeAction" -> {
                        val action = call.arguments as? Map<*, *>
                        if (action != null) {
                            val success = executeAction(action)
                            result.success(success)
                        } else {
                            result.success(false)
                        }
                    }
                    "executeIntent" -> {
                        val intentData = call.arguments as? Map<*, *>
                        if (intentData != null) {
                            val success = executeIntent(intentData)
                            result.success(success)
                        } else {
                            result.success(false)
                        }
                    }
                    "getInstalledApps" -> {
                        val apps = getInstalledApps()
                        result.success(apps)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val accessibilityEnabled = try {
            Settings.Secure.getInt(
                contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: Settings.SettingNotFoundException) {
            0
        }

        if (accessibilityEnabled != 1) {
            return false
        }

        val serviceString = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(serviceString)

        val serviceName = "$packageName/.VoiceOSAccessibilityService"

        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(serviceName, ignoreCase = true) ||
                componentName.contains("VoiceOSAccessibilityService", ignoreCase = true)) {
                return true
            }
        }

        return false
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun getScreenContext(): Map<String, Any?> {
        val service = VoiceOSAccessibilityService.instance
        return if (service != null) {
            service.getScreenContent()
        } else {
            mapOf("error" to "Accessibility service not running")
        }
    }

    private fun executeAction(action: Map<*, *>): Boolean {
        val service = VoiceOSAccessibilityService.instance ?: return false
        val type = action["type"] as? String ?: return false

        return when (type) {
            "tap" -> {
                val x = (action["x"] as? Number)?.toInt() ?: return false
                val y = (action["y"] as? Number)?.toInt() ?: return false
                service.executeTap(x, y)
            }
            "tap_node" -> {
                val nodeIndex = (action["nodeIndex"] as? Number)?.toInt() ?: return false
                service.executeTapNode(nodeIndex)
            }
            "long_press" -> {
                val x = (action["x"] as? Number)?.toInt() ?: return false
                val y = (action["y"] as? Number)?.toInt() ?: return false
                service.executeLongPress(x, y)
            }
            "swipe_up" -> service.swipeUp()
            "swipe_down" -> service.swipeDown()
            "swipe_left" -> service.swipeLeft()
            "swipe_right" -> service.swipeRight()
            "set_text" -> {
                val nodeIndex = (action["nodeIndex"] as? Number)?.toInt() ?: return false
                val text = action["text"] as? String ?: return false
                service.executeSetText(nodeIndex, text)
            }
            "press_back" -> service.pressBack()
            "press_home" -> service.pressHome()
            "press_recents" -> service.pressRecents()
            "open_notifications" -> service.openNotifications()
            "open_quick_settings" -> service.openQuickSettings()
            "screenshot" -> service.takeScreenshot()
            else -> false
        }
    }

    private fun executeIntent(intentData: Map<*, *>): Boolean {
        val type = intentData["type"] as? String ?: return false

        return try {
            when (type) {
                "open_app" -> {
                    val packageName = intentData["packageName"] as? String ?: return false
                    openApp(packageName)
                }
                "search_web" -> {
                    val query = intentData["query"] as? String ?: return false
                    searchWeb(query)
                }
                "open_url" -> {
                    val url = intentData["url"] as? String ?: return false
                    openUrl(url)
                }
                else -> false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun openApp(packageName: String): Boolean {
        val intent = packageManager.getLaunchIntentForPackage(packageName) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }

    private fun searchWeb(query: String): Boolean {
        val intent = Intent(Intent.ACTION_WEB_SEARCH)
        intent.putExtra("query", query)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (e: Exception) {
            // Fallback to browser
            openUrl("https://www.google.com/search?q=$query")
        }
    }

    private fun openUrl(url: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)

        val apps = pm.queryIntentActivities(intent, 0)
        return apps.map { resolveInfo ->
            mapOf(
                "name" to resolveInfo.loadLabel(pm).toString(),
                "packageName" to resolveInfo.activityInfo.packageName
            )
        }.sortedBy { it["name"]?.lowercase() }
    }
}
