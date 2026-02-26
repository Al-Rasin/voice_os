import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/air_gesture_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/wake_word_provider.dart';
import '../services/air_gesture_service.dart';

class HandsFreeScreen extends StatefulWidget {
  const HandsFreeScreen({super.key});

  @override
  State<HandsFreeScreen> createState() => _HandsFreeScreenState();
}

class _HandsFreeScreenState extends State<HandsFreeScreen> {
  final TextEditingController _wakeWordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final wakeWordProvider = context.read<WakeWordProvider>();
    _wakeWordController.text = wakeWordProvider.wakeWord;
  }

  @override
  void dispose() {
    _wakeWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hands-Free Mode'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wake Word Section
            _buildSectionHeader('Wake Word'),
            const SizedBox(height: 12),
            _buildWakeWordSection(),
            const SizedBox(height: 24),

            // Continuous Listening Section
            _buildSectionHeader('Continuous Listening'),
            const SizedBox(height: 12),
            _buildContinuousListeningSection(),
            const SizedBox(height: 24),

            // Air Gestures Section
            _buildSectionHeader('Air Gestures'),
            const SizedBox(height: 12),
            _buildAirGesturesSection(),
            const SizedBox(height: 24),

            // Air Gesture Preview (when enabled)
            Consumer<AirGestureProvider>(
              builder: (context, provider, child) {
                if (provider.isEnabled) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Camera Preview'),
                      const SizedBox(height: 12),
                      _buildCameraPreview(provider),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildWakeWordSection() {
    return Consumer<WakeWordProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Enable Wake Word'),
                  subtitle: Text(
                    provider.isEnabled
                        ? 'Listening for "${provider.wakeWord}"'
                        : 'Say your wake word to activate voice control',
                  ),
                  value: provider.isEnabled,
                  onChanged: (value) async {
                    final status = await Permission.microphone.request();
                    if (status.isGranted) {
                      if (value) {
                        await provider.enable();
                      } else {
                        await provider.disable();
                      }
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                const SizedBox(height: 8),
                TextField(
                  controller: _wakeWordController,
                  decoration: const InputDecoration(
                    labelText: 'Wake Word',
                    hintText: 'e.g., hey voice, ok assistant',
                    helperText: 'The phrase that activates voice control',
                  ),
                  onChanged: (value) {
                    provider.setWakeWord(value);
                  },
                ),
                const SizedBox(height: 16),
                if (provider.isEnabled && provider.lastHeard.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hearing, size: 16, color: Colors.white54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Heard: "${provider.lastHeard}"',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinuousListeningSection() {
    return Consumer<VoiceProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Continuous Listening'),
                  subtitle: const Text(
                    'Keep listening after each command until stopped',
                  ),
                  value: provider.isContinuousListening,
                  onChanged: (value) async {
                    if (value) {
                      final status = await Permission.microphone.request();
                      if (status.isGranted) {
                        await provider.startContinuousListening();
                      }
                    } else {
                      await provider.stopContinuousListening();
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (provider.isContinuousListening) ...[
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Continuous listening active. Say "stop listening" to disable.',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAirGesturesSection() {
    return Consumer<AirGestureProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Air Gestures'),
                  subtitle: const Text(
                    'Use hand movements to control (requires camera)',
                  ),
                  value: provider.isEnabled,
                  onChanged: (value) async {
                    final status = await Permission.camera.request();
                    if (status.isGranted) {
                      if (value) {
                        await provider.enable();
                      } else {
                        await provider.disable();
                      }
                    } else {
                      _showPermissionDialog('Camera');
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Supported Gestures:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildGestureItem(Icons.swipe_left, 'Swipe Left', 'Go back'),
                _buildGestureItem(Icons.swipe_right, 'Swipe Right', 'Open recents'),
                _buildGestureItem(Icons.swipe_up, 'Swipe Up', 'Scroll down'),
                _buildGestureItem(Icons.swipe_down, 'Swipe Down', 'Scroll up'),
                if (provider.lastGesture != null) ...[
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gesture, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Detected: ${_gestureToString(provider.lastGesture!)}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGestureItem(IconData icon, String gesture, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white54),
          const SizedBox(width: 12),
          Text(gesture, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(action, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(AirGestureProvider provider) {
    if (provider.cameraController == null ||
        !provider.cameraController!.value.isInitialized) {
      return const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Mirror the camera for natural feedback
            Transform.scale(
              scaleX: -1,
              child: CameraPreview(provider.cameraController!),
            ),
            // Overlay
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: provider.lastGesture != null
                      ? Colors.green
                      : Colors.white24,
                  width: 2,
                ),
              ),
            ),
            // Instructions
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Move your hand to control',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _gestureToString(AirGesture gesture) {
    switch (gesture) {
      case AirGesture.swipeLeft:
        return 'Swipe Left';
      case AirGesture.swipeRight:
        return 'Swipe Right';
      case AirGesture.swipeUp:
        return 'Swipe Up';
      case AirGesture.swipeDown:
        return 'Swipe Down';
      case AirGesture.tap:
        return 'Tap';
      default:
        return 'None';
    }
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          '$permission access is needed for this feature. '
          'Please grant permission in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
