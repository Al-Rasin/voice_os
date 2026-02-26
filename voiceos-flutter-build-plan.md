# VoiceOS — Universal Voice Control Android App (Flutter)
## Complete Build Plan for Claude Code

> **What this app does:** A personal Android app that lets you control your entire phone using voice commands. It uses Android's AccessibilityService (via platform channels) to tap, swipe, type, open apps — and Android Intents to set reminders, add calendar events, play YouTube videos, send WhatsApp messages, compose emails, make calls, and more. Powered by your choice of LLM (Claude, GPT, Gemini, etc.).

---

## HOW THE APP WORKS (Architecture Overview)

```
┌──────────────────────────────────────────────────────┐
│                    FLUTTER UI LAYER                   │
│  Main Screen │ Settings │ History │ Onboarding        │
├──────────────────────────────────────────────────────┤
│               VOICE COMMAND PIPELINE                  │
│  Voice Input → Screen Context → LLM → Parse → Execute│
├──────────────────────────────────────────────────────┤
│             PLATFORM CHANNELS (Dart ↔ Kotlin)         │
├──────────────┬──────────────┬────────────────────────┤
│ Accessibility│   Android    │    Android Intents      │
│   Service    │   System     │  (Calendar, Alarm,      │
│ (tap, swipe, │   APIs       │   YouTube, WhatsApp,    │
│  read screen)│ (volume,wifi)│   Email, Phone, Maps)   │
└──────────────┴──────────────┴────────────────────────┘
```

**Two types of actions the app can do:**

1. **Intent-based actions (fast, reliable, no screen reading needed):**
   - Set alarm/reminder → `android.intent.action.SET_ALARM`
   - Add calendar event → `android.intent.action.INSERT` to Calendar
   - Play YouTube video → YouTube app intent or `vnd.youtube:` URI
   - Send WhatsApp message → WhatsApp direct message intent
   - Compose email → `android.intent.action.SENDTO` mailto intent
   - Make phone call → `android.intent.action.CALL`
   - Open Google Maps → `geo:` or `google.navigation:` intent
   - Send SMS → `android.intent.action.SENDTO` sms intent
   - Open any app → Launch intent from PackageManager
   - Web search → Chrome or browser intent
   - Play music → Media intent to Spotify/YT Music
   - Set timer → `android.intent.action.SET_TIMER`

2. **AccessibilityService actions (for everything else):**
   - Tap any button on any screen
   - Swipe/scroll in any direction
   - Type text into any field
   - Read what's on screen (messages, posts, content)
   - Navigate within any app
   - Like, comment, share on social media
   - Read WhatsApp messages (by reading screen nodes)
   - Any interaction a human finger can do

---

## PHASE 1: Flutter Project Setup

**Goal:** Create a working Flutter project with proper structure and dependencies.

```
Create a new Flutter project with the following specs:
- Project name: voice_os
- Package name: com.voiceos.app
- Min Android SDK: 28 (Android 9)
- Target Android SDK: 34
- Platforms: Android only (no iOS, no web, no desktop)
- State management: Provider
- Use Material Design 3

Create the following folder structure:
lib/
├── main.dart
├── app.dart (MaterialApp with theme setup)
├── config/
│   ├── theme.dart (Dark and Light themes, Material 3)
│   └── constants.dart (App-wide constants)
├── models/
│   └── (empty for now — data classes will go here)
├── providers/
│   └── (empty for now — state management)
├── screens/
│   └── home_screen.dart
├── services/
│   └── (empty for now — business logic)
├── widgets/
│   └── (empty for now — reusable widgets)
└── platform/
    └── (empty for now — platform channel code)

Add these dependencies to pubspec.yaml:
- provider: ^6.1.2 (state management)
- shared_preferences: ^2.3.0 (local storage)
- flutter_secure_storage: ^9.2.0 (encrypted API key storage)
- http: ^1.2.0 (HTTP client for LLM APIs)
- speech_to_text: ^6.6.0 (voice recognition)
- flutter_tts: ^4.0.0 (text-to-speech)
- permission_handler: ^11.3.0 (runtime permissions)
- uuid: ^4.4.0 (unique IDs)
- intl: ^0.19.0 (date formatting)

In android/app/build.gradle, set:
- minSdkVersion 28
- targetSdkVersion 34
- compileSdkVersion 34

Create home_screen.dart with:
- A centered text "VoiceOS" with a subtitle "Ready"
- A large circular FloatingActionButton with a mic icon at the bottom center
- An AppBar with a settings gear icon (does nothing yet)
- Use dark theme as default

Create app.dart with MaterialApp setup:
- Material 3 enabled
- Dark theme with a deep purple/blue accent color
- ThemeMode.dark as default

Make sure `flutter run` works successfully and shows the home screen.
```

---

## PHASE 2A: Settings Screen — UI Only

**Goal:** Build the settings screen layout without any logic.

```
Create the Settings screen UI:

1. Create lib/screens/settings_screen.dart with a Scaffold and these sections:

   Section 1 — "AI Provider":
   - A dropdown/card selector showing provider options:
     - OpenAI (icon: brain)
     - Anthropic Claude (icon: sparkle)
     - Google Gemini (icon: star)
     - Groq (icon: bolt/lightning)
     - DeepSeek (icon: search)
     - OpenRouter (icon: globe)
   - When a provider is tapped/selected, it should visually highlight
   - Below the provider selector, show a second dropdown for "Model" with placeholder options

   Section 2 — "API Key":
   - A TextField with obscured text (password style)
   - A visibility toggle icon button (eye/eye-off)
   - Helper text: "Your API key is stored securely on device"

   Section 3 — "Voice Settings":
   - Toggle: "Speak responses aloud" (default: on)
   - Slider: "Speech rate" (0.5 to 2.0, default 1.0)
   - Toggle: "Vibrate on command" (default: on)

   Section 4 — "Advanced":
   - Slider: "AI Temperature" (0.0 to 1.0, default 0.3, show value)
   - A "Test Connection" button (outlined style, does nothing yet)

   Bottom: A "Save" ElevatedButton (does nothing yet)

2. Navigate to SettingsScreen from the gear icon on HomeScreen.

3. Style everything with Material 3 — use Cards for sections, proper spacing (16dp padding), section headers as bold text.

No logic or data persistence yet — just the UI layout. Make sure it looks clean and professional.
```

---

## PHASE 2B: Settings Screen — Data & Logic

**Goal:** Add data persistence to the settings screen.

```
Add data models and persistence for settings:

1. Create lib/models/llm_provider.dart:
   ```dart
   class LLMProvider with id, name, iconName, baseUrl, and a list of available models (each model has id and displayName).
   
   Define all providers as static constants:
   - OpenAI: models = [gpt-4o, gpt-4o-mini]
     baseUrl = https://api.openai.com/v1/chat/completions
   - Anthropic: models = [claude-sonnet-4-20250514, claude-haiku-4-5-20251001]
     baseUrl = https://api.anthropic.com/v1/messages
   - Google Gemini: models = [gemini-2.0-flash, gemini-2.5-pro]
     baseUrl = https://generativelanguage.googleapis.com/v1beta/
   - Groq: models = [llama-3.3-70b-versatile, mixtral-8x7b-32768]
     baseUrl = https://api.groq.com/openai/v1/chat/completions
   - DeepSeek: models = [deepseek-chat]
     baseUrl = https://api.deepseek.com/v1/chat/completions
   - OpenRouter: models = [anthropic/claude-sonnet-4, google/gemini-2.0-flash-001, meta-llama/llama-3.3-70b-instruct]
     baseUrl = https://openrouter.ai/api/v1/chat/completions
   ```

2. Create lib/models/app_settings.dart:
   ```dart
   class AppSettings with fields:
   - selectedProviderId: String
   - selectedModelId: String
   - apiKey: String
   - speakResponses: bool (default true)
   - speechRate: double (default 1.0)
   - vibrateOnCommand: bool (default true)
   - temperature: double (default 0.3)
   ```

3. Create lib/services/settings_service.dart:
   - Save/load all settings using shared_preferences
   - API key specifically saved using flutter_secure_storage
   - Methods: saveSettings(AppSettings), loadSettings() → AppSettings
   - Handle first-run defaults

4. Create lib/providers/settings_provider.dart:
   - ChangeNotifier that holds AppSettings
   - Load on init, save on change
   - Expose getters for current provider, model, apiKey, etc.

5. Wire SettingsScreen to use SettingsProvider:
   - Dropdowns reflect and update the provider state
   - When provider changes, model dropdown updates to show that provider's models
   - API key field saves securely
   - All toggles and sliders connected to state
   - Save button persists everything and shows a SnackBar "Settings saved"
   
6. Register SettingsProvider in main.dart using MultiProvider.

Test: Change settings, close app, reopen — settings should persist.
```

---

## PHASE 3A: LLM Client — Interface & OpenAI-Compatible Clients

**Goal:** Build the LLM API client for OpenAI and all OpenAI-compatible providers.

