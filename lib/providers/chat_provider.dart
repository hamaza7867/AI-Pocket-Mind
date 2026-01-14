import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';
import '../services/database_helper.dart'; // Local First
import '../services/sync_service.dart'; // Sync Service
import '../services/context_service.dart';
import '../services/tools_service.dart';
import '../services/knowledge_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async'; // For Timers
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Strict Dual Mode
enum AIMode { byoapi, desktopClient }

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _currentSessionId;
  int? get currentSessionId => _currentSessionId;

  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> get sessions => _sessions;

  // Settings
  AIMode _currentMode =
      AIMode.desktopClient; // Default to Desktop Client for safety
  AIMode get currentMode => _currentMode;

  // Desktop Client Config
  String _desktopBridgeUrl = "http://192.168.1.10:5000"; // Python Server URL

  // BYOAPI Config
  String _apiKey = "";
  String _cloudProvider = "OpenAI";
  String _cloudModel = "gpt-3.5-turbo";
  String _customBaseUrl = "";
  String _customBody = "";
  String _systemPrompt = "You are a helpful AI assistant.";

  AIService? _activeService;

  // Advanced Features
  final ImagePicker _picker = ImagePicker();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final ContextService _contextService = ContextService();
  final ToolsService _toolsService = ToolsService();
  final KnowledgeService _knowledgeService = KnowledgeService();

  bool _useContext = true;
  bool _useRAG = true; // Works best with Desktop Client mode
  bool get useRAG => _useRAG;

  bool _isListening = false;
  bool get isListening => _isListening;

  bool _isLiveMode = false; // "Phone Call" mode
  bool get isLiveMode => _isLiveMode;

  // Status for UI (e.g. "Browsing web...", "Thinking...")
  String _statusMessage = "";
  String get statusMessage => _statusMessage;

  ChatProvider() {
    _loadSettings();
    _initTts();
    _initializeSession(); // Ensure session is loaded
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    // Continuous Conversation Loop
    _flutterTts.setCompletionHandler(() {
      if (_isLiveMode) {
        // AI finished speaking, start listening again automatically
        startListening();
      }
    });
  }

  // --- Getters ---
  String get currentDesktopUrl => _desktopBridgeUrl;
  String get currentApiKey => _apiKey;
  String get currentCloudProvider => _cloudProvider;
  String get currentCloudModel => _cloudModel;
  String get customBaseUrl => _customBaseUrl;
  String get customBody => _customBody;
  String get systemPrompt => _systemPrompt;

  String get currentModeDisplay {
    switch (_currentMode) {
      case AIMode.desktopClient:
        return "Desktop Client (Connected to $_desktopBridgeUrl)";
      case AIMode.byoapi:
        return "$_cloudProvider ($_cloudModel)";
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _desktopBridgeUrl =
        prefs.getString('desktopBridgeUrl') ?? "http://192.168.1.10:5000";
    _apiKey = prefs.getString('apiKey') ?? "";

    // Migration logic for old enums
    final storedModeString = prefs.getString('modeString');
    if (storedModeString == "AIMode.network") {
      _currentMode = AIMode.desktopClient;
    } else if (storedModeString == "AIMode.cloud") {
      _currentMode = AIMode.byoapi;
    } else {
      // Clean install or default
      _currentMode = AIMode.values.firstWhere(
        (m) => m.toString() == storedModeString,
        orElse: () => AIMode.desktopClient,
      );
    }

    _cloudProvider = prefs.getString('cloudProvider') ?? "OpenAI";
    _cloudModel = prefs.getString('cloudModel') ?? "gpt-3.5-turbo";
    _customBaseUrl = prefs.getString('customBaseUrl') ?? "";
    _customBody = prefs.getString('customBody') ?? "";
    _systemPrompt =
        prefs.getString('systemPrompt') ?? "You are a helpful AI assistant.";
    _useContext = prefs.getBool('useContext') ?? true;
    _useRAG = prefs.getBool('useRAG') ?? true;

    // Sync Knowledge Service
    _knowledgeService.setServerUrl(_desktopBridgeUrl);

    _refreshService();

    // Trigger Sync on Startup
    SyncService().syncPendingData();

    notifyListeners();
  }

  Future<void> updateSettings({
    required AIMode mode,
    required String desktopBridgeUrl,
    required String apiKey,
    required String cloudProvider,
    required String cloudModel,
    String? customBaseUrl,
    String? customBody,
    String? systemPrompt,
    bool? useRAG,
  }) async {
    _currentMode = mode;
    _desktopBridgeUrl = desktopBridgeUrl;
    _apiKey = apiKey;
    _cloudProvider = cloudProvider;
    _cloudModel = cloudModel;
    _customBaseUrl = customBaseUrl ?? _customBaseUrl;
    _customBody = customBody ?? _customBody;
    _systemPrompt = systemPrompt ?? _systemPrompt;
    if (useRAG != null) _useRAG = useRAG;

    // Update Knowledge Service immediately
    _knowledgeService.setServerUrl(_desktopBridgeUrl);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('modeString', mode.toString());
    await prefs.setString('desktopBridgeUrl', desktopBridgeUrl);
    await prefs.setString('apiKey', apiKey);
    await prefs.setString('cloudProvider', cloudProvider);
    await prefs.setString('cloudModel', cloudModel);
    await prefs.setString('customBaseUrl', _customBaseUrl);
    await prefs.setString('customBody', _customBody);
    await prefs.setString('systemPrompt', _systemPrompt);
    await prefs.setBool('useRAG', _useRAG);

    _refreshService();
    notifyListeners();
  }

  // --- Session Management ---
  Future<void> _initializeSession() async {
    await loadAllSessions();
    if (_sessions.isNotEmpty) {
      await loadSession(_sessions.first['id']);
    } else {
      await startNewSession();
    }
  }

  Future<void> loadAllSessions() async {
    try {
      _sessions = await DatabaseHelper.instance.getSessions();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading sessions: $e");
    }
  }

  Future<void> loadSession(int sessionId) async {
    _currentSessionId = sessionId;
    _messages.clear();
    final dbMessages = await DatabaseHelper.instance.getMessages(sessionId);
    for (var m in dbMessages) {
      _messages.add(ChatMessage(
          text: m['content'] as String,
          isUser: (m['role'] as String) == 'user'));
    }
    notifyListeners();
  }

  Future<void> startNewSession() async {
    try {
      final id = await DatabaseHelper.instance.createSession("New Chat");
      _currentSessionId = id;
      _messages.clear();
      await loadAllSessions();
      notifyListeners();
    } catch (e) {
      debugPrint("Error creating session: $e");
    }
  }

  Future<void> deleteSession(int sessionId) async {
    await DatabaseHelper.instance.deleteSession(sessionId);
    await loadAllSessions();
    if (_currentSessionId == sessionId) {
      await startNewSession();
    } else {
      notifyListeners();
    }
  }

  void _refreshService() {
    if (_currentMode == AIMode.byoapi) {
      // Cloud / BYOAPI
      String baseUrl;
      // Pre-select known base URLs
      if (_cloudProvider == "OpenAI") {
        baseUrl = "https://api.openai.com/v1";
      } else if (_cloudProvider == "Agent Router") {
        baseUrl = "https://agentrouter.org/v1";
      } else if (_cloudProvider == "Groq") {
        baseUrl = "https://api.groq.com/openai/v1";
      } else if (_cloudProvider == "DeepSeek") {
        baseUrl = "https://api.deepseek.com/v1";
      } else if (_cloudProvider == "Mistral AI") {
        baseUrl = "https://api.mistral.ai/v1";
      } else {
        // Custom
        baseUrl = _customBaseUrl.isNotEmpty
            ? _customBaseUrl
            : "https://api.openai.com/v1";
      }

      _activeService = CloudService(
        providerName: _cloudProvider,
        apiKey: _apiKey,
        baseUrl: baseUrl,
        model: _cloudModel,
        customBody: _customBody,
      );
    } else {
      // Desktop Client Mode
      // We use the DesktopBridgeService (formerly OllamaService)
      _activeService = DesktopBridgeService(
        baseUrl: _desktopBridgeUrl,
        // The desktop decides the model, or we can pass one if needed
        model: "desktop-default",
      );
    }
    notifyListeners();
  }

  // --- Multimodal & Voice Features ---

  Future<void> attachImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        // Standard markdown format for basic image display
        final hiddenContent = "User uploaded an image. [IMG]$base64Image[/IMG]";
        sendMessage(hiddenContent, displayLabel: "[Image Uploaded]");

        // TODO: In Desktop Client mode, we could upload this file to the bridge directly
        // But embedding it in the message works for now if the Bridge parses [IMG] tags.
      }
    } catch (e) {
      _messages
          .add(ChatMessage(text: "Error picking image: $e", isUser: false));
      notifyListeners();
    }
  }

  Future<void> attachDocument() async {
    // Only works effectively in Desktop Client mode for RAG
    if (_currentMode != AIMode.desktopClient) {
      _messages.add(ChatMessage(
          text:
              "System: Document RAG is only available in Desktop Client mode.",
          isUser: false));
      notifyListeners();
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        withData: kIsWeb,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        _isLoading = true;
        _statusMessage = "Uploading & Analyzing...";
        notifyListeners();

        if (file.path != null) {
          // Upload to Desktop Bridge
          // We use KnowledgeService which is already configured with _desktopBridgeUrl
          await _knowledgeService.addDocument(file.path!);
        }

        final systemMsg =
            "I have uploaded '${file.name}' to the Desktop Brain. You can now chat about it.";
        await DatabaseHelper.instance
            .createMessage(_currentSessionId!, 'assistant', systemMsg);
        _messages.add(ChatMessage(text: systemMsg, isUser: false));

        _isLoading = false;
        _statusMessage = "";
        notifyListeners();
      }
    } catch (e) {
      _messages.add(ChatMessage(text: "Error attachment: $e", isUser: false));
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      _isListening = true;
      notifyListeners();
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _isListening = false;
            notifyListeners();
            sendMessage(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
    notifyListeners();
  }

  void toggleLiveMode() {
    _isLiveMode = !_isLiveMode;
    if (_isLiveMode) {
      _flutterTts.speak("Live mode active. Listening.");
    } else {
      _flutterTts.stop();
      stopListening();
    }
    notifyListeners();
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  // --- Core Messaging Logic ---
  Future<void> sendMessage(String text, {String? displayLabel}) async {
    if (text.trim().isEmpty) return;
    if (_currentSessionId == null) await startNewSession();

    final userMsg = ChatMessage(text: displayLabel ?? text, isUser: true);
    _messages.add(userMsg);
    _isLoading = true;
    _statusMessage = "Thinking...";
    notifyListeners();

    if (_currentSessionId != null) {
      await DatabaseHelper.instance
          .createMessage(_currentSessionId!, 'user', text);
      SyncService().syncPendingData();
    }

    try {
      if (_activeService == null) _refreshService();

      if (_currentMode == AIMode.byoapi &&
          _apiKey.isEmpty &&
          _cloudProvider != "Custom") {
        // Custom might not need Key
        throw Exception(
            "API Key is missing for $_cloudProvider. Please check Settings.");
      }

      // Context & RAG Building
      List<Map<String, String>> context = await _buildContext(text);

      // --- AGENT EXECUTION ---
      // We support basic tools even in BYOAPI if implemented in client,
      // but mostly Tools handled by Desktop Bridge.

      final assistantMsg = ChatMessage(text: "", isUser: false);
      _messages.add(assistantMsg);
      notifyListeners();

      StringBuffer fullResponseBuffer = StringBuffer();
      int chunkCount = 0;

      await for (final chunk in _activeService!.sendMessageStream(context)) {
        fullResponseBuffer.write(chunk);
        chunkCount++;
        if (chunkCount % 3 == 0) {
          _messages.removeLast();
          _messages.add(
              ChatMessage(text: fullResponseBuffer.toString(), isUser: false));
          notifyListeners();
        }
      }

      _messages.removeLast();
      _messages
          .add(ChatMessage(text: fullResponseBuffer.toString(), isUser: false));
      notifyListeners();

      final fullResponse = fullResponseBuffer.toString();
      await DatabaseHelper.instance
          .createMessage(_currentSessionId!, 'assistant', fullResponse);
      SyncService().syncPendingData();

      if (_isLiveMode) {
        await _flutterTts.speak(fullResponse);
      }
    } catch (e) {
      _messages.add(ChatMessage(text: "Error: $e", isUser: false));
      debugPrint("SendMessage Error: $e");
    } finally {
      _isLoading = false;
      _statusMessage = "";
      notifyListeners();
    }
  }

  Future<List<Map<String, String>>> _buildContext(String userText) async {
    final List<Map<String, String>> context = [];
    String finalSystemPrompt = _systemPrompt;

    if (_useContext) {
      // _statusMessage = "Recalling context...";
      // notifyListeners();
      final ctx = await _contextService.getAllContext();
      finalSystemPrompt += "\n${_contextService.formatContextForPrompt(ctx)}";
    }

    if (_useRAG && _currentMode == AIMode.desktopClient) {
      // _statusMessage = "Searching memory...";
      // notifyListeners();
      try {
        final knowledge = await _knowledgeService
            .retrieveRelevantContext(userText)
            .timeout(const Duration(seconds: 4), onTimeout: () => []);

        if (knowledge.isNotEmpty) {
          finalSystemPrompt +=
              "\n\nRELEVANT KNOWLEDGE BASE:\n${knowledge.join("\n\n")}";
        }
      } catch (_) {}
    }

    _statusMessage = "Thinking...";
    notifyListeners();

    if (finalSystemPrompt.isNotEmpty) {
      context.add({"role": "system", "content": finalSystemPrompt});
    }

    final recentMsgs = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : _messages;
    for (var msg in recentMsgs) {
      if (msg.text.startsWith("[Image Uploaded]")) continue;
      // Skip empty placeholder
      if (msg.text.isEmpty) continue;
      context.add(
          {"role": msg.isUser ? "user" : "assistant", "content": msg.text});
    }
    context.add({"role": "user", "content": userText});
    return context;
  }

  void clearChat() {
    _messages.clear();
    startNewSession();
  }
}
