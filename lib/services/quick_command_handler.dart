import 'package:intl/intl.dart';
import '../models/pipeline_result.dart';
import '../platform/native_bridge.dart';
import 'llm/response_parser.dart';

class QuickCommandHandler {
  PipelineResult? tryHandle(String command) {
    final lower = command.toLowerCase().trim();

    // ==================== NAVIGATION ====================
    // Scroll/Swipe
    if (_matches(lower, ['scroll down', 'swipe up', 'page down'])) {
      return _action('swipe_up', 'Scrolling down');
    }
    if (_matches(lower, ['scroll up', 'swipe down', 'page up'])) {
      return _action('swipe_down', 'Scrolling up');
    }
    if (_matches(lower, ['swipe left', 'scroll left'])) {
      return _action('swipe_left', 'Swiping left');
    }
    if (_matches(lower, ['swipe right', 'scroll right'])) {
      return _action('swipe_right', 'Swiping right');
    }

    // Navigation
    if (_matches(lower, ['go back', 'back', 'press back', 'go backward'])) {
      return _action('press_back', 'Going back');
    }
    if (_matches(lower, ['go home', 'home', 'press home', 'home screen'])) {
      return _action('press_home', 'Going home');
    }
    if (_matches(lower, ['recent apps', 'recents', 'show recents', 'recent', 'switch app', 'switch apps'])) {
      return _action('press_recents', 'Showing recent apps');
    }
    if (_matches(lower, ['notifications', 'show notifications', 'open notifications'])) {
      return _action('open_notifications', 'Opening notifications');
    }
    if (_matches(lower, ['quick settings', 'open quick settings'])) {
      return _action('open_quick_settings', 'Opening quick settings');
    }
    if (_matches(lower, ['screenshot', 'take screenshot', 'take a screenshot', 'capture screen'])) {
      return _action('screenshot', 'Taking screenshot');
    }

    // ==================== DEVICE CONTROL ====================
    // Flashlight
    if (_matches(lower, ['flashlight on', 'turn on flashlight', 'torch on', 'turn on torch', 'light on'])) {
      return _action('flashlight_on', 'Flashlight on');
    }
    if (_matches(lower, ['flashlight off', 'turn off flashlight', 'torch off', 'turn off torch', 'light off'])) {
      return _action('flashlight_off', 'Flashlight off');
    }
    if (_matches(lower, ['flashlight', 'toggle flashlight', 'torch'])) {
      return _action('toggle_flashlight', 'Toggling flashlight');
    }

    // Volume
    if (_matches(lower, ['volume up', 'increase volume', 'louder', 'turn up volume'])) {
      return _action('volume_up', 'Volume up');
    }
    if (_matches(lower, ['volume down', 'decrease volume', 'quieter', 'turn down volume'])) {
      return _action('volume_down', 'Volume down');
    }
    if (_matches(lower, ['mute', 'mute volume', 'volume mute'])) {
      return _action('volume_mute', 'Muted');
    }
    if (_matches(lower, ['unmute', 'unmute volume'])) {
      return _action('volume_unmute', 'Unmuted');
    }
    if (_matches(lower, ['max volume', 'volume max', 'full volume'])) {
      return _action('volume_max', 'Volume set to maximum');
    }

    // Ringer Mode
    if (_matches(lower, ['silent mode', 'go silent', 'silence phone', 'silent'])) {
      return _action('silent_mode', 'Silent mode enabled');
    }
    if (_matches(lower, ['vibrate mode', 'vibrate only', 'vibration mode'])) {
      return _action('vibrate_mode', 'Vibrate mode enabled');
    }
    if (_matches(lower, ['ring mode', 'normal mode', 'sound on', 'ringer on'])) {
      return _action('ring_mode', 'Ringer mode enabled');
    }

    // Do Not Disturb
    if (_matches(lower, ['do not disturb on', 'dnd on', 'enable do not disturb', 'turn on do not disturb'])) {
      return _action('dnd_on', 'Do not disturb enabled');
    }
    if (_matches(lower, ['do not disturb off', 'dnd off', 'disable do not disturb', 'turn off do not disturb'])) {
      return _action('dnd_off', 'Do not disturb disabled');
    }

    // ==================== MEDIA CONTROL ====================
    if (_matches(lower, ['pause', 'pause music', 'pause video', 'stop playing'])) {
      return _action('media_play_pause', 'Paused');
    }
    if (_matches(lower, ['play', 'resume', 'resume music', 'continue playing'])) {
      return _action('media_play_pause', 'Playing');
    }
    if (_matches(lower, ['next', 'next song', 'next track', 'skip', 'skip song'])) {
      return _action('media_next', 'Next track');
    }
    if (_matches(lower, ['previous', 'previous song', 'previous track', 'go back song'])) {
      return _action('media_previous', 'Previous track');
    }
    if (_matches(lower, ['stop music', 'stop playing music'])) {
      return _action('media_stop', 'Music stopped');
    }

    // ==================== CAMERA ====================
    if (_matches(lower, ['open camera', 'camera', 'take photo', 'take a photo', 'take picture'])) {
      return _action('open_camera', 'Opening camera');
    }
    if (_matches(lower, ['record video', 'video camera', 'start recording'])) {
      return _action('record_video', 'Opening video camera');
    }

    // ==================== SETTINGS ====================
    if (_matches(lower, ['wifi settings', 'open wifi', 'wifi'])) {
      return _action('open_wifi_settings', 'Opening WiFi settings');
    }
    if (_matches(lower, ['bluetooth settings', 'open bluetooth', 'bluetooth'])) {
      return _action('open_bluetooth_settings', 'Opening Bluetooth settings');
    }
    if (_matches(lower, ['brightness settings', 'display settings'])) {
      return _action('open_display_settings', 'Opening display settings');
    }
    if (_matches(lower, ['sound settings', 'audio settings'])) {
      return _action('open_sound_settings', 'Opening sound settings');
    }
    if (_matches(lower, ['location settings', 'gps settings'])) {
      return _action('open_location_settings', 'Opening location settings');
    }
    if (_matches(lower, ['battery settings'])) {
      return _action('open_battery_settings', 'Opening battery settings');
    }
    if (_matches(lower, ['settings', 'open settings', 'phone settings'])) {
      return _action('open_settings', 'Opening settings');
    }

    // ==================== INFO QUERIES (no LLM needed) ====================
    // Time
    if (_matches(lower, ['what time is it', 'what\'s the time', 'time', 'current time', 'tell me the time'])) {
      final now = DateTime.now();
      final timeStr = DateFormat('h:mm a').format(now);
      return _info('The time is $timeStr');
    }

    // Date
    if (_matches(lower, ['what\'s the date', 'what date is it', 'today\'s date', 'date', 'what day is it'])) {
      final now = DateTime.now();
      final dateStr = DateFormat('EEEE, MMMM d, y').format(now);
      return _info('Today is $dateStr');
    }

    // Battery (async - handled specially)
    if (_matches(lower, ['battery', 'battery level', 'how much battery', 'battery status', 'battery percentage'])) {
      return _asyncBatteryQuery();
    }

    // ==================== VOICE CONTROL ====================
    if (_matches(lower, ['stop listening', 'stop', 'cancel', 'never mind', 'nevermind'])) {
      return _info('Stopped');
    }

    if (_matches(lower, ['thank you', 'thanks'])) {
      return _info("You're welcome!");
    }

    if (_matches(lower, ['hello', 'hi', 'hey'])) {
      return _info('Hello! How can I help you?');
    }

    // Not a quick command
    return null;
  }

  bool _matches(String input, List<String> patterns) {
    for (final p in patterns) {
      if (input == p || input.startsWith('$p ') || input.endsWith(' $p') || input.contains(' $p ')) {
        return true;
      }
    }
    return false;
  }

  PipelineResult _action(String type, String speak) {
    return PipelineResult.success(
      thought: 'Quick command: $type',
      actions: [ParsedAction(type: type, params: {})],
      speak: speak,
    );
  }

  PipelineResult _info(String speak) {
    return PipelineResult.success(
      thought: 'Info query',
      actions: [ParsedAction(type: 'none', params: {})],
      speak: speak,
    );
  }

  PipelineResult _asyncBatteryQuery() {
    // This will be executed synchronously but we return a placeholder
    // The actual battery info needs to be fetched async
    return PipelineResult.success(
      thought: 'Battery query - fetching...',
      actions: [ParsedAction(type: 'none', params: {})],
      speak: 'Checking battery...',
    );
  }
}
