import 'package:flutter/foundation.dart';
import '../models/action_result.dart';
import '../models/app_settings.dart';
import '../models/pipeline_result.dart';
import '../services/action_executor.dart';
import '../services/app_resolver_service.dart';
import '../services/command_pipeline.dart';
import '../services/llm/response_parser.dart';

class CommandProvider extends ChangeNotifier {
  final AppResolverService _appResolver = AppResolverService();
  late final CommandPipeline _pipeline;
  late final ActionExecutor _executor;

  bool _isProcessing = false;
  PipelineResult? _lastResult;
  ActionResult? _lastActionResult;
  List<CommandHistoryItem> _history = [];

  bool get isProcessing => _isProcessing;
  PipelineResult? get lastResult => _lastResult;
  ActionResult? get lastActionResult => _lastActionResult;
  List<CommandHistoryItem> get history => _history;

  CommandProvider() {
    _pipeline = CommandPipeline(appResolver: _appResolver);
    _executor = ActionExecutor(appResolver: _appResolver);
  }

  Future<void> init() async {
    await _appResolver.refresh();
  }

  Future<String> processVoiceCommand(String text, AppSettings settings) async {
    _isProcessing = true;
    _lastResult = null;
    _lastActionResult = null;
    notifyListeners();

    try {
      // Process through pipeline
      _lastResult = await _pipeline.processCommand(text, settings);
      notifyListeners();

      if (!_lastResult!.success) {
        _addToHistory(text, _lastResult!.error ?? 'Error', false);
        return _lastResult!.error ?? 'Error processing command';
      }

      // Execute actions
      if (_lastResult!.actions != null && _lastResult!.actions!.isNotEmpty) {
        _lastActionResult = await _executor.executeActions(
          _lastResult!.actions!,
          _pipeline.lastScreenContext,
        );
      }

      // Add to history
      final actionDesc = _getActionDescription(_lastResult!);
      _addToHistory(text, actionDesc, _lastActionResult?.success ?? true);

      return _lastResult!.speak ?? 'Done';
    } catch (e) {
      _addToHistory(text, 'Error: $e', false);
      return 'Error: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  String _getActionDescription(PipelineResult result) {
    if (result.actions == null || result.actions!.isEmpty) {
      return result.speak ?? 'No action';
    }

    final actions = result.actions!;
    if (actions.length == 1) {
      return _describeAction(actions.first);
    }
    return '${actions.length} actions executed';
  }

  String _describeAction(ParsedAction action) {
    switch (action.type) {
      case 'open_app':
        return 'Opened ${action.params['app_name'] ?? 'app'}';
      case 'search_web':
        return 'Searched: ${action.params['query'] ?? ''}';
      case 'search_youtube':
      case 'play_youtube':
        return 'YouTube: ${action.params['query'] ?? ''}';
      case 'set_alarm':
        final hour = action.params['hour'] ?? 0;
        final minute = action.params['minute']?.toString().padLeft(2, '0') ?? '00';
        return 'Set alarm for $hour:$minute';
      case 'set_timer':
        final seconds = action.params['seconds'] as int? ?? 0;
        return 'Set timer for ${seconds ~/ 60} min';
      case 'swipe_up':
        return 'Scrolled down';
      case 'swipe_down':
        return 'Scrolled up';
      case 'press_back':
        return 'Pressed back';
      case 'press_home':
        return 'Pressed home';
      case 'press_recents':
        return 'Opened recents';
      case 'flashlight_on':
        return 'Flashlight on';
      case 'flashlight_off':
        return 'Flashlight off';
      case 'toggle_flashlight':
        return 'Toggled flashlight';
      case 'volume_up':
        return 'Volume up';
      case 'volume_down':
        return 'Volume down';
      case 'volume_mute':
        return 'Muted';
      case 'volume_unmute':
        return 'Unmuted';
      case 'volume_max':
        return 'Volume max';
      case 'silent_mode':
        return 'Silent mode';
      case 'vibrate_mode':
        return 'Vibrate mode';
      case 'ring_mode':
        return 'Ring mode';
      case 'dnd_on':
        return 'Do not disturb on';
      case 'dnd_off':
        return 'Do not disturb off';
      case 'media_play_pause':
      case 'play_pause':
        return 'Play/Pause';
      case 'media_next':
      case 'next_track':
        return 'Next track';
      case 'media_previous':
      case 'previous_track':
        return 'Previous track';
      case 'media_stop':
        return 'Stopped media';
      case 'open_camera':
        return 'Opened camera';
      case 'record_video':
        return 'Recording video';
      case 'open_wifi_settings':
        return 'WiFi settings';
      case 'open_bluetooth_settings':
        return 'Bluetooth settings';
      case 'open_settings':
        return 'Opened settings';
      case 'screenshot':
        return 'Screenshot taken';
      case 'none':
        return 'Responded';
      default:
        return action.type.replaceAll('_', ' ');
    }
  }

  void _addToHistory(String command, String result, bool success) {
    _history.insert(
      0,
      CommandHistoryItem(
        command: command,
        result: result,
        success: success,
        timestamp: DateTime.now(),
      ),
    );

    // Keep only last 50 items
    if (_history.length > 50) {
      _history = _history.sublist(0, 50);
    }
  }

  void clearHistory() {
    _history.clear();
    _pipeline.clearHistory();
    notifyListeners();
  }
}

class CommandHistoryItem {
  final String command;
  final String result;
  final bool success;
  final DateTime timestamp;

  CommandHistoryItem({
    required this.command,
    required this.result,
    required this.success,
    required this.timestamp,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }
}