```
Build the LLM HTTP client layer (OpenAI-compatible providers first):

1. Create lib/models/chat_message.dart:
   ```dart
   class ChatMessage {
     final String role; // "system", "user", "assistant"
     final String content;
   }
   ```

2. Create lib/models/llm_response.dart:
   ```dart
   class LLMResponse {
     final String rawText;
     final bool success;
     final String? error;
   }
   ```

3. Create lib/services/llm/llm_client.dart — abstract class:
   ```dart
   abstract class LLMClient {
     Future<LLMResponse> sendMessage({
       required String systemPrompt,
       required String userMessage,
       List<ChatMessage> history = const [],
       double temperature = 0.3,
       int maxTokens = 1024,
     });
   }
   ```

4. Create lib/services/llm/openai_compatible_client.dart:
   - Implements LLMClient
   - Works for OpenAI, Groq, DeepSeek, and OpenRouter (all use the same API format)
   - Constructor takes: baseUrl, apiKey, model, optional extra headers
   - POST request body:
     {
       "model": model,
       "messages": [{"role": "system", "content": systemPrompt}, ...history, {"role": "user", "content": userMessage}],
       "temperature": temperature,
       "max_tokens": maxTokens
     }
   - Headers: Authorization: Bearer {apiKey}, Content-Type: application/json
   - For OpenRouter: add HTTP-Referer: "com.voiceos.app" and X-Title: "VoiceOS"
   - Parse response: extract choices[0].message.content
   - Handle errors: non-200 status, timeout (30s), network errors, JSON parse errors
   - Return LLMResponse with success/error

5. Test: Add a temporary "Test LLM" button on HomeScreen. When pressed:
   - Load settings to get provider/key/model
   - Create OpenAI-compatible client
   - Send: systemPrompt="You are a helpful assistant", userMessage="Say hello in exactly 5 words"
   - Show response in a dialog
   - Test with at least one provider (Groq is free tier friendly for testing)
```

---

## PHASE 3B: LLM Client — Anthropic & Gemini Clients

**Goal:** Add the non-OpenAI-format clients.

```
Add Anthropic and Gemini clients:

1. Create lib/services/llm/anthropic_client.dart:
   - Implements LLMClient
   - POST to https://api.anthropic.com/v1/messages
   - Headers:
     - x-api-key: {apiKey}
     - anthropic-version: 2023-06-01
     - Content-Type: application/json
   - Request body:
     {
       "model": model,
       "max_tokens": maxTokens,
       "system": systemPrompt,
       "messages": [...history, {"role": "user", "content": userMessage}]
     }
   - Parse response: extract content[0].text
   - Handle errors same as OpenAI client

2. Create lib/services/llm/gemini_client.dart:
   - Implements LLMClient
   - POST to https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}
   - Request body:
     {
       "system_instruction": {"parts": [{"text": systemPrompt}]},
       "contents": [
         ...history mapped to {"role": "user"/"model", "parts": [{"text": content}]},
         {"role": "user", "parts": [{"text": userMessage}]}
       ],
       "generationConfig": {"temperature": temperature, "maxOutputTokens": maxTokens}
     }
   - Note: Gemini uses "model" instead of "assistant" for the role
   - Parse response: extract candidates[0].content.parts[0].text
   - Handle errors

3. Create lib/services/llm/llm_client_factory.dart:
   - Factory method that takes AppSettings and returns the correct LLMClient:
     - OpenAI → OpenAICompatibleClient(baseUrl: openai url, ...)
     - Anthropic → AnthropicClient(...)
     - Gemini → GeminiClient(...)
     - Groq → OpenAICompatibleClient(baseUrl: groq url, ...)
     - DeepSeek → OpenAICompatibleClient(baseUrl: deepseek url, ...)
     - OpenRouter → OpenAICompatibleClient(baseUrl: openrouter url, extraHeaders: {...})

4. Wire the "Test Connection" button in SettingsScreen:
   - Use LLMClientFactory to create client from current settings
   - Send a test message: "Respond with only: Connection successful"
   - Show result in a dialog (green check for success, red X for error with error message)
   - Show loading indicator while testing

5. Update the temp test button on HomeScreen to use LLMClientFactory.

Test with at least 2 different providers to verify the factory works correctly.
```

---

## PHASE 4A: Voice Input — Speech to Text

**Goal:** Capture voice and convert to text.

```
Build the voice input system:

1. Create lib/services/voice_input_service.dart:
   - Uses the speech_to_text package
   - Methods:
     - Future<bool> initialize() — initialize speech recognition, check availability
     - Future<void> startListening({
         required Function(String) onResult,
         required Function(String) onPartialResult,
         required Function() onListeningStarted,
         required Function() onListeningStopped,
         required Function(String) onError,
       })
     - Future<void> stopListening()
     - bool get isListening
   - Configure with:
     - listenMode: ListenMode.dictation (for longer phrases)
     - pauseFor: 3 seconds (auto-stop after 3s silence)
     - listenFor: 30 seconds (max listen duration)
     - partialResults: true

2. Create lib/services/tts_service.dart:
   - Uses flutter_tts package
   - Methods:
     - Future<void> initialize()
     - Future<void> speak(String text)
     - Future<void> stop()
     - void setSpeechRate(double rate)
   - Default language: en-US
   - Load speech rate from settings

3. Create lib/providers/voice_provider.dart (ChangeNotifier):
   - Fields: isListening, partialText, finalText, isProcessing, responseText
   - Methods:
     - startListening() — triggers voice input
     - stopListening() — stops voice input
   - On final result: set finalText, set isProcessing = true
   - On error: set error state

4. Add RECORD_AUDIO permission:
   - In android/app/src/main/AndroidManifest.xml add: <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   - In HomeScreen, request permission on first mic tap using permission_handler
   - If denied, show explanation dialog with button to open app settings

5. Update HomeScreen UI:
   - Mic button: When tapped, call voiceProvider.startListening()
   - While listening: mic button turns red, shows pulse animation (use AnimatedContainer or AnimationController with a scale/glow effect)
   - Show partialText in real-time above the mic button (updating as user speaks)
   - When speech ends: show finalText, show a CircularProgressIndicator below (for future LLM processing)
   - If error: show error text briefly, then reset

Test: Tap mic, speak "open Chrome", verify the text appears correctly on screen.
```

---

## PHASE 4B: Voice Input — Text-to-Speech & Feedback

**Goal:** Add spoken responses and haptic feedback.

```
Complete the voice feedback loop:

1. Wire TTS into the app:
   - Initialize TTSService in main.dart
   - Load speech rate from SettingsProvider
   - When settings change speech rate, update TTS
   - Create a provider or add to existing VoiceProvider: speakResponse(String text)

2. Add haptic feedback:
   - When listening starts: short vibration (HapticFeedback.mediumImpact)
   - When command recognized: light vibration (HapticFeedback.lightImpact)
   - When action complete: success vibration pattern
   - Respect the "vibrate on command" setting

3. Update the mic button animation:
   - Idle state: normal mic icon, subtle glow
   - Listening state: red color, pulsing scale animation (1.0 → 1.15 → 1.0, repeating)
   - Processing state: blue color, rotating circular progress around the button
   - Success state: briefly green, then back to idle
   - Error state: briefly orange, then back to idle
   - Use AnimationController for smooth transitions

4. Add a status text widget below the mic that shows:
   - Idle: "Tap to speak"
   - Listening: "Listening..."
   - Shows partial text as user speaks
   - Processing: "Thinking..."
   - Response: shows the LLM's spoken response text
   - Auto-fade response after 5 seconds back to "Tap to speak"

5. Test the full voice → display → TTS flow:
   - Tap mic → speak → see text appear → hear TTS say the recognized text back
   (We'll replace the TTS echo with actual LLM responses in later phases)
```

---

## PHASE 5A: Platform Channel — Basic Setup

**Goal:** Create the bridge between Flutter (Dart) and native Android (Kotlin).

```
Set up the platform channel for Flutter ↔ Android native communication:

1. Create the Dart side — lib/platform/native_bridge.dart:
   ```dart
   class NativeBridge {
     static const MethodChannel _channel = MethodChannel('com.voiceos.app/native');
     
     // Check if AccessibilityService is enabled
     static Future<bool> isAccessibilityServiceEnabled() async {
       return await _channel.invokeMethod('isAccessibilityServiceEnabled');
     }
     
     // Open Android Accessibility Settings
     static Future<void> openAccessibilitySettings() async {
       await _channel.invokeMethod('openAccessibilitySettings');
     }
     
     // Placeholder methods for future phases:
     static Future<Map<String, dynamic>> getScreenContext() async {
       final result = await _channel.invokeMethod('getScreenContext');
       return Map<String, dynamic>.from(result);
     }
     
     static Future<bool> executeAction(Map<String, dynamic> action) async {
       return await _channel.invokeMethod('executeAction', action);
     }
     
     static Future<bool> executeIntent(Map<String, dynamic> intentData) async {
       return await _channel.invokeMethod('executeIntent', intentData);
     }
     
     static Future<List<Map<String, String>>> getInstalledApps() async {
       final result = await _channel.invokeMethod('getInstalledApps');
       return List<Map<String, String>>.from(result.map((e) => Map<String, String>.from(e)));
     }
   }
   ```

2. Create the Kotlin side — edit android/app/src/main/kotlin/com/voiceos/app/MainActivity.kt:
   - Set up MethodChannel("com.voiceos.app/native") in configureFlutterEngine
   - Implement handlers for:
     - "isAccessibilityServiceEnabled" → check if the VoiceOS accessibility service is in Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
     - "openAccessibilitySettings" → startActivity with Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
     - "getInstalledApps" → query PackageManager for all launchable apps, return list of {name, packageName}
   - Other methods return placeholder responses for now

3. Create lib/providers/accessibility_provider.dart (ChangeNotifier):
   - bool isServiceEnabled
   - Method: checkServiceStatus() — calls NativeBridge.isAccessibilityServiceEnabled()
   - Method: openSettings() — calls NativeBridge.openAccessibilitySettings()
   - Check status on init and on app resume (use WidgetsBindingObserver)

4. Update HomeScreen:
   - Add a status banner at the top:
     - If service enabled: green bar "Accessibility Service Active ✓"
     - If service disabled: red/orange bar "Accessibility Service Required" with a "Enable" button
     - Tapping "Enable" opens Android accessibility settings
   - Also show current LLM provider name and model in the status area

5. Register AccessibilityProvider in main.dart MultiProvider.

Test: Run the app. Status should show "service not enabled". Tap enable, it should open Android settings. (The actual service doesn't exist yet — we'll build it next.)
```

