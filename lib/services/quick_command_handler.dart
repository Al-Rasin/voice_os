import '../models/pipeline_result.dart';
import 'llm/response_parser.dart';

class QuickCommandHandler {
  PipelineResult? tryHandle(String command) {
    final lower = command.toLowerCase().trim();

    // Scroll/Swipe
    if (_matches(lower, ['scroll down', 'swipe up'])) {
      return _action('swipe_up', 'Scrolling down');
    }
    if (_matches(lower, ['scroll up', 'swipe down'])) {
      return _action('swipe_down', 'Scrolling up');
    }
    if (_matches(lower, ['swipe left', 'scroll left'])) {
      return _action('swipe_left', 'Swiping left');
    }
    if (_matches(lower, ['swipe right', 'scroll right'])) {
      return _action('swipe_right', 'Swiping right');
    }

    // Navigation
    if (_matches(lower, ['go back', 'back', 'press back'])) {
      return _action('press_back', 'Going back');
    }
    if (_matches(lower, ['go home', 'home', 'press home'])) {
      return _action('press_home', 'Going home');
    }
    if (_matches(lower, ['recent apps', 'recents', 'show recents'])) {
      return _action('press_recents', 'Showing recent apps');
    }
    if (_matches(lower, ['notifications', 'show notifications'])) {
      return _action('open_notifications', 'Opening notifications');
    }
    if (_matches(lower, ['quick settings'])) {
      return _action('open_quick_settings', 'Opening quick settings');
    }
    if (_matches(lower, ['screenshot', 'take screenshot', 'take a screenshot'])) {
      return _action('screenshot', 'Taking screenshot');
    }

    // Not a quick command
    return null;
  }

  bool _matches(String input, List<String> patterns) {
    return patterns.any((p) => input == p || input.startsWith('$p '));
  }

  PipelineResult _action(String type, String speak) {
    return PipelineResult.success(
      thought: 'Quick command: $type',
      actions: [ParsedAction(type: type, params: {})],
      speak: speak,
    );
  }
}
