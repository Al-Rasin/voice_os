import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/accessibility_provider.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.mic,
      title: 'Voice Control',
      description:
          'Control your entire phone with your voice. Just tap the mic and speak naturally.',
      color: AppTheme.primaryColor,
    ),
    OnboardingPage(
      icon: Icons.psychology,
      title: 'AI Powered',
      description:
          'Powered by advanced AI that understands context and executes complex commands.',
      color: AppTheme.accentColor,
    ),
    OnboardingPage(
      icon: Icons.accessibility_new,
      title: 'Accessibility Service',
      description:
          'VoiceOS needs accessibility permission to read screen content and perform actions.',
      color: Colors.teal,
      isAccessibilityPage: true,
    ),
    OnboardingPage(
      icon: Icons.key,
      title: 'API Key Setup',
      description:
          'Connect your preferred AI provider. Your API key is stored securely on device.',
      color: Colors.deepOrange,
      isApiKeyPage: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await SettingsService.setOnboardingComplete(true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Skip'),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDot(index),
              ),
            ),
            const SizedBox(height: 32),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _currentPage > 0
                      ? TextButton.icon(
                          onPressed: _previousPage,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        )
                      : const SizedBox(width: 100),

                  // Next/Finish button
                  ElevatedButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? _completeOnboarding
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Special content for accessibility page
          if (page.isAccessibilityPage) _buildAccessibilitySection(),

          // Special content for API key page
          if (page.isApiKeyPage) _buildApiKeySection(),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySection() {
    return Consumer<AccessibilityProvider>(
      builder: (context, provider, child) {
        final isEnabled = provider.isServiceEnabled;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isEnabled
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEnabled ? Icons.check_circle : Icons.warning,
                    color: isEnabled ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEnabled ? 'Service Enabled' : 'Service Not Enabled',
                    style: TextStyle(
                      color: isEnabled ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!isEnabled)
              OutlinedButton.icon(
                onPressed: () => provider.openSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Enable Accessibility Service'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildApiKeySection() {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        final hasKey = provider.hasApiKey;
        final providerName = provider.currentProvider?.name ?? 'Not set';

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasKey
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasKey ? Icons.check_circle : Icons.key_off,
                    color: hasKey ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasKey ? 'Connected to $providerName' : 'No API Key Set',
                    style: TextStyle(
                      color: hasKey ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: Text(hasKey ? 'Change Settings' : 'Configure API Key'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppTheme.primaryColor
            : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isAccessibilityPage;
  final bool isApiKeyPage;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isAccessibilityPage = false,
    this.isApiKeyPage = false,
  });
}