---

## PHASE 5B: AccessibilityService — Create the Service

**Goal:** Create the Android AccessibilityService in Kotlin that can read the screen.

```
Create the AccessibilityService on the native Android side:

1. Create the file android/app/src/main/kotlin/com/voiceos/app/VoiceOSAccessibilityService.kt:
   
   ```kotlin
   class VoiceOSAccessibilityService : AccessibilityService() {
       
       companion object {
           var instance: VoiceOSAccessibilityService? = null
           var isRunning: Boolean = false
       }
       
       override fun onServiceConnected() {
           super.onServiceConnected()
           instance = this
           isRunning = true
       }
       
       override fun onAccessibilityEvent(event: AccessibilityEvent?) {
           // We'll use this later for real-time screen monitoring
           // For now, just store the current package name
           event?.packageName?.let { currentPackageName = it.toString() }
       }
       
       override fun onInterrupt() {}
       
       override fun onDestroy() {
           super.onDestroy()
           instance = null
           isRunning = false
       }
       
       private var currentPackageName: String = ""
       
       // Method to get all screen nodes as a structured map
       fun getScreenContent(): Map<String, Any?> {
           val root = rootInActiveWindow ?: return mapOf("error" to "No window available")
           val nodes = mutableListOf<Map<String, Any?>>()
           traverseNode(root, nodes, 0)
           root.recycle()
           return mapOf(
               "packageName" to currentPackageName,
               "nodes" to nodes
           )
       }
       
       private fun traverseNode(node: AccessibilityNodeInfo, nodes: MutableList<Map<String, Any?>>, depth: Int) {
           // Only include interactive or text-bearing nodes to keep data small
           val isInteractive = node.isClickable || node.isScrollable || node.isEditable || node.isFocused
           val hasText = !node.text.isNullOrBlank() || !node.contentDescription.isNullOrBlank()
           
           if (isInteractive || hasText) {
               val rect = android.graphics.Rect()
               node.getBoundsInScreen(rect)
               nodes.add(mapOf(
                   "index" to nodes.size,
                   "className" to (node.className?.toString() ?: ""),
                   "text" to (node.text?.toString()?.take(100) ?: ""),
                   "contentDescription" to (node.contentDescription?.toString()?.take(100) ?: ""),
                   "viewId" to (node.viewIdResourceName ?: ""),
                   "bounds" to mapOf("left" to rect.left, "top" to rect.top, "right" to rect.right, "bottom" to rect.bottom),
                   "isClickable" to node.isClickable,
                   "isScrollable" to node.isScrollable,
                   "isEditable" to node.isEditable,
                   "isFocused" to node.isFocused,
                   "isChecked" to node.isChecked,
                   "isEnabled" to node.isEnabled,
                   "isSelected" to node.isSelected,
                   "depth" to depth
               ))
           }
           
           // Traverse children
           for (i in 0 until node.childCount) {
               val child = node.getChild(i) ?: continue
               traverseNode(child, nodes, depth + 1)
               child.recycle()
           }
       }
   }
   ```

2. Create android/app/src/main/res/xml/accessibility_service_config.xml:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
       android:description="@string/accessibility_service_description"
       android:accessibilityEventTypes="typeAllMask"
       android:accessibilityFeedbackType="feedbackGeneric"
       android:canRetrieveWindowContent="true"
       android:canPerformGestures="true"
       android:accessibilityFlags="flagReportViewIds|flagRequestFilterKeyEvents|flagIncludeNotImportantViews"
       android:notificationTimeout="100"
       android:settingsActivity="com.voiceos.app.MainActivity" />
   ```

3. Add to android/app/src/main/res/values/strings.xml:
   ```xml
   <string name="accessibility_service_description">VoiceOS uses this service to read screen content and perform actions like tapping, swiping, and typing on your behalf based on your voice commands.</string>
   ```

4. Register the service in AndroidManifest.xml inside <application>:
   ```xml
   <service
       android:name=".VoiceOSAccessibilityService"
       android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
       android:exported="false">
       <intent-filter>
           <action android:name="android.accessibilityservice.AccessibilityService" />
       </intent-filter>
       <meta-data
           android:name="android.accessibilityservice"
           android:resource="@xml/accessibility_service_config" />
   </service>
   ```

5. Update the "isAccessibilityServiceEnabled" handler in MainActivity.kt to properly check if VoiceOSAccessibilityService is in the enabled services list.

6. Update the "getScreenContext" handler in MainActivity.kt:
   - Check if VoiceOSAccessibilityService.instance is not null
   - Call instance.getScreenContent() and return the result to Flutter

Test:
- Run app → go to settings → enable VoiceOS accessibility service
- Return to app → status banner should show green "Active"
- Add a temporary debug button that calls NativeBridge.getScreenContext() and prints the result to a dialog or logs
- Navigate to different apps and verify screen nodes are being read
```

---

## PHASE 5C: AccessibilityService — Gesture Execution

**Goal:** Make the AccessibilityService able to perform taps, swipes, and gestures.

```
Add gesture/action execution to VoiceOSAccessibilityService:

1. Add these methods to VoiceOSAccessibilityService.kt:

   a) fun executeTap(x: Int, y: Int): Boolean
      - Create a GestureDescription with a single Path
      - Path: moveTo(x, y), duration 50ms
      - dispatchGesture() and return success/failure via callback

   b) fun executeLongPress(x: Int, y: Int): Boolean
      - Same as tap but duration 1000ms

   c) fun executeSwipe(startX: Int, startY: Int, endX: Int, endY: Int, duration: Long = 300): Boolean
      - Create Path from (startX, startY) to (endX, endY) with given duration
      - dispatchGesture()

   d) Convenience swipe methods using screen dimensions:
      - fun swipeUp(): Boolean — from (centerX, 70% height) to (centerX, 30% height)
      - fun swipeDown(): Boolean — from (centerX, 30% height) to (centerX, 70% height)
      - fun swipeLeft(): Boolean — from (80% width, centerY) to (20% width, centerY)
      - fun swipeRight(): Boolean — from (20% width, centerY) to (80% width, centerY)
      - Get screen dimensions from Resources.displayMetrics

   e) fun executeSetText(nodeIndex: Int, text: String): Boolean
      - Find the node by index from last getScreenContent() call (cache the nodes)
      - Use node.performAction(ACTION_SET_TEXT, Bundle with ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE)

   f) fun executeTapNode(nodeIndex: Int): Boolean
      - Find node by index from cached nodes
      - Get bounds center, then execute tap at that point
      - Or use node.performAction(ACTION_CLICK) if the node supports it

   g) Global actions:
      - fun pressBack(): Boolean → performGlobalAction(GLOBAL_ACTION_BACK)
      - fun pressHome(): Boolean → performGlobalAction(GLOBAL_ACTION_HOME)
      - fun pressRecents(): Boolean → performGlobalAction(GLOBAL_ACTION_RECENTS)
      - fun openNotifications(): Boolean → performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)
      - fun openQuickSettings(): Boolean → performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
      - fun takeScreenshot(): Boolean → performGlobalAction(GLOBAL_ACTION_TAKE_SCREENSHOT) (API 28+)

2. Update the "executeAction" handler in MainActivity.kt:
   - Receive action map from Flutter with "type" and parameters
   - Route to the appropriate VoiceOSAccessibilityService method:
     - "tap" → executeTap(x, y)
     - "tap_node" → executeTapNode(nodeIndex)
     - "long_press" → executeLongPress(x, y)
     - "swipe_up" → swipeUp()
     - "swipe_down" → swipeDown()
     - "swipe_left" → swipeLeft()
     - "swipe_right" → swipeRight()
     - "set_text" → executeSetText(nodeIndex, text)
     - "press_back" → pressBack()
     - "press_home" → pressHome()
     - "press_recents" → pressRecents()
     - "open_notifications" → openNotifications()
     - "open_quick_settings" → openQuickSettings()
     - "screenshot" → takeScreenshot()
   - Return true/false for success

