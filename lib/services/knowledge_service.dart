// import 'dart:io'; // Removed
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:http/http.dart' as http;
import 'dart:convert';

class KnowledgeService {
  static final KnowledgeService _instance = KnowledgeService._internal();
  factory KnowledgeService() => _instance;
  KnowledgeService._internal();

  String pythonServerUrl = "http://127.0.0.1:8000";

  void setServerUrl(String url) {
    if (url.isNotEmpty) {
      pythonServerUrl =
          url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    }
  }

  // Upload Document to Python Backend
  Future<void> addDocument(String path) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$pythonServerUrl/add_document'));

      request.files.add(await http.MultipartFile.fromPath('file', path));

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("KnowledgeService: Upload Success ($pythonServerUrl) - $respStr");
      } else {
        throw Exception("Server Error ${response.statusCode}: $respStr");
      }
    } catch (e) {
      print("KnowledgeService: Upload Error: $e");
      rethrow;
    }
  }

  // Web helper
  Future<void> addDocumentBytes(String name, Uint8List bytes) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$pythonServerUrl/add_document'));

      request.files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: name));

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("KnowledgeService: Upload Success ($pythonServerUrl) - $respStr");
      } else {
        throw Exception("Server Error ${response.statusCode}: $respStr");
      }
    } catch (e) {
      print("KnowledgeService: Upload Error: $e");
      rethrow;
    }
  }

  // Query Python Backend
  Future<List<String>> retrieveRelevantContext(String query) async {
    try {
      final response = await http
          .post(Uri.parse('$pythonServerUrl/query'),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"query": query, "n_results": 4}))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['results'] as List).cast<Map<String, dynamic>>();

        if (results.isEmpty) return [];

        print("RAG: Retrieved ${results.length} chunks from Python.");
        return results
            .map((r) =>
                "Source: ${r['source']} (Score: ${r['score']})\nContent: ${r['content']}")
            .toList();
      } else {
        print(
            "RAG Error: Python Server ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("RAG Error: Connection failed to $pythonServerUrl -> $e");
      // Fallback message? Or just return empty.
      return [];
    }
  }

  // Debug Stats
  Future<int> getDocumentCount() async {
    try {
      final response = await http.get(Uri.parse('$pythonServerUrl/debug'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['document_count'];
      }
    } catch (_) {}
    return 0;
  }

  // Adapter for UI to list documents
  Future<List<Map<String, dynamic>>> getDocuments() async {
    // Since ChromaDB doesn't easily list all docs, we return a placeholder
    // if the count > 0, or empty list.
    int count = await getDocumentCount();
    if (count > 0) {
      return [
        {
          "id": "python-backend",
          "title": "Python Knowledge Base",
          "content": "Contains $count chunks managed by Python Server.",
          "embedding": "YES"
        }
      ];
    }
    return [];
  }

  Future<void> clearKnowledge() async {
    // Optional: Add endpoint to clear DB
  }
}
