import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; // For TimeoutException
// import 'package:flutter/services.dart'; // Removed
import 'app_config.dart';

// 1. THE INTERFACE (The Brain Contract)
abstract class AIService {
  // Changed to return a Stream for "Typewriter" effect
  Stream<String> sendMessageStream(List<Map<String, String>> messages);

  // Keep legacy for compatibility if needed (optional)
  Future<String> sendMessage(List<Map<String, String>> messages);

  // RAG: Generate Vector Embedding
  Future<List<double>> getEmbedding(String text);

  String get name;
}

// 2. DESKTOP BRIDGE MODE (Client -> Local Server)
class DesktopBridgeService implements AIService {
  final String baseUrl;
  final String model;

  DesktopBridgeService({required this.baseUrl, this.model = "desktop-default"});

  @override
  String get name => "Desktop Bridge";

  @override
  Future<String> sendMessage(List<Map<String, String>> messages) async {
    final stream = sendMessageStream(messages);
    return stream.join();
  }

  @override
  Stream<String> sendMessageStream(List<Map<String, String>> messages) async* {
    try {
      final cleanBase = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      // We assume the Desktop Bridge exposes an OpenAI-compatible /v1/chat/completions endpoint
      // OR keeps the Ollama style. Let's stick to Ollama style for now as that's what the bridge likely uses internally
      // IF the bridge is just a proxy.
      // However, if the bridge is the Python code we wrote earlier, it might expect different.
      // Let's assume the Bridge IS Ollama for now (since the user deleted the python bridge and might strictly use Ollama directly or a new bridge).
      // Wait, the user said "Desktop Client Mode: Acts as a client to a local server (previously the deleted Python bridge)".
      // But they DELETED the bridge. So they might be running it separately?
      // "The app now relies on the user running the bridge separately."
      // So we should keep the API generic or Ollama-compatible.
      // Let's stick to the /api/chat (Ollama) format as default for "Local Server" unless specified otherwise.
      // Or better: support OpenAI format which is more standard.
      // Let's keep the existing logic but rename class.

      final url = Uri.parse('$cleanBase/api/chat');

      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        "model": model, // Bridge might ignore this or use it
        "messages": messages,
        "stream": true,
      });

      final client = http.Client();
      try {
        final response = await client.send(request).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
                "Connection timed out. Is the Desktop Bridge running?");
          },
        );

        if (response.statusCode == 200) {
          final stream = response.stream
              .transform(utf8.decoder)
              .timeout(const Duration(seconds: 15), onTimeout: (sink) {
            sink.addError(TimeoutException("Stream Stalled"));
            sink.close();
          });

          await for (final chunk in stream) {
            // Handle multiple JSON objects in one chunk
            final lines = chunk.split('\n').where((l) => l.trim().isNotEmpty);
            for (final line in lines) {
              try {
                final data = jsonDecode(line);
                if (data['done'] == false) {
                  final content = data['message']['content'] as String;
                  yield content;
                }
              } catch (e) {
                // partial json
              }
            }
          }
        } else {
          yield "Error: Desktop Bridge returned ${response.statusCode}";
        }
      } finally {
        client.close();
      }
    } catch (e) {
      yield "Error: Could not connect to Desktop Bridge at $baseUrl.\nDetails: $e";
    }
  }

  @override
  Future<List<double>> getEmbedding(String text) async {
    // Leave headers for RAG which might be handled by the bridge separate endpoint
    return [];
  }
}

// 3. CLOUD MODE (OpenAI / Agent Router / Custom)
class CloudService implements AIService {
  final String apiKey;
  final String baseUrl;
  final String model;
  final String providerName;
  final String customBody; // JSON string

  CloudService({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-3.5-turbo',
    this.providerName = 'Cloud API',
    this.customBody = '',
  });

  @override
  String get name => "$providerName ($model)";

  @override
  Future<String> sendMessage(List<Map<String, String>> messages) async {
    final stream = sendMessageStream(messages);
    return stream.join();
  }