3. Update NativeBridge.executeAction() in Flutter to call these properly.

4. Create a Debug/Test screen in Flutter (lib/screens/debug_screen.dart):
   - Grid of buttons, each testing one action:
     - "Tap Center" → tap(screenWidth/2, screenHeight/2)
     - "Swipe Up" → swipeUp()
     - "Swipe Down" → swipeDown()
     - "Swipe Left" → swipeLeft()
     - "Swipe Right" → swipeRight()
     - "Press Back" → pressBack()
     - "Press Home" → pressHome()
     - "Notifications" → openNotifications()
     - "Screenshot" → takeScreenshot()
     - "Read Screen" → getScreenContext() and display in a bottom sheet
   - Add a link to this debug screen from Settings (for development use)

Test each action thoroughly:
- Open a scrollable app (like Chrome or Instagram)
- Test swipe up/down — content should scroll
- Test tap — should register touches
- Test press back — should navigate back
- Test read screen — should show current UI elements
```

---

## PHASE 6A: Android Intent Actions — App Launching & Basic Intents

**Goal:** Add intent-based actions that don't need AccessibilityService.

```
Build the Android Intent action system:

1. Create android/app/src/main/kotlin/com/voiceos/app/IntentExecutor.kt:

   This class handles all Intent-based actions. These are MORE RELIABLE than
   AccessibilityService for specific tasks because they use Android's built-in
   intent system.

   a) fun openApp(packageName: String): Boolean
      - Get launch intent from packageManager.getLaunchIntentForPackage()
      - If null, return false (app not installed)
      - startActivity(intent) with FLAG_ACTIVITY_NEW_TASK
   
   b) fun searchWeb(query: String): Boolean
      - Intent(Intent.ACTION_WEB_SEARCH) with SearchManager.QUERY = query
      - Or fallback: open Chrome with URL "https://www.google.com/search?q={query}"
   
   c) fun makePhoneCall(number: String): Boolean
      - Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
      - Requires CALL_PHONE permission — add to manifest
   
   d) fun sendSMS(number: String, message: String): Boolean
      - Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$number"))
      - putExtra("sms_body", message)
   
   e) fun openUrl(url: String): Boolean
      - Intent(Intent.ACTION_VIEW, Uri.parse(url))
   
   f) fun shareText(text: String): Boolean
      - Intent(Intent.ACTION_SEND) with EXTRA_TEXT = text, type "text/plain"
      - startActivity(Intent.createChooser(...))

2. Update the "executeIntent" handler in MainActivity.kt:
   - Receive intent data map from Flutter with "type" and parameters
   - Route to IntentExecutor methods:
     - "open_app" → openApp(packageName)
     - "search_web" → searchWeb(query)
     - "make_call" → makePhoneCall(number)
     - "send_sms" → sendSMS(number, message)
     - "open_url" → openUrl(url)
     - "share_text" → shareText(text)
   - Return success/failure

3. Update the "getInstalledApps" handler:
   - Query PackageManager for all apps with CATEGORY_LAUNCHER
   - Return list of maps: [{name: "Chrome", packageName: "com.android.chrome"}, ...]
   - Sort alphabetically by name

4. Create lib/services/app_resolver_service.dart in Flutter:
   - On init, call NativeBridge.getInstalledApps() and cache the list
   - Method: resolveAppName(String spokenName) → String? packageName
   - Use fuzzy matching: "Insta" → "Instagram", "YT" → "YouTube", "Chrome" → "Chrome"
   - Normalize both strings to lowercase, check contains/startsWith
   - Also maintain a hardcoded alias map for common nicknames:
     {"insta": "instagram", "yt": "youtube", "wp": "whatsapp", "fb": "facebook", "tg": "telegram", "gm": "gmail"}

5. Add to Debug screen: buttons for "Open Chrome", "Search 'Flutter tutorial'", "Share text"

Test: Verify each intent action works correctly.
```

---

## PHASE 6B: Android Intent Actions — Calendar, Alarms, YouTube, WhatsApp, Email

**Goal:** Add intent actions for calendar events, reminders, YouTube, WhatsApp, and email.

```
Add advanced intent actions to IntentExecutor.kt:

1. ALARMS & TIMERS:
   
   a) fun setAlarm(hour: Int, minute: Int, message: String): Boolean
      - Intent(AlarmClock.ACTION_SET_ALARM)
      - putExtra(AlarmClock.EXTRA_HOUR, hour)
      - putExtra(AlarmClock.EXTRA_MINUTES, minute)
      - putExtra(AlarmClock.EXTRA_MESSAGE, message)
      - putExtra(AlarmClock.EXTRA_SKIP_UI, true) — set silently
      - Requires SET_ALARM permission in manifest
   
   b) fun setTimer(seconds: Int, message: String): Boolean
      - Intent(AlarmClock.ACTION_SET_TIMER)
      - putExtra(AlarmClock.EXTRA_LENGTH, seconds)
      - putExtra(AlarmClock.EXTRA_MESSAGE, message)
      - putExtra(AlarmClock.EXTRA_SKIP_UI, true)
   
   c) fun setReminder(title: String, timeInMillis: Long): Boolean
      - This creates a calendar event as a reminder
      - Intent(Intent.ACTION_INSERT).setData(CalendarContract.Events.CONTENT_URI)
      - putExtra(CalendarContract.Events.TITLE, title)
      - putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, timeInMillis)
      - putExtra(CalendarContract.EXTRA_EVENT_END_TIME, timeInMillis + 30*60*1000) // 30min
      - putExtra(CalendarContract.Events.HAS_ALARM, true)

2. CALENDAR EVENTS:
   
   a) fun addCalendarEvent(title: String, description: String, startTime: Long, endTime: Long, location: String?): Boolean
      - Intent(Intent.ACTION_INSERT).setData(CalendarContract.Events.CONTENT_URI)
      - putExtra(CalendarContract.Events.TITLE, title)
      - putExtra(CalendarContract.Events.DESCRIPTION, description)
      - putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startTime)
      - putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endTime)
      - if location != null: putExtra(CalendarContract.Events.EVENT_LOCATION, location)
      - Add READ_CALENDAR and WRITE_CALENDAR permissions to manifest

3. YOUTUBE:
   
   a) fun playYouTubeVideo(videoId: String): Boolean
      - Intent(Intent.ACTION_VIEW, Uri.parse("vnd.youtube:$videoId"))
      - Fallback: open "https://www.youtube.com/watch?v=$videoId" in browser
   
   b) fun searchYouTube(query: String): Boolean
      - Intent(Intent.ACTION_SEARCH).setPackage("com.google.android.youtube")
      - putExtra(SearchManager.QUERY, query)
      - Fallback: open "https://www.youtube.com/results?search_query={query}" in browser

4. WHATSAPP:
   
   a) fun sendWhatsApp(phoneNumber: String, message: String): Boolean
      - Intent(Intent.ACTION_VIEW)
      - Uri: "https://api.whatsapp.com/send?phone=$phoneNumber&text=${Uri.encode(message)}"
      - This opens WhatsApp to that contact with the message pre-filled
   
   b) fun openWhatsAppChat(contactName: String): Boolean
      - This is tricky with intents alone — we'll use AccessibilityService for this
      - For now: just open WhatsApp → Intent for com.whatsapp/.Main
      - The LLM + AccessibilityService will navigate to the right chat

5. EMAIL:
   
   a) fun composeEmail(to: String, subject: String, body: String): Boolean
      - Intent(Intent.ACTION_SENDTO)
      - Uri: "mailto:$to?subject=${Uri.encode(subject)}&body=${Uri.encode(body)}"
      - This opens Gmail or default email app with fields pre-filled
   
   b) fun composeEmailMultiple(to: List<String>, subject: String, body: String): Boolean
      - Intent(Intent.ACTION_SEND)
      - putExtra(Intent.EXTRA_EMAIL, to.toTypedArray())
      - putExtra(Intent.EXTRA_SUBJECT, subject)
      - putExtra(Intent.EXTRA_TEXT, body)
      - type = "message/rfc822"

6. MAPS & NAVIGATION:
   
   a) fun openMaps(query: String): Boolean
      - Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q=${Uri.encode(query)}"))
   
   b) fun navigate(destination: String): Boolean
      - Intent(Intent.ACTION_VIEW, Uri.parse("google.navigation:q=${Uri.encode(destination)}"))

7. MEDIA:
   
   a) fun openSpotify(query: String?): Boolean
      - If query: Intent(Intent.ACTION_VIEW, Uri.parse("spotify:search:$query"))
      - If no query: just launch Spotify

8. Update the "executeIntent" handler in MainActivity.kt to route all new action types.

9. Update NativeBridge in Flutter to support all these intent types.

10. Add necessary permissions to AndroidManifest.xml:
    - CALL_PHONE
    - SET_ALARM  
    - READ_CALENDAR
    - WRITE_CALENDAR
    - Handle runtime permission requests for CALL_PHONE and CALENDAR

11. Add tests for all intents in Debug screen: buttons for each action type.

