import '../models/action_result.dart';
import '../platform/native_bridge.dart';
import 'app_resolver_service.dart';
import 'llm/response_parser.dart';

class ActionExecutor {
  final AppResolverService appResolver;

  ActionExecutor({required this.appResolver});

  Future<ActionResult> executeActions(
    List<ParsedAction> actions,
    Map<String, dynamic>? screenContext,
  ) async {
    if (actions.isEmpty) {
      return ActionResult.ok();
    }

    final results = <String>[];

    for (final action in actions) {
      final result = await _executeSingleAction(action, screenContext);
      results.add('${action.type}: ${result.success ? 'OK' : result.error}');

      // Small delay between sequential actions
      if (actions.length > 1) {
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    final allSuccess = results.every((r) => r.contains('OK'));
    return ActionResult.withDetails(allSuccess, results);
  }

  Future<ActionResult> _executeSingleAction(
    ParsedAction action,
    Map<String, dynamic>? screenContext,
  ) async {
    try {
      switch (action.type) {
        // --- Intent Actions ---
        case 'open_app':
          final appName = action.params['app_name'] as String?;
          if (appName == null) return ActionResult.fail('No app name');
          final packageName = appResolver.resolveAppName(appName);
          if (packageName == null) return ActionResult.fail('App not found: $appName');
          return _callIntent({'type': 'open_app', 'packageName': packageName});

        case 'search_web':
          return _callIntent({
            'type': 'search_web',
            'query': action.params['query'],
          });

        case 'make_call':
          return _callIntent({
            'type': 'make_call',
            'number': action.params['number'],
          });

        case 'send_sms':
          return _callIntent({
            'type': 'send_sms',
            'number': action.params['number'],
            'message': action.params['message'] ?? '',
          });

        case 'set_alarm':
          return _callIntent({
            'type': 'set_alarm',
            'hour': action.params['hour'],
            'minute': action.params['minute'] ?? 0,
            'message': action.params['message'] ?? 'Alarm',
          });

        case 'set_timer':
          return _callIntent({
            'type': 'set_timer',
            'seconds': action.params['seconds'],
            'message': action.params['message'] ?? 'Timer',
          });

        case 'add_calendar_event':
          final startMs = _parseIsoTime(action.params['start_time_iso'] as String?);
          final endMs = _parseIsoTime(action.params['end_time_iso'] as String?);
          if (startMs == null || endMs == null) {
            return ActionResult.fail('Invalid time format');
          }
          return _callIntent({
            'type': 'add_calendar_event',
            'title': action.params['title'],
            'description': action.params['description'] ?? '',
            'startTime': startMs,
            'endTime': endMs,
            'location': action.params['location'],
          });

        case 'set_reminder':
          final timeMs = _parseIsoTime(action.params['time_iso'] as String?);
          if (timeMs == null) return ActionResult.fail('Invalid time format');
          return _callIntent({
            'type': 'set_reminder',
            'title': action.params['title'],
            'timeInMillis': timeMs,
          });

        case 'play_youtube':
        case 'search_youtube':
          return _callIntent({
            'type': 'search_youtube',
            'query': action.params['query'],
          });

        case 'send_whatsapp':
          return _callIntent({
            'type': 'send_whatsapp',
            'phone': action.params['phone'],
            'message': action.params['message'] ?? '',
          });

        case 'compose_email':
          return _callIntent({
            'type': 'compose_email',
            'to': action.params['to'],
            'subject': action.params['subject'] ?? '',
            'body': action.params['body'] ?? '',
          });

        case 'open_maps':
          return _callIntent({
            'type': 'open_maps',
            'query': action.params['query'],
          });

        case 'navigate_to':
          return _callIntent({
            'type': 'navigate_to',
            'destination': action.params['destination'],
          });

        case 'open_url':
          return _callIntent({
            'type': 'open_url',
            'url': action.params['url'],
          });

        case 'share_text':
          return _callIntent({
            'type': 'share_text',
            'text': action.params['text'],
          });

        // --- Device Control Actions ---
        case 'toggle_flashlight':
          return _callIntent({
            'type': 'toggle_flashlight',
            'on': action.params['on'],
          });

        case 'flashlight_on':
          return _callIntent({'type': 'toggle_flashlight', 'on': true});

        case 'flashlight_off':
          return _callIntent({'type': 'toggle_flashlight', 'on': false});

        case 'set_volume':
          return _callIntent({
            'type': 'set_volume',
            'level': action.params['level'],
          });

        case 'volume_up':
          return _callIntent({'type': 'adjust_volume', 'direction': 'up'});

        case 'volume_down':
          return _callIntent({'type': 'adjust_volume', 'direction': 'down'});

        case 'volume_mute':
          return _callIntent({'type': 'adjust_volume', 'direction': 'mute'});

        case 'volume_unmute':
          return _callIntent({'type': 'adjust_volume', 'direction': 'unmute'});

        case 'volume_max':
          return _callIntent({'type': 'adjust_volume', 'direction': 'max'});

        case 'set_ringer_mode':
          return _callIntent({
            'type': 'set_ringer_mode',
            'mode': action.params['mode'],
          });

        case 'silent_mode':
          return _callIntent({'type': 'set_ringer_mode', 'mode': 'silent'});

        case 'vibrate_mode':
          return _callIntent({'type': 'set_ringer_mode', 'mode': 'vibrate'});

        case 'ring_mode':
          return _callIntent({'type': 'set_ringer_mode', 'mode': 'normal'});

        case 'dnd_on':
          return _callIntent({'type': 'set_dnd', 'enabled': true});

        case 'dnd_off':
          return _callIntent({'type': 'set_dnd', 'enabled': false});

        // --- Media Control Actions ---
        case 'media_play_pause':
        case 'play_pause':
        case 'pause':
        case 'play':
          return _callIntent({'type': 'media_play_pause'});

        case 'media_next':
        case 'next_track':
        case 'skip':
          return _callIntent({'type': 'media_next'});

        case 'media_previous':
        case 'previous_track':
          return _callIntent({'type': 'media_previous'});

        case 'media_stop':
        case 'stop_music':
          return _callIntent({'type': 'media_stop'});

        // --- Camera Actions ---
        case 'open_camera':
        case 'take_photo':
          return _callIntent({'type': 'open_camera'});

        case 'record_video':
          return _callIntent({'type': 'open_video_camera'});

        // --- Settings Actions ---
        case 'open_wifi_settings':
        case 'wifi_settings':
          return _callIntent({'type': 'open_wifi_settings'});

        case 'open_bluetooth_settings':
        case 'bluetooth_settings':
          return _callIntent({'type': 'open_bluetooth_settings'});

        case 'open_display_settings':
        case 'brightness_settings':
          return _callIntent({'type': 'open_display_settings'});

        case 'open_sound_settings':
        case 'sound_settings':
          return _callIntent({'type': 'open_sound_settings'});

        case 'open_location_settings':
        case 'location_settings':
          return _callIntent({'type': 'open_location_settings'});

        case 'open_battery_settings':
        case 'battery_settings':
          return _callIntent({'type': 'open_battery_settings'});

        case 'open_settings':
        case 'settings':
          return _callIntent({'type': 'open_settings'});

        // --- Notes ---
        case 'create_note':
          return _callIntent({
            'type': 'create_note',
            'title': action.params['title'] ?? '',
            'content': action.params['content'] ?? action.params['text'] ?? '',
          });

        // --- Accessibility Actions ---
        case 'tap':
          final resolved = _resolveElementBounds(action, screenContext);
          return _callAccessibility({
            'type': 'tap',
            'x': resolved.params['x'],
            'y': resolved.params['y'],
          });

        case 'tap_xy':
          return _callAccessibility({
            'type': 'tap',
            'x': action.params['x'],
            'y': action.params['y'],
          });

        case 'long_press':
          final resolved = _resolveElementBounds(action, screenContext);
          return _callAccessibility({
            'type': 'long_press',
            'x': resolved.params['x'],
            'y': resolved.params['y'],
          });

        case 'swipe_up':
          return _callAccessibility({'type': 'swipe_up'});
        case 'swipe_down':
          return _callAccessibility({'type': 'swipe_down'});
        case 'swipe_left':
          return _callAccessibility({'type': 'swipe_left'});
        case 'swipe_right':
          return _callAccessibility({'type': 'swipe_right'});

        case 'set_text':
          return _callAccessibility({
            'type': 'set_text',
            'nodeIndex': action.params['element'],
            'text': action.params['text'],
          });

        case 'press_back':
          return _callAccessibility({'type': 'press_back'});
        case 'press_home':
          return _callAccessibility({'type': 'press_home'});
        case 'press_recents':
          return _callAccessibility({'type': 'press_recents'});
        case 'open_notifications':
          return _callAccessibility({'type': 'open_notifications'});
        case 'open_quick_settings':
          return _callAccessibility({'type': 'open_quick_settings'});
        case 'screenshot':
          return _callAccessibility({'type': 'screenshot'});

        case 'wait':
          final ms = action.params['ms'] as int? ?? 1000;
          await Future.delayed(Duration(milliseconds: ms));
          return ActionResult.ok();

        case 'none':
          return ActionResult.ok();

        default:
          return ActionResult.fail('Unknown action: ${action.type}');
      }
    } catch (e) {
      return ActionResult.fail('Error: $e');
    }
  }

  Future<ActionResult> _callIntent(Map<String, dynamic> data) async {
    final success = await NativeBridge.executeIntent(data);
    return success ? ActionResult.ok() : ActionResult.fail('Intent failed');
  }

  Future<ActionResult> _callAccessibility(Map<String, dynamic> data) async {
    final success = await NativeBridge.executeAction(data);
    return success ? ActionResult.ok() : ActionResult.fail('Action failed');
  }

  int? _parseIsoTime(String? isoString) {
    if (isoString == null) return null;
    try {
      return DateTime.parse(isoString).millisecondsSinceEpoch;
    } catch (e) {
      return null;
    }
  }

  ParsedAction _resolveElementBounds(
      ParsedAction action, Map<String, dynamic>? screenContext) {
    if (screenContext == null || !action.params.containsKey('element')) {
      return action;
    }
    return ResponseParser.resolveElementBounds(action, screenContext);
  }
}
