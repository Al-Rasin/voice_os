import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/accessibility_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/voice_provider.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleMicTap() async {
    final voiceProvider = context.read<VoiceProvider>();

    // Check if already listening
    if (voiceProvider.isListening) {
      await voiceProvider.stopListening();
      _pulseController.stop();
      _pulseController.reset();
      return;
    }

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        _showPermissionDialog();
      }
      return;
    }

    // Start listening
    await voiceProvider.startListening();
    _pulseController.repeat(reverse: true);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text(
          'VoiceOS needs microphone access to hear your voice commands. '
          'Please grant permission in your device settings.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VoiceOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<VoiceProvider>(
          builder: (context, voiceProvider, child) {
            // Control animation based on state
            if (voiceProvider.isListening && !_pulseController.isAnimating) {
              _pulseController.repeat(reverse: true);
            } else if (!voiceProvider.isListening &&
                _pulseController.isAnimating) {
              _pulseController.stop();
              _pulseController.reset();
            }

            return Column(
              children: [
                // Status banner
                _buildStatusBanner(context),

                // Main content area
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Status text
                        Text(
                          'VoiceOS',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusText(voiceProvider),
                        const SizedBox(height: 32),

                        // Voice text area
                        _buildVoiceTextArea(voiceProvider),
                        const SizedBox(height: 48),

                        // Tap to speak hint
                        _buildHintText(voiceProvider),
                      ],
                    ),
                  ),
                ),

                // Mic button area
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: _buildMicButton(voiceProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    return Consumer2<AccessibilityProvider, SettingsProvider>(
      builder: (context, accessibilityProvider, settingsProvider, child) {
        final isEnabled = accessibilityProvider.isServiceEnabled;
        final providerName = settingsProvider.currentProvider?.name ?? 'Not set';
        final modelName = settingsProvider.currentModel?.displayName ?? '';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isEnabled ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
          child: Row(
            children: [
              Icon(
                isEnabled ? Icons.check_circle : Icons.warning,
                size: 16,
                color: isEnabled ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEnabled
                      ? 'Accessibility Active'
                      : 'Accessibility Service Required',
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              if (!isEnabled)
                TextButton(
                  onPressed: () => accessibilityProvider.openSettings(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Enable',
                    style: TextStyle(fontSize: 12),
                  ),
                )
              else
                Text(
                  '$providerName${modelName.isNotEmpty ? " • $modelName" : ""}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusText(VoiceProvider voiceProvider) {
    String statusText;
    Color statusColor;

    switch (voiceProvider.state) {
      case VoiceState.idle:
        statusText = 'Ready';
        statusColor = Colors.white54;
        break;
      case VoiceState.listening:
        statusText = 'Listening...';
        statusColor = Colors.redAccent;
        break;
      case VoiceState.processing:
        statusText = 'Thinking...';
        statusColor = AppTheme.accentColor;
        break;
      case VoiceState.success:
        statusText = 'Done';
        statusColor = Colors.green;
        break;
      case VoiceState.error:
        statusText = 'Error';
        statusColor = Colors.orange;
        break;
    }

    return Text(
      statusText,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: statusColor,
          ),
    );
  }

  Widget _buildVoiceTextArea(VoiceProvider voiceProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      constraints: const BoxConstraints(minHeight: 80),
      child: _buildVoiceText(voiceProvider),
    );
  }

  Widget _buildVoiceText(VoiceProvider voiceProvider) {
    switch (voiceProvider.state) {
      case VoiceState.idle:
        return const SizedBox.shrink();

      case VoiceState.listening:
        final text = voiceProvider.partialText.isNotEmpty
            ? voiceProvider.partialText
            : '';
        return Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        );

      case VoiceState.processing:
        return Column(
          children: [
            Text(
              voiceProvider.finalText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        );

      case VoiceState.success:
        return Column(
          children: [
            if (voiceProvider.finalText.isNotEmpty) ...[
              Text(
                voiceProvider.finalText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              voiceProvider.responseText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.accentColor,
                  ),
            ),
          ],
        );

      case VoiceState.error:
        return Text(
          voiceProvider.errorMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.orange,
              ),
        );
    }
  }

  Widget _buildHintText(VoiceProvider voiceProvider) {
    if (voiceProvider.state != VoiceState.idle) {
      return const SizedBox.shrink();
    }

    return Text(
      'Tap to speak',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white38,
          ),
    );
  }

  Widget _buildMicButton(VoiceProvider voiceProvider) {
    Color buttonColor;
    Color iconColor = Colors.white;

    switch (voiceProvider.state) {
      case VoiceState.idle:
        buttonColor = AppTheme.primaryColor;
        break;
      case VoiceState.listening:
        buttonColor = Colors.redAccent;
        break;
      case VoiceState.processing:
        buttonColor = AppTheme.accentColor;
        break;
      case VoiceState.success:
        buttonColor = Colors.green;
        break;
      case VoiceState.error:
        buttonColor = Colors.orange;
        break;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale =
            voiceProvider.isListening ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 72,
            height: 72,
            child: FloatingActionButton(
              onPressed: _handleMicTap,
              backgroundColor: buttonColor,
              child: voiceProvider.isProcessing
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      voiceProvider.isListening ? Icons.stop : Icons.mic,
                      size: 32,
                      color: iconColor,
                    ),
            ),
          ),
        );
      },
    );
  }
}