Test each intent:
- "Set alarm for 7:30 AM" → should create alarm
- "Set timer for 5 minutes" → should start timer
- "Add meeting tomorrow at 2pm" → should open calendar
- "Play lo-fi music on YouTube" → should search YouTube
- "Message +8801XXXXXXXXX on WhatsApp saying hello" → should open WhatsApp
- "Email test@example.com about the meeting" → should open Gmail
```

---

## PHASE 7A: LLM System Prompt — Action Mapping

**Goal:** Create the system prompt that tells the LLM how to interpret voice commands and return structured actions.

```
Create the system prompt and response parser:

1. Create lib/services/llm/system_prompt.dart with a constant string:

   The system prompt must teach the LLM:
   - What screen context looks like and how to read it
   - All available action types (both intent actions and accessibility actions)
   - How to respond with valid JSON
   - Rules for choosing intent vs accessibility actions
   
   System prompt content:

   """
   You are VoiceOS, a voice-controlled Android phone assistant. You receive:
   1. The user's voice command
   2. The current screen context (what's visible on screen)
   3. The list of installed apps
   
   YOUR JOB: Determine what action(s) to take and respond ONLY with a valid JSON object.
   No markdown, no explanation, no backticks — ONLY the JSON object.
   
   RESPONSE FORMAT:
   {
     "thought": "Brief reasoning about what to do (1 sentence)",
     "actions": [ ...list of action objects... ],
     "speak": "Short confirmation to say to user (under 15 words)"
   }
   
   AVAILABLE ACTIONS:
   
   --- Intent Actions (preferred when available — fast and reliable) ---
   {"type": "open_app", "app_name": "Chrome"}
   {"type": "search_web", "query": "weather today"}
   {"type": "make_call", "number": "+1234567890"}
   {"type": "send_sms", "number": "+1234567890", "message": "On my way"}
   {"type": "set_alarm", "hour": 7, "minute": 30, "message": "Wake up"}
   {"type": "set_timer", "seconds": 300, "message": "Pasta timer"}
   {"type": "add_calendar_event", "title": "Team Meeting", "description": "Weekly sync", "start_time_iso": "2025-02-27T14:00:00", "end_time_iso": "2025-02-27T15:00:00", "location": "Office"}
   {"type": "set_reminder", "title": "Buy groceries", "time_iso": "2025-02-27T18:00:00"}
   {"type": "play_youtube", "query": "lofi hip hop"}
   {"type": "search_youtube", "query": "flutter tutorial"}
   {"type": "send_whatsapp", "phone": "+1234567890", "message": "Hello!"}
   {"type": "compose_email", "to": "boss@company.com", "subject": "Update", "body": "Here is the update..."}
   {"type": "open_maps", "query": "nearest coffee shop"}
   {"type": "navigate_to", "destination": "Dhaka airport"}
   {"type": "open_url", "url": "https://example.com"}
   {"type": "share_text", "text": "Check this out!"}
   
   --- Accessibility Actions (for on-screen interactions) ---
   {"type": "tap", "element": 3}  (tap element by index number from screen context)
   {"type": "tap_xy", "x": 540, "y": 960}  (tap specific coordinates)
   {"type": "long_press", "element": 3}
   {"type": "swipe_up"}  (scrolls content DOWN — finger moves up)
   {"type": "swipe_down"}  (scrolls content UP — finger moves down)
   {"type": "swipe_left"}
   {"type": "swipe_right"}
   {"type": "set_text", "element": 7, "text": "Hello world"}  (type into a text field by element index)
   {"type": "press_back"}
   {"type": "press_home"}
   {"type": "open_notifications"}
   {"type": "open_quick_settings"}
   {"type": "screenshot"}
   {"type": "wait", "ms": 1000}  (wait before next action)
   
   --- System Actions ---
   {"type": "volume_up"}
   {"type": "volume_down"}
   {"type": "toggle_wifi"}
   {"type": "toggle_bluetooth"}
   {"type": "toggle_flashlight"}
   
   --- No Action ---
   {"type": "none"}  (just respond verbally, no device action needed)
   
   RULES:
   1. ALWAYS prefer intent actions over accessibility actions when possible. Intent actions are faster and more reliable.
   2. You can chain multiple actions in sequence. Example: open_app then wait then set_text.
   3. For "scroll down", use "swipe_up" (finger swipes up to move content down).
   4. If the user asks a question (weather, time, facts), use {"type": "none"} and answer in "speak".
   5. For time-related commands, today's date and time will be provided. Parse relative times like "tomorrow at 3pm", "in 2 hours", "next Monday" into ISO format.
   6. If you need to type text on screen: first check if there's an editable field in the screen context. If yes, use set_text with its element index. If the field isn't focused, tap it first, then wait 500ms, then set_text.
   7. For WhatsApp: if user says a contact name (not number), try open_app WhatsApp first, then use accessibility to find and tap the contact.
   8. Keep "speak" responses brief and natural. Never say "I'll" or "Let me" — just confirm: "Opening Chrome", "Alarm set for 7:30 AM", "Scrolling down".
   9. If unclear what user wants, use "none" and ask in "speak".
   10. NEVER include markdown, backticks, or explanation outside the JSON.
   """

2. Create a method that builds the full user prompt by combining:
   - Current date/time: "Current date: Thursday, February 27, 2025, 2:35 PM"
   - Screen context (formatted — we'll build the formatter in next sub-phase)
   - Installed apps list (abbreviated — just names, not package names)
   - The actual voice command
   
   Template:
   """
   [CURRENT TIME] {datetime}
   
   [SCREEN CONTEXT]
   App: {packageName}
   Elements:
   {formatted screen nodes}
   
   [INSTALLED APPS] {comma-separated app names}
   
   [VOICE COMMAND] {user's spoken text}
   """

This file is data/prompt only — no logic to test yet. We'll wire it in Phase 8.
```

---

## PHASE 7B: Screen Context Formatter & Response Parser

**Goal:** Format screen data for the LLM and parse LLM responses into actions.

```
Build screen context formatter and response parser:

1. Create lib/services/screen_context_formatter.dart:

   Method: String formatScreenContext(Map<String, dynamic> rawContext)
   
   Takes the raw map from NativeBridge.getScreenContext() and formats it into
   a concise, numbered text representation.
   
   Rules:
   - Number each element: [0], [1], [2]...
   - Show element type simplified: "Button", "Text", "Input", "Image", "ScrollView", etc.
     Map common Android class names:
     - android.widget.Button, *.MaterialButton → "Button"
     - android.widget.TextView → "Text"
     - android.widget.EditText → "Input"
     - android.widget.ImageView → "Image"
     - android.widget.ImageButton → "ImageButton"
     - *.RecyclerView, *.ScrollView → "ScrollView"
     - android.widget.CheckBox → "Checkbox"
     - android.widget.Switch → "Switch"
     - Default: just show last part of class name
   - Show text or contentDescription (whichever exists, prefer text)
   - Show key properties: (clickable), (scrollable), (editable), (checked), (selected)
   - Show bounds as approximate region
   - Skip elements with no text AND not clickable/scrollable (decorative)
   - Limit to 40 elements max (prioritize clickable and editable)
   - Truncate individual text to 60 characters
   
   Example output:
   ```
   App: Instagram (com.instagram.android)
   [0] Button: "Home" (clickable, selected) [0,1800→270,1920]
   [1] Button: "Search" (clickable) [270,1800→540,1920]
   [2] Image: "john_doe profile" (clickable) [10,200→60,250]
   [3] Text: "john_doe" [70,200→200,230]
   [4] Text: "Great sunset today! 🌅" [10,260→1070,300]
   [5] Button: "Like" (clickable) [10,600→60,650]
   [6] Button: "Comment" (clickable) [70,600→120,650]
   [7] Input: "Add a comment..." (editable, clickable) [10,650→1000,700]
   [8] ScrollView: (scrollable) [0,150→1080,1800]
   ```

2. Create lib/services/llm/response_parser.dart:

   a) Create data class ParsedLLMResponse:
      - String thought
      - List<ParsedAction> actions
      - String speak
   
   b) Create data class ParsedAction:
      - String type
      - Map<String, dynamic> params (all the extra fields)
   
   c) Method: ParsedLLMResponse? parseResponse(String rawLLMResponse)
      - First, try to JSON.decode the raw response directly
      - If that fails, try to extract JSON from markdown code blocks:
        - Look for ```json ... ``` and extract content
        - Look for ``` ... ``` and extract content
        - Look for first { and last } and try to parse that substring
      - If JSON is valid, extract "thought", "actions", "speak"
      - If "actions" is a single object instead of array, wrap it in array
      - Validate each action has a "type" field
      - If all parsing fails, return a fallback:
        ParsedLLMResponse(thought: "Could not parse response", actions: [], speak: "Sorry, something went wrong. Try again.")
   
   d) Method: ParsedAction resolveElementBounds(ParsedAction action, Map<String, dynamic> screenContext)
      - For actions with "element" field (tap, long_press, set_text):
        - Look up the element index in the screen context nodes
        - Calculate center point of bounds: x = (left+right)/2, y = (top+bottom)/2
        - Add resolved x, y coordinates to the action params
      - This converts element-index-based actions to coordinate-based actions

