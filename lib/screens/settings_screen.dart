import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/llm_provider.dart';
import '../platform/native_bridge.dart';
import '../providers/settings_provider.dart';
import '../services/llm/llm_client_factory.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  bool _obscureApiKey = true;
  bool _hasUnsavedChanges = false;
  bool _isTesting = false;
  bool _floatingWidgetEnabled = false;
  bool _canDrawOverlays = false;

  // Local state for editing
  late String _selectedProviderId;
  late String _selectedModelId;
  late bool _speakResponses;
  late double _speechRate;
  late bool _vibrateOnCommand;
  late double _temperature;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _loadCurrentSettings();
    _checkFloatingWidgetStatus();
  }

  Future<void> _checkFloatingWidgetStatus() async {
    final canDraw = await NativeBridge.canDrawOverlays();
    final isRunning = await NativeBridge.isFloatingWidgetRunning();
    setState(() {
      _canDrawOverlays = canDraw;
      _floatingWidgetEnabled = isRunning;
    });
  }

  void _loadCurrentSettings() {
    final settings = context.read<SettingsProvider>().settings;
    _selectedProviderId = settings.selectedProviderId;
    _selectedModelId = settings.selectedModelId;
    _apiKeyController.text = settings.apiKey;
    _speakResponses = settings.speakResponses;
    _speechRate = settings.speechRate;
    _vibrateOnCommand = settings.vibrateOnCommand;
    _temperature = settings.temperature;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  List<LLMModel> get _currentModels {
    final provider = LLMProvider.getById(_selectedProviderId);
    return provider?.models ?? [];
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveSettings() async {
    final settingsProvider = context.read<SettingsProvider>();

    await settingsProvider.updateSettings(
      settingsProvider.settings.copyWith(
        selectedProviderId: _selectedProviderId,
        selectedModelId: _selectedModelId,
        apiKey: _apiKeyController.text,
        speakResponses: _speakResponses,
        speechRate: _speechRate,
        vibrateOnCommand: _vibrateOnCommand,
        temperature: _temperature,
      ),
    );

    setState(() {
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an API key first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final testSettings = AppSettings(
        selectedProviderId: _selectedProviderId,
        selectedModelId: _selectedModelId,
        apiKey: _apiKeyController.text,
      );

      final client = LLMClientFactory.createClient(testSettings);
      final response = await client.sendMessage(
        systemPrompt: 'You are a helpful assistant.',
        userMessage: 'Respond with only: Connection successful',
        temperature: 0.0,
        maxTokens: 50,
      );

      if (mounted) {
        if (response.success) {
          _showConnectionDialog(
            success: true,
            message: 'Connection successful!\n\nResponse: ${response.rawText}',
          );
        } else {
          _showConnectionDialog(
            success: false,
            message: 'Connection failed:\n\n${response.error}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showConnectionDialog(
          success: false,
          message: 'Error: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  void _showConnectionDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          success ? Icons.check_circle : Icons.error,
          color: success ? Colors.green : Colors.red,
          size: 48,
        ),
        title: Text(success ? 'Success' : 'Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: AI Provider
            _buildSectionHeader('AI Provider'),
            const SizedBox(height: 12),
            _buildProviderSelector(),
            const SizedBox(height: 16),
            _buildModelDropdown(),
            const SizedBox(height: 24),

            // Section 2: API Key
            _buildSectionHeader('API Key'),
            const SizedBox(height: 12),
            _buildApiKeyField(),
            const SizedBox(height: 24),

            // Section 3: Voice Settings
            _buildSectionHeader('Voice Settings'),
            const SizedBox(height: 12),
            _buildVoiceSettings(),
            const SizedBox(height: 24),

            // Section 4: Advanced
            _buildSectionHeader('Advanced'),
            const SizedBox(height: 12),
            _buildAdvancedSettings(),
            const SizedBox(height: 24),

            // Section 5: Floating Widget
            _buildSectionHeader('Floating Widget'),
            const SizedBox(height: 12),
            _buildFloatingWidgetSettings(),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Save', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
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

  Widget _buildProviderSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: LLMProvider.providers.map((provider) {
            final isSelected = _selectedProviderId == provider.id;
            return ListTile(
              leading: Icon(
                _getIconForProvider(provider.iconName),
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white54,
              ),
              title: Text(
                provider.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              selected: isSelected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                setState(() {
                  _selectedProviderId = provider.id;
                  // Reset model to first option when provider changes
                  _selectedModelId = provider.models.isNotEmpty
                      ? provider.models.first.id
                      : '';
                });
                _markChanged();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getIconForProvider(String iconName) {
    switch (iconName) {
      case 'psychology':
        return Icons.psychology;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'star':
        return Icons.star;
      case 'bolt':
        return Icons.bolt;
      case 'search':
        return Icons.search;
      case 'public':
        return Icons.public;
      default:
        return Icons.smart_toy;
    }
  }

  Widget _buildModelDropdown() {
    final models = _currentModels;
    if (models.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No models available for this provider'),
        ),
      );
    }

    // Ensure selected model is valid
    if (!models.any((m) => m.id == _selectedModelId)) {
      _selectedModelId = models.first.id;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedModelId,
          decoration: const InputDecoration(
            labelText: 'Model',
            border: InputBorder.none,
          ),
          items: models.map((model) {
            return DropdownMenuItem(
              value: model.id,
              child: Text(model.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedModelId = value;
              });
              _markChanged();
            }
          },
        ),
      ),
    );
  }

  Widget _buildApiKeyField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              onChanged: (_) => _markChanged(),
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your API key',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your API key is stored securely on device',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Speak responses aloud'),
              value: _speakResponses,
              onChanged: (value) {
                setState(() {
                  _speakResponses = value;
                });
                _markChanged();
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Speech rate'),
                    Text(
                      _speechRate.toStringAsFixed(1),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _speechRate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) {
                    setState(() {
                      _speechRate = value;
                    });
                    _markChanged();
                  },
                ),
              ],
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Vibrate on command'),
              value: _vibrateOnCommand,
              onChanged: (value) {
                setState(() {
                  _vibrateOnCommand = value;
                });
                _markChanged();
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('AI Temperature'),
                    Text(
                      _temperature.toStringAsFixed(1),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _temperature,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) {
                    setState(() {
                      _temperature = value;
                    });
                    _markChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingWidgetSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable floating button'),
              subtitle: const Text('Show a floating mic button on screen'),
              value: _floatingWidgetEnabled,
              onChanged: _canDrawOverlays
                  ? (value) async {
                      if (value) {
                        final success = await NativeBridge.startFloatingWidget();
                        setState(() {
                          _floatingWidgetEnabled = success;
                        });
                      } else {
                        await NativeBridge.stopFloatingWidget();
                        setState(() {
                          _floatingWidgetEnabled = false;
                        });
                      }
                    }
                  : null,
              contentPadding: EdgeInsets.zero,
            ),
            if (!_canDrawOverlays) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Overlay permission required',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await NativeBridge.requestOverlayPermission();
                      // Check again after returning
                      Future.delayed(const Duration(seconds: 1), () {
                        _checkFloatingWidgetStatus();
                      });
                    },
                    child: const Text('Grant'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
