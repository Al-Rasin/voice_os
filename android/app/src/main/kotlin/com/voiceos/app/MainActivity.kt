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
                    "startFloatingWidget" -> {
                        val success = startFloatingWidget()
                        result.success(success)
                    }
                    "stopFloatingWidget" -> {
                        stopFloatingWidget()
                        result.success(true)
                    }
                    "isFloatingWidgetRunning" -> {
                        result.success(FloatingWidgetService.isRunning)
                    }
                    "canDrawOverlays" -> {
                        result.success(canDrawOverlays())
                    }
                    "requestOverlayPermission" -> {
                        requestOverlayPermission()
                        result.success(null)
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
        val executor = IntentExecutor(this)

        return try {
            when (type) {
                "open_app" -> {
                    val packageName = intentData["packageName"] as? String ?: return false
                    executor.openApp(packageName)
                }
                "search_web" -> {
                    val query = intentData["query"] as? String ?: return false
                    executor.searchWeb(query)
                }
                "open_url" -> {
                    val url = intentData["url"] as? String ?: return false
                    executor.openUrl(url)
                }
                "make_call" -> {
                    val number = intentData["number"] as? String ?: return false
                    executor.makePhoneCall(number)
                }
                "dial" -> {
                    val number = intentData["number"] as? String ?: return false
                    executor.dialPhoneNumber(number)
                }
                "send_sms" -> {
                    val number = intentData["number"] as? String ?: return false
                    val message = intentData["message"] as? String ?: ""
                    executor.sendSMS(number, message)
                }
                "share_text" -> {
                    val text = intentData["text"] as? String ?: return false
                    executor.shareText(text)
                }
                "set_alarm" -> {
                    val hour = (intentData["hour"] as? Number)?.toInt() ?: return false
                    val minute = (intentData["minute"] as? Number)?.toInt() ?: 0
                    val message = intentData["message"] as? String ?: "Alarm"
                    executor.setAlarm(hour, minute, message)
                }
                "set_timer" -> {
                    val seconds = (intentData["seconds"] as? Number)?.toInt() ?: return false
                    val message = intentData["message"] as? String ?: "Timer"
                    executor.setTimer(seconds, message)
                }
                "set_reminder" -> {
                    val title = intentData["title"] as? String ?: return false
                    val timeInMillis = (intentData["timeInMillis"] as? Number)?.toLong() ?: return false
                    executor.setReminder(title, timeInMillis)
                }
                "add_calendar_event" -> {
                    val title = intentData["title"] as? String ?: return false
                    val description = intentData["description"] as? String ?: ""
                    val startTime = (intentData["startTime"] as? Number)?.toLong() ?: return false
                    val endTime = (intentData["endTime"] as? Number)?.toLong() ?: return false
                    val location = intentData["location"] as? String
                    executor.addCalendarEvent(title, description, startTime, endTime, location)
                }
                "play_youtube" -> {
                    val videoId = intentData["videoId"] as? String
                    if (videoId != null) {
                        executor.playYouTubeVideo(videoId)
                    } else {
                        val query = intentData["query"] as? String ?: return false
                        executor.searchYouTube(query)
                    }
                }
                "search_youtube" -> {
                    val query = intentData["query"] as? String ?: return false
                    executor.searchYouTube(query)
                }
                "send_whatsapp" -> {
                    val phone = intentData["phone"] as? String ?: return false
                    val message = intentData["message"] as? String ?: ""
                    executor.sendWhatsApp(phone, message)
                }
                "open_whatsapp" -> executor.openWhatsApp()
                "compose_email" -> {
                    val to = intentData["to"] as? String ?: return false
                    val subject = intentData["subject"] as? String ?: ""
                    val body = intentData["body"] as? String ?: ""
                    executor.composeEmail(to, subject, body)
                }
                "open_maps" -> {
                    val query = intentData["query"] as? String ?: return false
                    executor.openMaps(query)
                }
                "navigate_to" -> {
                    val destination = intentData["destination"] as? String ?: return false
                    executor.navigate(destination)
                }
                "open_spotify" -> {
                    val query = intentData["query"] as? String
                    executor.openSpotify(query)
                }
                else -> false
            }
        } catch (e: Exception) {
            false
        }
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

    // Floating Widget methods
    private fun canDrawOverlays(): Boolean {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                android.net.Uri.parse("package:$packageName")
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

    private fun startFloatingWidget(): Boolean {
        if (!canDrawOverlays()) return false

        val intent = Intent(this, FloatingWidgetService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        return true
    }

    private fun stopFloatingWidget() {
        val intent = Intent(this, FloatingWidgetService::class.java)
        stopService(intent)
    }
}
