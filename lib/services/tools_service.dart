import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_config.dart';
import 'api_registry.dart';

class ToolsService {
  // Parsing [TOOL:name, args:xyz]
  Future<String?> checkForTools(String aiResponse) async {
    final RegExp toolRegex = RegExp(r'\[TOOL:(\w+),\s*args:([^\]]+)\]');
    final match = toolRegex.firstMatch(aiResponse);

    if (match != null) {
      final toolName = match.group(1);
      final rawArgs = match.group(2)?.trim() ?? "";

      // Execute and return result
      try {
        final result = await executeTool(toolName!, rawArgs);
        return result; // Return the actual data/result to be injected back
      } catch (e) {
        return "Error executing $toolName: $e";
      }
    }
    return null;
  }

  Future<String> executeTool(String toolName, String args) async {
    switch (toolName) {
      case 'fetch_web_data':
        // Usage: [TOOL:fetch_web_data, args:https://api.coindesk.com/v1/bpi/currentprice.json]
        return await _httpGet(args);

      case 'calculate':
        // Calculate math expressions using API
        // Usage: [TOOL:calculate, args:25*4+10]
        return await _calculate(args);

      case 'fetch_data':
        // Usage: [TOOL:fetch_data, args:provider_name|query]
        // Example: [TOOL:fetch_data, args:wikipedia|Flutter]
        return await _fetchFromRegistry(args);

      case 'tavily_search':
        return await _tavilySearch(args);

      case 'open_browser':
        await _launchUrl(args);
        return "Browser opened for $args";

      default:
        return "Tool $toolName not found.";
    }
  }

  // --- Dynamic API Fetcher ---
  Future<String> _fetchFromRegistry(String args) async {
    // Parse args: "provider|query"
    final parts = args.split('|');
    if (parts.isEmpty) {
      return "[TOOL_ERROR] Invalid args format. Use: provider|query [/TOOL_ERROR]";
    }

    final providerKey = parts[0].trim();
    final query = parts.length > 1 ? parts.sublist(1).join('|').trim() : "";

    final config = ApiRegistry.providers[providerKey];
    if (config == null) {
      return "[TOOL_ERROR] Unknown provider '$providerKey'. Available: ${ApiRegistry.providers.keys.join(', ')} [/TOOL_ERROR]";
    }

    // construct URL
    String url = config.urlTemplate;
    if (config.requiresQuery) {
      if (query.isEmpty) {
        return "[TOOL_ERROR] Provider '$providerKey' requires a query argument. [/TOOL_ERROR]";
      }
      url = url.replaceAll('{query}', Uri.encodeComponent(query));
    }

    // Handle Image Tools Special Case
    if (config.isImage) {
      return "[TOOL_RESULT] Generated Image:\n![Image]($url) [/TOOL_RESULT]";
    }

    // HTTP Request
    return await _httpGet(url);
  }

  // --- API Implementations ---

  Future<String> _httpGet(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      final response = await http.get(url, headers: {
        'User-Agent': 'AIPocketMind/1.0 (MobileApp)',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Return body (truncated if too long to save context)
        String body = response.body;
        if (body.length > 2000) {
          body = "${body.substring(0, 2000)}... [Truncated]";
        }
        return "[TOOL_RESULT] $body [/TOOL_RESULT]";
      } else {
        return "[TOOL_ERROR] Status ${response.statusCode} [/TOOL_ERROR]";
      }
    } catch (e) {
      return "[TOOL_ERROR] Failed to fetch data: $e [/TOOL_ERROR]";
    }
  }

  Future<String> _tavilySearch(String query) async {
    try {
      final url = Uri.parse('https://api.tavily.com/search');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "api_key": AppConfig.tavilyApiKey,
              "query": query,
              "search_depth": "basic", // or "advanced"
              "include_answer": true,
              "max_results": 3,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer'] ?? "";
        final results = data['results'] as List;

        String output = "Tavily Search Results:\n";
        if (answer.isNotEmpty) output += "Direct Answer: $answer\n\n";

        for (var res in results) {
          output += "- ${res['title']}: ${res['content']} (${res['url']})\n";
        }

        return "[TOOL_RESULT] $output [/TOOL_RESULT]";
      } else {
        return "[TOOL_ERROR] Tavily Status ${response.statusCode}: ${response.body} [/TOOL_ERROR]";
      }
    } catch (e) {
      return "[TOOL_ERROR] Tavily search failed: $e [/TOOL_ERROR]";
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<String> _calculate(String expression) async {
    try {
      // Use Newton API for math calculations
      final url = Uri.parse(
          'https://newton.now.sh/api/v2/simplify/${Uri.encodeComponent(expression)}');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'] ?? data['operation'];
        return "[TOOL_RESULT] $expression = $result [/TOOL_RESULT]";
      } else {
        // Fallback: try to parse as simple expression
        return "[TOOL_RESULT] Please calculate: $expression [/TOOL_RESULT]";
      }
    } catch (e) {
      return "[TOOL_ERROR] Could not calculate: $e [/TOOL_ERROR]";
    }
  }

  String getSystemPromptInjection() {
    // Dynamically build tool list from Registry
    final buffer = StringBuffer();
    buffer.writeln("[AVAILABLE TOOLS]");

    // Fixed Tools
    buffer.writeln("1. Search Web (Tavily): [TOOL:tavily_search, args:QUERY]");
    buffer.writeln("   - Use for verification or general queries.");

    buffer.writeln("2. Calculator: [TOOL:calculate, args:EXPRESSION]");
    buffer.writeln("   - Use for math calculations (e.g., 25*4+10)");

    // Dynamic Generic Tool
    buffer.writeln(
        "3. Fetch Specific Data: [TOOL:fetch_data, args:PROVIDER|QUERY]");
    buffer.writeln("   - Available Providers:");

    ApiRegistry.providers.forEach((key, config) {
      buffer.writeln("     * '$key': ${config.description}");
    });

    buffer.writeln("");
    buffer.writeln("4. Open Website: [TOOL:open_browser, args:URL]");
    buffer.writeln("");
    buffer.writeln(
        "IMPORTANT: Use tools when you need real-time data, calculations, or verification.");
    buffer.writeln(
        "Choose the most appropriate tool based on the user's question.");
    buffer.writeln("[/AVAILABLE TOOLS]");

    return buffer.toString();
  }
}
