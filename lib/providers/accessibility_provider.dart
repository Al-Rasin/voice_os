import 'package:flutter/widgets.dart';
import '../platform/native_bridge.dart';

class AccessibilityProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isServiceEnabled = false;
  bool _isChecking = false;

  bool get isServiceEnabled => _isServiceEnabled;
  bool get isChecking => _isChecking;

  AccessibilityProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> init() async {
    await checkServiceStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check when app comes back to foreground
      checkServiceStatus();
    }
  }

  Future<void> checkServiceStatus() async {
    if (_isChecking) return;

    _isChecking = true;
    notifyListeners();

    try {
      _isServiceEnabled = await NativeBridge.isAccessibilityServiceEnabled();
    } catch (e) {
      _isServiceEnabled = false;
    }

    _isChecking = false;
    notifyListeners();
  }

  Future<void> openSettings() async {
    await NativeBridge.openAccessibilitySettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
