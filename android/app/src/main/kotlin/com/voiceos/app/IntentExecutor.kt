package com.voiceos.app

import android.app.NotificationManager
import android.app.SearchManager
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.provider.AlarmClock
import android.provider.CalendarContract
import android.provider.MediaStore
import android.provider.Settings
import android.view.KeyEvent

class IntentExecutor(private val context: Context) {
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var flashlightOn = false

    fun openApp(packageName: String): Boolean {
        val intent = context.packageManager.getLaunchIntentForPackage(packageName) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun searchWeb(query: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_WEB_SEARCH)
            intent.putExtra(SearchManager.QUERY, query)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            // Fallback to browser
            openUrl("https://www.google.com/search?q=${Uri.encode(query)}")
        }
    }

    fun makePhoneCall(number: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            // Fallback to dial (doesn't require permission)
            dialPhoneNumber(number)
        }
    }

    fun dialPhoneNumber(number: String): Boolean {
        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number"))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun sendSMS(number: String, message: String): Boolean {
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$number"))
        intent.putExtra("sms_body", message)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun openUrl(url: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun shareText(text: String): Boolean {
        val intent = Intent(Intent.ACTION_SEND)
        intent.type = "text/plain"
        intent.putExtra(Intent.EXTRA_TEXT, text)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(Intent.createChooser(intent, "Share via").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        return true
    }

    // Alarms & Timers
    fun setAlarm(hour: Int, minute: Int, message: String): Boolean {
        val intent = Intent(AlarmClock.ACTION_SET_ALARM)
        intent.putExtra(AlarmClock.EXTRA_HOUR, hour)
        intent.putExtra(AlarmClock.EXTRA_MINUTES, minute)
        intent.putExtra(AlarmClock.EXTRA_MESSAGE, message)
        intent.putExtra(AlarmClock.EXTRA_SKIP_UI, true)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun setTimer(seconds: Int, message: String): Boolean {
        val intent = Intent(AlarmClock.ACTION_SET_TIMER)
        intent.putExtra(AlarmClock.EXTRA_LENGTH, seconds)
        intent.putExtra(AlarmClock.EXTRA_MESSAGE, message)
        intent.putExtra(AlarmClock.EXTRA_SKIP_UI, true)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun setReminder(title: String, timeInMillis: Long): Boolean {
        val intent = Intent(Intent.ACTION_INSERT)
        intent.data = CalendarContract.Events.CONTENT_URI
        intent.putExtra(CalendarContract.Events.TITLE, title)
        intent.putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, timeInMillis)
        intent.putExtra(CalendarContract.EXTRA_EVENT_END_TIME, timeInMillis + 30 * 60 * 1000)
        intent.putExtra(CalendarContract.Events.HAS_ALARM, true)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    // Calendar
    fun addCalendarEvent(title: String, description: String, startTime: Long, endTime: Long, location: String?): Boolean {
        val intent = Intent(Intent.ACTION_INSERT)
        intent.data = CalendarContract.Events.CONTENT_URI
        intent.putExtra(CalendarContract.Events.TITLE, title)
        intent.putExtra(CalendarContract.Events.DESCRIPTION, description)
        intent.putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startTime)
        intent.putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endTime)
        location?.let { intent.putExtra(CalendarContract.Events.EVENT_LOCATION, it) }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    // YouTube
    fun playYouTubeVideo(videoId: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("vnd.youtube:$videoId"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            openUrl("https://www.youtube.com/watch?v=$videoId")
        }
    }

    fun searchYouTube(query: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_SEARCH)
            intent.setPackage("com.google.android.youtube")
            intent.putExtra(SearchManager.QUERY, query)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            openUrl("https://www.youtube.com/results?search_query=${Uri.encode(query)}")
        }
    }

    // WhatsApp
    fun sendWhatsApp(phoneNumber: String, message: String): Boolean {
        val url = "https://api.whatsapp.com/send?phone=$phoneNumber&text=${Uri.encode(message)}"
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun openWhatsApp(): Boolean {
        return openApp("com.whatsapp")
    }

    // Email
    fun composeEmail(to: String, subject: String, body: String): Boolean {
        val uri = Uri.parse("mailto:$to?subject=${Uri.encode(subject)}&body=${Uri.encode(body)}")
        val intent = Intent(Intent.ACTION_SENDTO, uri)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun composeEmailMultiple(to: List<String>, subject: String, body: String): Boolean {
        val intent = Intent(Intent.ACTION_SEND)
        intent.putExtra(Intent.EXTRA_EMAIL, to.toTypedArray())
        intent.putExtra(Intent.EXTRA_SUBJECT, subject)
        intent.putExtra(Intent.EXTRA_TEXT, body)
        intent.type = "message/rfc822"
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(Intent.createChooser(intent, "Send email via").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        return true
    }

    // Maps & Navigation
    fun openMaps(query: String): Boolean {
        val uri = Uri.parse("geo:0,0?q=${Uri.encode(query)}")
        val intent = Intent(Intent.ACTION_VIEW, uri)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun navigate(destination: String): Boolean {
        val uri = Uri.parse("google.navigation:q=${Uri.encode(destination)}")
        val intent = Intent(Intent.ACTION_VIEW, uri)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    // Media Apps
    fun openSpotify(query: String?): Boolean {
        return try {
            if (query != null) {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("spotify:search:$query"))
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            } else {
                openApp("com.spotify.music")
            }
            true
        } catch (e: Exception) {
            openApp("com.spotify.music")
        }
    }

    // ==================== DEVICE CONTROL ====================

    // Flashlight
    fun toggleFlashlight(on: Boolean? = null): Boolean {
        return try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList[0]
            val newState = on ?: !flashlightOn
            cameraManager.setTorchMode(cameraId, newState)
            flashlightOn = newState
            true
        } catch (e: Exception) {
            false
        }
    }

    fun isFlashlightOn(): Boolean = flashlightOn

    // Volume Control
    fun setVolume(level: Int, streamType: Int = AudioManager.STREAM_MUSIC): Boolean {
        return try {
            val maxVolume = audioManager.getStreamMaxVolume(streamType)
            val targetVolume = (level.coerceIn(0, 100) * maxVolume / 100)
            audioManager.setStreamVolume(streamType, targetVolume, AudioManager.FLAG_SHOW_UI)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun adjustVolume(direction: String): Boolean {
        return try {
            when (direction.lowercase()) {
                "up" -> audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_RAISE, AudioManager.FLAG_SHOW_UI)
                "down" -> audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_LOWER, AudioManager.FLAG_SHOW_UI)
                "mute" -> audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_MUTE, AudioManager.FLAG_SHOW_UI)
                "unmute" -> audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_UNMUTE, AudioManager.FLAG_SHOW_UI)
                "max" -> setVolume(100)
                else -> return false
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    fun getVolume(): Int {
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        return (currentVolume * 100 / maxVolume)
    }

    // Ringer Mode
    fun setRingerMode(mode: String): Boolean {
        return try {
            val ringerMode = when (mode.lowercase()) {
                "silent" -> AudioManager.RINGER_MODE_SILENT
                "vibrate" -> AudioManager.RINGER_MODE_VIBRATE
                "normal", "ring" -> AudioManager.RINGER_MODE_NORMAL
                else -> return false
            }
            audioManager.ringerMode = ringerMode
            true
        } catch (e: Exception) {
            false
        }
    }

    // Do Not Disturb
    fun setDoNotDisturb(enabled: Boolean): Boolean {
        return try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!notificationManager.isNotificationPolicyAccessGranted) {
                    // Open settings to grant DND access
                    val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    return false
                }
                val filter = if (enabled) NotificationManager.INTERRUPTION_FILTER_NONE else NotificationManager.INTERRUPTION_FILTER_ALL
                notificationManager.setInterruptionFilter(filter)
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    // Battery Info
    fun getBatteryLevel(): Int {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    fun isBatteryCharging(): Boolean {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.isCharging
    }

    // Media Playback Control
    fun mediaPlayPause(): Boolean {
        return sendMediaKeyEvent(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
    }

    fun mediaNext(): Boolean {
        return sendMediaKeyEvent(KeyEvent.KEYCODE_MEDIA_NEXT)
    }

    fun mediaPrevious(): Boolean {
        return sendMediaKeyEvent(KeyEvent.KEYCODE_MEDIA_PREVIOUS)
    }

    fun mediaStop(): Boolean {
        return sendMediaKeyEvent(KeyEvent.KEYCODE_MEDIA_STOP)
    }

    private fun sendMediaKeyEvent(keyCode: Int): Boolean {
        return try {
            val downEvent = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
            val upEvent = KeyEvent(KeyEvent.ACTION_UP, keyCode)
            audioManager.dispatchMediaKeyEvent(downEvent)
            audioManager.dispatchMediaKeyEvent(upEvent)
            true
        } catch (e: Exception) {
            false
        }
    }

    // Camera
    fun openCamera(): Boolean {
        return try {
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun openVideoCamera(): Boolean {
        return try {
            val intent = Intent(MediaStore.ACTION_VIDEO_CAPTURE)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    // Settings Pages
    fun openWifiSettings(): Boolean {
        val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun openBluetoothSettings(): Boolean {
        val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun openDisplaySettings(): Boolean {
        val intent = Intent(Settings.ACTION_DISPLAY_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun openSoundSettings(): Boolean {
        val intent = Intent(Settings.ACTION_SOUND_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun openLocationSettings(): Boolean {
        val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun openAppSettings(): Boolean {
        val intent = Intent(Settings.ACTION_APPLICATION_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun openBatterySettings(): Boolean {
        val intent = Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    fun openAllSettings(): Boolean {
        val intent = Intent(Settings.ACTION_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    // Notes/Memo
    fun createNote(title: String, content: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_SEND)
            intent.type = "text/plain"
            intent.putExtra(Intent.EXTRA_SUBJECT, title)
            intent.putExtra(Intent.EXTRA_TEXT, content)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(Intent.createChooser(intent, "Save note to").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (e: Exception) {
            false
        }
    }
}
