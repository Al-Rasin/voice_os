package com.voiceos.app

import android.app.SearchManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.AlarmClock
import android.provider.CalendarContract

class IntentExecutor(private val context: Context) {

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

    // Media
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
}