3. Test: Write a simple test in a debug method:
   - Hardcode a sample LLM response JSON string
   - Parse it with responseParser
   - Verify all fields extracted correctly
   - Test with malformed JSON (markdown wrapped, missing fields) to ensure fallback works
```

---

## PHASE 8A: Command Pipeline — Core Integration

**Goal:** Wire voice → LLM → action into a single pipeline.

```
Create the central command pipeline:

1. Create lib/services/command_pipeline.dart:

   class CommandPipeline {
     final LLMClientFactory llmClientFactory;
     final SettingsProvider settingsProvider;
     final ScreenContextFormatter screenFormatter;
     final ResponseParser responseParser;
     final TTSService ttsService;
     
     List<ChatMessage> conversationHistory = [];
     Map<String, dynamic>? lastScreenContext;
     
     Future<PipelineResult> processCommand(String spokenText) async {
       // Step 1: Get current screen context
       lastScreenContext = await NativeBridge.getScreenContext();
       
       // Step 2: Get installed apps (cache this, refresh every 5 min)
       final apps = await NativeBridge.getInstalledApps();
       
       // Step 3: Format everything into prompt
       final screenText = screenFormatter.formatScreenContext(lastScreenContext!);
       final appNames = apps.map((a) => a['name']).join(', ');
       final now = DateTime.now();
       final dateTimeStr = DateFormat('EEEE, MMMM d, y, h:mm a').format(now);
       
       final userPrompt = """
   [CURRENT TIME] $dateTimeStr
   
   [SCREEN CONTEXT]
   $screenText
   
   [INSTALLED APPS] $appNames
   
   [VOICE COMMAND] $spokenText
   """;
       
       // Step 4: Send to LLM
       final client = llmClientFactory.createClient(settingsProvider.settings);
       final systemPrompt = SystemPrompt.prompt;
       final response = await client.sendMessage(
         systemPrompt: systemPrompt,
         userMessage: userPrompt,
         history: conversationHistory,
         temperature: settingsProvider.settings.temperature,
       );
       
       if (!response.success) {
         return PipelineResult.error("AI error: ${response.error}");
       }
       
       // Step 5: Parse LLM response
       final parsed = responseParser.parseResponse(response.rawText);
       if (parsed == null) {
         return PipelineResult.error("Could not understand AI response");
       }
       
       // Step 6: Update conversation history (keep last 6 messages)
       conversationHistory.add(ChatMessage(role: "user", content: spokenText));
       conversationHistory.add(ChatMessage(role: "assistant", content: response.rawText));
       if (conversationHistory.length > 6) {
         conversationHistory = conversationHistory.sublist(conversationHistory.length - 6);
       }
       
       // Step 7: Return parsed result (execution happens in next step)
       return PipelineResult.success(
         thought: parsed.thought,
         actions: parsed.actions,
         speak: parsed.speak,
       );
     }
     
     void clearHistory() {
       conversationHistory.clear();
     }
   }

2. Create lib/models/pipeline_result.dart:
   ```dart
   class PipelineResult {
     final bool success;
     final String? thought;
     final List<ParsedAction>? actions;
     final String? speak;
     final String? error;
     
     PipelineResult.success({this.thought, this.actions, this.speak})
       : success = true, error = null;
     PipelineResult.error(this.error)
       : success = false, thought = null, actions = null, speak = null;
   }
   ```

3. Create lib/providers/command_provider.dart (ChangeNotifier):
   - Holds: isProcessing, lastResult (PipelineResult), commandHistory (List)
   - Method: processVoiceCommand(String text) — calls pipeline, updates state
   - Auto-clears conversation history after 5 minutes of inactivity

4. Register CommandPipeline and CommandProvider in the provider tree.

DO NOT wire to UI yet — we'll do that after building the action executor in the next phase.

Test: Call commandPipeline.processCommand("open Chrome") from debug screen,
log the parsed result to verify LLM returns correct JSON with actions.
```

---

## PHASE 8B: Action Executor — Execute Parsed Actions

**Goal:** Take parsed LLM actions and actually execute them on the device.

```
Build the action executor that runs parsed actions:

1. Create lib/services/action_executor.dart:

   class ActionExecutor {
     final AppResolverService appResolver;
     
     Future<ActionResult> executeActions(List<ParsedAction> actions, Map<String, dynamic>? screenContext) async {
       List<String> results = [];
       
       for (final action in actions) {
         final result = await _executeSingleAction(action, screenContext);
         results.add("${action.type}: ${result.success ? 'OK' : result.error}");
         
         // Small delay between sequential actions
         if (actions.length > 1) {
           await Future.delayed(Duration(milliseconds: 400));
         }
       }
       
       return ActionResult(
         success: results.every((r) => r.contains('OK')),
         details: results,
       );
     }
     
     Future<ActionResult> _executeSingleAction(ParsedAction action, Map<String, dynamic>? screenContext) async {
       switch (action.type) {
         // --- Intent Actions ---
         case 'open_app':
           final packageName = appResolver.resolveAppName(action.params['app_name']);
           if (packageName == null) return ActionResult.fail("App not found");
           return _callIntent({'type': 'open_app', 'packageName': packageName});
         
         case 'search_web':
           return _callIntent({'type': 'search_web', 'query': action.params['query']});
         
         case 'make_call':
           return _callIntent({'type': 'make_call', 'number': action.params['number']});
         
         case 'send_sms':
           return _callIntent({'type': 'send_sms', 'number': action.params['number'], 'message': action.params['message']});
         
         case 'set_alarm':
           return _callIntent({'type': 'set_alarm', 'hour': action.params['hour'], 'minute': action.params['minute'], 'message': action.params['message'] ?? 'Alarm'});
         
         case 'set_timer':
           return _callIntent({'type': 'set_timer', 'seconds': action.params['seconds'], 'message': action.params['message'] ?? 'Timer'});
         
         case 'add_calendar_event':
           // Parse ISO time strings to milliseconds
           final startMs = DateTime.parse(action.params['start_time_iso']).millisecondsSinceEpoch;
           final endMs = DateTime.parse(action.params['end_time_iso']).millisecondsSinceEpoch;
           return _callIntent({
             'type': 'add_calendar_event',
             'title': action.params['title'],
             'description': action.params['description'] ?? '',
             'startTime': startMs,
             'endTime': endMs,
             'location': action.params['location'],
           });
         
         case 'set_reminder':
           final timeMs = DateTime.parse(action.params['time_iso']).millisecondsSinceEpoch;
           return _callIntent({'type': 'set_reminder', 'title': action.params['title'], 'timeInMillis': timeMs});
         
         case 'play_youtube':
         case 'search_youtube':
           return _callIntent({'type': 'search_youtube', 'query': action.params['query']});
         
         case 'send_whatsapp':
           return _callIntent({'type': 'send_whatsapp', 'phone': action.params['phone'], 'message': action.params['message']});
         
         case 'compose_email':
           return _callIntent({'type': 'compose_email', 'to': action.params['to'], 'subject': action.params['subject'] ?? '', 'body': action.params['body'] ?? ''});
         
         case 'open_maps':
           return _callIntent({'type': 'open_maps', 'query': action.params['query']});
         
         case 'navigate_to':
           return _callIntent({'type': 'navigate_to', 'destination': action.params['destination']});
         
         case 'open_url':
           return _callIntent({'type': 'open_url', 'url': action.params['url']});
         
         case 'share_text':
           return _callIntent({'type': 'share_text', 'text': action.params['text']});
         
         // --- Accessibility Actions ---
         case 'tap':
           // Resolve element index to coordinates
           final resolved = responseParser.resolveElementBounds(action, screenContext!);
           return _callAccessibility({'type': 'tap', 'x': resolved.params['x'], 'y': resolved.params['y']});
         
         case 'tap_xy':
           return _callAccessibility({'type': 'tap', 'x': action.params['x'], 'y': action.params['y']});
         
         case 'long_press':
           final resolved = responseParser.resolveElementBounds(action, screenContext!);
           return _callAccessibility({'type': 'long_press', 'x': resolved.params['x'], 'y': resolved.params['y']});
         
         case 'swipe_up':
           return _callAccessibility({'type': 'swipe_up'});
         case 'swipe_down':
           return _callAccessibility({'type': 'swipe_down'});
         case 'swipe_left':
           return _callAccessibility({'type': 'swipe_left'});
         case 'swipe_right':
           return _callAccessibility({'type': 'swipe_right'});
         
         case 'set_text':
           return _callAccessibility({'type': 'set_text', 'nodeIndex': action.params['element'], 'text': action.params['text']});
         
         case 'press_back':
           return _callAccessibility({'type': 'press_back'});
         case 'press_home':
           return _callAccessibility({'type': 'press_home'});
         case 'open_notifications':
           return _callAccessibility({'type': 'open_notifications'});
         case 'open_quick_settings':
           return _callAccessibility({'type': 'open_quick_settings'});
         case 'screenshot':
           return _callAccessibility({'type': 'screenshot'});
         
         // --- System Actions ---
         case 'volume_up':
         case 'volume_down':
         case 'toggle_wifi':
         case 'toggle_bluetooth':
         case 'toggle_flashlight':
           return _callSystem(action.type);
         
         case 'wait':
           await Future.delayed(Duration(milliseconds: action.params['ms'] ?? 1000));
           return ActionResult.ok();
         
         case 'none':
           return ActionResult.ok();
         
         default:
           return ActionResult.fail("Unknown action: ${action.type}");
       }
     }
     
     Future<ActionResult> _callIntent(Map<String, dynamic> data) async { ... NativeBridge.executeIntent(data) ... }
     Future<ActionResult> _callAccessibility(Map<String, dynamic> data) async { ... NativeBridge.executeAction(data) ... }
     Future<ActionResult> _callSystem(String type) async { ... NativeBridge.executeAction({'type': type}) ... }
   }