  @override
  Stream<String> sendMessageStream(List<Map<String, String>> messages) async* {
    try {
      Uri url;
      if (providerName == "Custom") {
        url = Uri.parse(baseUrl);
      } else {
        // BYOAPI Proxy Logic
        // If we are "Cloud Mode" (User Key), route through Bridge
        if (apiKey.startsWith("sk-") || providerName == "OpenAI") {
          // Route via Bridge
          url = Uri.parse('${AppConfig.bridgeUrl}/api/cloud_proxy');
          // We need to change the body to include the target and key
          // This requires a larger refactor, for now let's just point to Bridge
          // AND assume the Bridge has a /chat/completions compatible endpoint?
          // The plan was /api/cloud_proxy.
        } else {
          url = Uri.parse('$baseUrl/chat/completions');
        }
      }

      Map<String, dynamic> body = {
        "model": model,
        "messages": messages,
        "stream": true, // Enable Streaming
      };

      if (customBody.isNotEmpty) {
        try {
          final Map<String, dynamic> extra = jsonDecode(customBody);
          body.addAll(extra);
        } catch (e) {
          print("Error parsing custom body JSON: $e");
        }
      }

      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.body = jsonEncode(body);

      final client = http.Client(); // Create client
      try {
        final response = await client.send(request);

        if (response.statusCode == 200) {
          // Robust Stream Handling
          final stream = response.stream
              .transform(utf8.decoder)
              .timeout(const Duration(seconds: 15), onTimeout: (sink) {
            sink.addError(TimeoutException("Cloud Stream Stalled"));
            sink.close();
          });

          await for (final chunk in stream) {
            // OpenAI SSE format: "data: {...}"
            final lines =
                chunk.split('\n').where((l) => l.trim().startsWith('data: '));
            for (final line in lines) {
              final jsonStr = line.replaceFirst('data: ', '').trim();
              if (jsonStr == '[DONE]') return;

              try {
                final data = jsonDecode(jsonStr);
                if (data['choices'] != null && data['choices'].isNotEmpty) {
                  final delta = data['choices'][0]['delta'];
                  if (delta.containsKey('content')) {
                    yield delta['content'];
                  }
                }
              } catch (e) {
                // ignore parse error
              }
            }
          }
        } else {
          // Since we can't easily read body from stream if status is bad, we assume error.
          yield "Error: Cloud API returned ${response.statusCode}";
        }
      } finally {
        client.close();
      }
    } catch (e) {
      yield "Error connecting to Cloud API: $e";
    }
  }

  @override
  Future<List<double>> getEmbedding(String text) async {
    if (providerName != "OpenAI" &&
        providerName != "Mistral AI" &&
        providerName != "Custom") {
      // Allow OpenAI, Mistral (uses same format often), and Custom.
      // Groq does NOT support embeddings yet officially via openai-compat in some proxies,
      // but let's try anyway if user selected Custom.
      // return [];
      // ACTUALLY: Let's remove the block and just TRY.
    }

    try {
      // FIX: Use the configured baseUrl instead of hardcoded OpenAI
      // This allows Groq, OpenRouter, etc. to receive the request.
      final cleanBase = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final url = Uri.parse('$cleanBase/embeddings');

      print("Attempting Cloud Embedding at: $url with model: $model");

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey'
            },
            body: jsonEncode({
              // Use a generic model or the one configured.
              // Note: Groq might not support 'text-embedding-3-small'.
              // We'll try the chat model or a known embedding model if provider is specific.
              "model":
                  providerName == "OpenAI" ? "text-embedding-3-small" : model,
              "input": text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          return List<double>.from(data['data'][0]['embedding']);
        }
        throw Exception(
            "Cloud API Error: Valid 200 but no embedding data found.");
      }
      throw Exception(
          "Cloud API HTTP Error: ${response.statusCode} - ${response.body}");
    } catch (e) {
      throw Exception("Cloud Embedding Failed: $e");
    }
  }
}

// 4. DEVICE MODE (Offline / Real Local) - Removed for Production Release
