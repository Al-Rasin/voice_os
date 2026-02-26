import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Selected provider
  String _selectedProvider = 'openai';
  String _selectedModel = 'gpt-4o';

  // API Key
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;

  // Voice settings
  bool _speakResponses = true;
  double _speechRate = 1.0;
  bool _vibrateOnCommand = true;

  // Advanced
  double _temperature = 0.3;

  // Provider options
  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'openai',
      'name': 'OpenAI',
      'icon': Icons.psychology,
      'models': ['gpt-4o', 'gpt-4o-mini'],
    },
    {
      'id': 'anthropic',
      'name': 'Anthropic Claude',
      'icon': Icons.auto_awesome,
      'models': ['claude-sonnet-4-20250514', 'claude-haiku-4-5-20251001'],
    },
    {
      'id': 'gemini',
      'name': 'Google Gemini',
      'icon': Icons.star,
      'models': ['gemini-2.0-flash', 'gemini-2.5-pro'],
    },
    {
      'id': 'groq',
      'name': 'Groq',
      'icon': Icons.bolt,
      'models': ['llama-3.3-70b-versatile', 'mixtral-8x7b-32768'],
    },
    {
      'id': 'deepseek',
      'name': 'DeepSeek',
      'icon': Icons.search,
      'models': ['deepseek-chat'],
    },
    {
      'id': 'openrouter',
      'name': 'OpenRouter',
      'icon': Icons.public,
      'models': [
        'anthropic/claude-sonnet-4',
        'google/gemini-2.0-flash-001',
        'meta-llama/llama-3.3-70b-instruct'
      ],
    },
  ];

  List<String> get _currentModels {
    final provider = _providers.firstWhere(
      (p) => p['id'] == _selectedProvider,
      orElse: () => _providers.first,
    );
    return List<String>.from(provider['models']);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
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
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Save settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved')),
                  );
                },
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
          children: _providers.map((provider) {
            final isSelected = _selectedProvider == provider['id'];
            return ListTile(
              leading: Icon(
                provider['icon'] as IconData,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white54,
              ),
              title: Text(
                provider['name'] as String,
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
                  _selectedProvider = provider['id'] as String;
                  // Reset model to first option when provider changes
                  final models = List<String>.from(provider['models']);
                  _selectedModel = models.first;
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildModelDropdown() {
    final models = _currentModels;
    if (!models.contains(_selectedModel)) {
      _selectedModel = models.first;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedModel,
          decoration: const InputDecoration(
            labelText: 'Model',
            border: InputBorder.none,
          ),
          items: models.map((model) {
            return DropdownMenuItem(
              value: model,
              child: Text(model),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedModel = value;
              });
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
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Test connection
                },
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Test Connection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
