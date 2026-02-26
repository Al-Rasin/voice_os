import 'package:flutter/services.dart';
import '../config/constants.dart';

class NativeBridge {
  static const MethodChannel _channel =
      MethodChannel(AppConstants.platformChannelName);

  /// Check if AccessibilityService is enabled
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open Android Accessibility Settings
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get current screen context from AccessibilityService
  static Future<Map<String, dynamic>> getScreenContext() async {
    try {
      final result = await _channel.invokeMethod('getScreenContext');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      // Return error context
    }
    return {'error': 'Failed to get screen context'};
  }

  /// Execute an accessibility action (tap, swipe, etc.)
  static Future<bool> executeAction(Map<String, dynamic> action) async {
    try {
      final result =
          await _channel.invokeMethod<bool>('executeAction', action);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Execute an Android intent (open app, set alarm, etc.)
  static Future<bool> executeIntent(Map<String, dynamic> intentData) async {
    try {
      final result =
          await _channel.invokeMethod<bool>('executeIntent', intentData);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get list of installed apps
  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      if (result != null) {
        return List<Map<String, String>>.from(
          (result as List).map((e) => Map<String, String>.from(e)),
        );
      }
    } catch (e) {
      // Return empty list
    }
    return [];
  }

  /// Check if overlay permission is granted
  static Future<bool> canDrawOverlays() async {
    try {
      final result = await _channel.invokeMethod<bool>('canDrawOverlays');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request overlay permission
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Start floating widget service
  static Future<bool> startFloatingWidget() async {
    try {
      final result = await _channel.invokeMethod<bool>('startFloatingWidget');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stop floating widget service
  static Future<void> stopFloatingWidget() async {
    try {
      await _channel.invokeMethod('stopFloatingWidget');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Check if floating widget is running
  static Future<bool> isFloatingWidgetRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isFloatingWidgetRunning');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