2. Also implement the system actions on the Kotlin side in MainActivity.kt or a new SystemActionsHandler.kt:
   - volume_up/down → AudioManager.adjustVolume()
   - toggle_wifi → WifiManager (or open WiFi settings intent on newer Android)
   - toggle_bluetooth → BluetoothAdapter (or open Bluetooth settings intent)
   - toggle_flashlight → CameraManager.setTorchMode()
   - Add required permissions: CAMERA (flashlight), CHANGE_WIFI_STATE, BLUETOOTH_CONNECT

3. Create lib/models/action_result.dart:
   ```dart
   class ActionResult {
     final bool success;
     final String? error;
     final List<String>? details;
     ActionResult.ok() : success = true, error = null, details = null;
     ActionResult.fail(this.error) : success = false, details = null;
   }
   ```

4. Wire into CommandProvider:
   - After pipeline returns parsed actions, call actionExecutor.executeActions()
   - Then speak the "speak" text via TTS (if settings.speakResponses is true)
   - Update UI state with results

Test from debug screen: 
- "Open Chrome" → LLM returns open_app, executor launches Chrome
- "Set alarm for 7 AM" → LLM returns set_alarm, executor creates alarm
- "Scroll down" → LLM returns swipe_up, executor swipes
```

---

## PHASE 8C: Quick Commands — No LLM Required

**Goal:** Handle common commands locally without LLM API calls for instant response.

```
Create a quick command handler that intercepts simple commands:

1. Create lib/services/quick_command_handler.dart:

   class QuickCommandHandler {
     // Returns parsed actions if this is a quick command, null if LLM is needed
     PipelineResult? tryHandle(String command) {
       final lower = command.toLowerCase().trim();
       
       // Scroll/Swipe
       if (_matches(lower, ['scroll down', 'swipe up'])) return _action('swipe_up', 'Scrolling down');
       if (_matches(lower, ['scroll up', 'swipe down'])) return _action('swipe_down', 'Scrolling up');
       if (_matches(lower, ['swipe left', 'scroll left'])) return _action('swipe_left', 'Swiping left');
       if (_matches(lower, ['swipe right', 'scroll right'])) return _action('swipe_right', 'Swiping right');
       
       // Navigation
       if (_matches(lower, ['go back', 'back', 'press back'])) return _action('press_back', 'Going back');
       if (_matches(lower, ['go home', 'home', 'press home'])) return _action('press_home', 'Going home');
       if (_matches(lower, ['recent apps', 'recents', 'show recents'])) return _action('press_recents', 'Showing recent apps');
       if (_matches(lower, ['notifications', 'show notifications'])) return _action('open_notifications', 'Opening notifications');
       if (_matches(lower, ['quick settings'])) return _action('open_quick_settings', 'Opening quick settings');
       if (_matches(lower, ['screenshot', 'take screenshot', 'take a screenshot'])) return _action('screenshot', 'Taking screenshot');
       
       // Volume
       if (_matches(lower, ['volume up', 'louder'])) return _action('volume_up', 'Volume up');
       if (_matches(lower, ['volume down', 'quieter', 'lower volume'])) return _action('volume_down', 'Volume down');
       
       // Toggles
       if (_matches(lower, ['flashlight on', 'torch on', 'turn on flashlight'])) return _action('toggle_flashlight', 'Flashlight on');
       if (_matches(lower, ['flashlight off', 'torch off', 'turn off flashlight'])) return _action('toggle_flashlight', 'Flashlight off');
       
       // Not a quick command — needs LLM
       return null;
     }
     
     bool _matches(String input, List<String> patterns) {
       return patterns.any((p) => input == p || input.startsWith(p));
     }
   }

2. Integrate into CommandPipeline:
   - BEFORE sending to LLM, check QuickCommandHandler.tryHandle()
   - If it returns a result, execute immediately (skip LLM call entirely)
   - This saves API calls and gives <100ms response for common actions

3. Wire into CommandProvider so quick commands also show in UI and get spoken.

Test:
- Say "scroll down" → should swipe up INSTANTLY (no LLM delay)
- Say "go back" → should press back instantly
- Say "open youtube and search for cats" → should NOT match quick commands, goes to LLM
```

---

## PHASE 9A: Home Screen — Final UI

**Goal:** Build the polished main screen.

```
Redesign HomeScreen with the final UI:

1. Top Section — Status Bar:
   - Row with: Accessibility service status (green dot + "Active" or red dot + "Enable" button)
   - Current LLM provider chip (e.g., "Claude Sonnet" with provider icon)
   - Settings gear icon button

2. Middle Section — Command Area:
   - Large circular mic button (72dp), centered
   - Above mic: text area showing:
     - When idle: "Tap to speak" (subtle grey)
     - When listening: partial text appearing in real-time (white, animating)
     - When processing: the final command text + "Thinking..." below with loading animation
     - When done: the LLM's "speak" response text (accent color)
   - Mic button states with animations:
     - Idle: default color with subtle breathing animation
     - Listening: red with pulse/ripple animation
     - Processing: accent color with rotating progress ring
     - Success: brief green flash
     - Error: brief orange flash

3. Bottom Section — Command History:
   - Scrollable list (ListView) of recent commands
   - Each item shows:
     - The voice command text (bold)
     - The action taken (e.g., "Opened Chrome", "Set alarm for 7:30 AM")
     - Timestamp (e.g., "2 min ago")
     - Success/failure icon (green check / red X)
   - Show last 20 commands
   - Subtle dividers between items
   - Empty state: "Your commands will appear here"

4. Floating shortcuts:
   - A small row of suggestion chips below the mic:
     - "Open Chrome"
     - "Set timer 5 min"
     - "Scroll down"
     - "Screenshot"
   - Tapping a chip immediately sends that as a command
   - Rotate suggestions randomly

5. Create lib/models/command_history.dart:
   - commandText, actionDescription, timestamp, success fields
   - Store history in shared_preferences (JSON list, max 50)

6. Theme polish:
   - Dark theme: deep dark background (#121212), accent blue/purple
   - Use Material 3 Card for history items
   - Smooth page transitions

Wire everything to the existing providers (VoiceProvider, CommandProvider).
```

---

## PHASE 9B: Floating Widget (Overlay Bubble)

**Goal:** Create a floating mic button that works over any app.

```
Create a floating overlay widget:

1. On the Kotlin side, create android/app/src/main/kotlin/com/voiceos/app/FloatingWidgetService.kt:
   - A foreground Service that displays a floating view using WindowManager
   - The floating view is a small circular mic button (48dp)
   - Uses WindowManager.LayoutParams with TYPE_APPLICATION_OVERLAY
   - The bubble can be dragged around the screen (implement touch drag)
   - When tapped (not dragged): send a message to Flutter via MethodChannel to trigger voice input
   - When long-pressed: dismiss the floating widget
   - Shows a foreground notification: "VoiceOS is listening in the background"

2. Handle SYSTEM_ALERT_WINDOW permission:
   - Add to manifest: <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
   - In Flutter, check if permission is granted: Settings.canDrawOverlays()
   - If not, open Settings.ACTION_MANAGE_OVERLAY_PERMISSION with app URI

3. Add platform channel methods:
   - NativeBridge.startFloatingWidget() → starts FloatingWidgetService
   - NativeBridge.stopFloatingWidget() → stops service
   - NativeBridge.isFloatingWidgetActive() → returns bool

4. When floating button is tapped:
   - The service sends an event to Flutter via EventChannel or MethodChannel
   - Flutter triggers VoiceProvider.startListening()
   - The recognized text goes through the normal pipeline
   - TTS speaks the response
   - The action executes

5. Add to Settings screen:
   - Toggle: "Floating mic button" (default: off)
   - When enabled: request SYSTEM_ALERT_WINDOW permission, then start service
   - When disabled: stop service

6. The floating widget should:
   - Persist across app switches
   - Auto-start on app launch if setting is enabled
   - Show a subtle animation when listening (color change)
   - Snap to screen edges when released after drag

Test:
- Enable floating widget in settings
- Go to Chrome or any other app
- Tap the floating bubble
- Speak a command
- Verify it executes
```

---

## PHASE 10A: Onboarding Flow

**Goal:** First-launch tutorial for new users.

```
Create an onboarding experience:

1. Create lib/screens/onboarding_screen.dart:
   - A PageView with 4 pages, dots indicator at bottom, "Next"/"Get Started" button
   
   Page 1 — Welcome:
   - Large VoiceOS icon/logo at top
   - Title: "Welcome to VoiceOS"
   - Subtitle: "Control your entire phone with your voice"
   - Simple illustration or icon: mic + phone
   
   Page 2 — Accessibility Setup:
   - Title: "Enable Accessibility Service"
   - Explanation: "VoiceOS needs the Accessibility Service to tap, swipe, and interact with your screen."
   - Large "Enable Now" button → opens Android Accessibility Settings
   - Shows current status (enabled/disabled) and updates in real-time when user returns
   - Warning text: "Your data stays on your device. VoiceOS only acts when you give a voice command."
   
   Page 3 — AI Setup:
   - Title: "Connect Your AI"
   - Mini version of the LLM provider selector
   - Model dropdown
   - API key field
   - "Test Connection" button
   - Link text: "Don't have an API key? Groq offers free access →"
   
   Page 4 — Ready:
   - Title: "You're All Set!"
   - Subtitle: "Try saying:"
   - List of example commands:
     - "Open YouTube and search for cooking videos"
     - "Set an alarm for 7 AM tomorrow"
     - "Scroll down"
     - "Send a WhatsApp message to Mom"
     - "What's the weather like?"
   - "Get Started" button → navigates to HomeScreen
   - Saves onboarding_complete = true in SharedPreferences

2. In main.dart:
   - Check if onboarding is complete
   - If not: show OnboardingScreen
   - If yes: show HomeScreen

3. Add "Replay Tutorial" option in Settings for users who want to redo onboarding.

4. Style: use consistent dark theme, smooth page transitions, subtle animations.
```

---

## PHASE 10B: Error Handling, Edge Cases & Polish

**Goal:** Make the app robust for daily use.

```
Harden the app for real-world use:

1. ACCESSIBILITY SERVICE MONITORING:
   - In AccessibilityProvider, periodically check (every 30s) if service is still running
   - Android sometimes kills accessibility services
   - If service dies: show a persistent banner on HomeScreen
   - Optional: show a notification prompting re-enable
   - On app resume: always re-check service status

2. NETWORK ERROR HANDLING:
   - LLM call timeout: show "AI is taking too long. Check your connection."
   - LLM call fails: retry once automatically, then show error
   - No internet: detect with connectivity check before LLM call, show "No internet connection"
   - API key invalid (401): show "API key is invalid. Check your settings."
   - Rate limited (429): show "Too many requests. Wait a moment."

3. LLM RESPONSE RECOVERY:
   - If LLM returns non-JSON: try 3 extraction methods (direct, code block, brace matching)
   - If LLM returns actions with invalid element indices: skip those actions, execute valid ones
   - If LLM returns empty actions array: just speak the response
   - Log all raw LLM responses for debugging

4. ACTION EXECUTION RECOVERY:
   - If an action fails in a sequence: continue with remaining actions (don't abort entire sequence)
   - If open_app fails (app not found): speak "I couldn't find that app"
   - If tap_node fails (element not on screen anymore): re-read screen and retry once
   - Timeout: if an action doesn't complete in 10 seconds, move on

5. VOICE INPUT EDGE CASES:
   - Very short utterance (1-2 words that are unclear): ask "Could you repeat that?"
   - Very long utterance: cap at 500 characters
   - If speech recognition fails to initialize: show error with guidance
   - If speech recognition returns empty: "I didn't catch that"
   - Multiple rapid mic taps: debounce (ignore taps within 500ms)

6. MEMORY & PERFORMANCE:
   - Screen context parsing: limit node traversal depth to 10 levels
   - Cache installed apps list (refresh only every 5 minutes)
   - Dispose all controllers and listeners properly in widget lifecycle
   - Cancel pending LLM calls if user starts a new command
   - Clear conversation history after 5 minutes of inactivity

7. PERMISSIONS:
   - Check all required permissions on app start
   - If any critical permission missing: show a permission request flow
   - Handle "Don't ask again" by directing to app settings
   - Required permissions checklist:
     - RECORD_AUDIO (essential)
     - SYSTEM_ALERT_WINDOW (optional, for floating widget)
     - CALL_PHONE (optional, for direct calling)
     - READ/WRITE_CALENDAR (optional, for calendar)
     - SET_ALARM (for alarms/timers)

8. CLEANUP:
   - Remove all temporary test/debug buttons from earlier phases
   - Keep the debug screen accessible from Settings but hidden (tap version number 7 times to unlock, like Android developer options)
   - Add proper app icon (create a simple mic icon in adaptive icon format)
   - Add proper splash screen
   - Set app label in AndroidManifest.xml to "VoiceOS"
   - Ensure proper back navigation everywhere
   - Test on different screen sizes (phone and tablet)

9. ABOUT SCREEN (in Settings):
   - App version
   - Current AI provider and model
   - Accessibility service status
   - Number of commands executed (track in SharedPreferences)
   - "Reset all settings" button with confirmation dialog
   - Link to accessibility settings
```

---

## PHASE 10C: Final Testing Checklist

**Goal:** Verify everything works before daily use.

```
Run through this complete test plan:

VOICE INPUT:
□ Tap mic → speak → text appears correctly
□ Partial text shows in real-time while speaking
□ Silence auto-stops after 3 seconds
□ Background noise doesn't cause false triggers
□ TTS speaks response back clearly

LLM PROVIDERS (test at least 2):
□ OpenAI GPT-4o works
□ Anthropic Claude works
□ Gemini works
□ Provider switching works (change in settings, next command uses new provider)
□ Invalid API key shows clear error
□ Connection test button works

QUICK COMMANDS (no LLM, instant):
□ "scroll down" → swipes up instantly
□ "go back" → presses back instantly
□ "go home" → goes to home screen
□ "volume up" → raises volume
□ "screenshot" → takes screenshot
□ "notifications" → opens notification shade

INTENT ACTIONS:
□ "open Chrome" → launches Chrome
□ "open YouTube" → launches YouTube
□ "search for pizza recipes on YouTube" → opens YT search
□ "set alarm for 7 AM" → creates alarm
□ "set timer for 5 minutes" → starts timer
□ "add meeting tomorrow at 2pm called Team Sync" → opens calendar
□ "call +8801XXXXXXXX" → initiates call
□ "send WhatsApp message to +8801XXXXXXXX saying hello" → opens WhatsApp
□ "email test@example.com about the project update" → opens email compose
□ "navigate to Dhaka airport" → opens Google Maps navigation
□ "search for best restaurants near me" → opens web search

ACCESSIBILITY ACTIONS:
□ Navigate to Instagram → "like the first post" → taps like button
□ Navigate to WhatsApp → "open first chat" → taps first chat
□ Navigate to Chrome → "tap the search bar" → taps search
□ In any app → "scroll down" → scrolls
□ In a text field → "type hello world" → types text

MULTI-STEP COMMANDS:
□ "Open WhatsApp and search for Mom" → opens app, taps search, types
□ "Go to Chrome and search for weather" → opens Chrome, taps search bar, types, submits

FLOATING WIDGET:
□ Enable in settings → floating bubble appears
□ Switch to another app → bubble stays
□ Tap bubble → voice listening starts
□ Speak command → action executes
□ Drag bubble → repositions
□ Disable in settings → bubble disappears

EDGE CASES:
□ Accessibility service disabled → shows clear warning
□ No internet → shows error message, no crash
□ App killed and reopened → settings persist
□ Rapid mic taps → handles gracefully
□ Very long voice command → handled without crash
□ LLM returns garbage → fallback response works

Fix any issues found during testing.
```

---

## IMPORTANT NOTES FOR CLAUDE CODE

1. **Build and verify after EVERY phase** — run `flutter run` and confirm no errors before moving on.
2. **The Kotlin code (Phases 5-6) is the trickiest part** — AccessibilityService has many quirks. If something doesn't work, check:
   - Is the service actually enabled in Android settings?
   - Is `instance` not null? (Service might not be connected yet)
   - Are you recycling AccessibilityNodeInfo objects properly?
   - Are gesture coordinates within screen bounds?
3. **Platform channels**: Make sure the MethodChannel name matches EXACTLY between Dart and Kotlin (`com.voiceos.app/native`).
4. **Testing LLM responses**: The LLM might not always return perfect JSON. The parser MUST handle:
   - JSON wrapped in ```json ``` blocks
   - Extra text before/after JSON
   - Missing fields
   - Wrong types (string instead of int for element index)
5. **Keep the system prompt under 2000 tokens** — large prompts eat into context and cost money.
6. **Screen context should be under 1500 tokens** — filter aggressively. Only include interactive and text elements.
7. **The app resolves all times relative to the current device time** — always pass current datetime to the LLM.
8. **For WhatsApp/SMS with contact names (not numbers)**: The LLM should use accessibility to search contacts. This is a multi-step flow: open app → tap search → type name → tap result → type message → tap send.
9. **All network calls must be async** — never block the UI thread.
10. **Android 10+ restricts background activity launches** — the floating widget might need to use a full-screen intent or notification to trigger actions reliably.
