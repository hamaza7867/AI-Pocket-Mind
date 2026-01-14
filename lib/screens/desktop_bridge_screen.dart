import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DesktopBridgeScreen extends StatefulWidget {
  const DesktopBridgeScreen({Key? key}) : super(key: key);

  @override
  State<DesktopBridgeScreen> createState() => _DesktopBridgeScreenState();
}

class _DesktopBridgeScreenState extends State<DesktopBridgeScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? serverUrl;
  String? sessionId;
  bool isConnected = false;
  List<Tool> availableTools = [];
  Set<String> selectedTools = {};
  String? currentPersona;
  List<String> personas = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desktop Bridge'),
        actions: [
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: loadTools,
            ),
        ],
      ),
      body: isConnected ? _buildConnectedView() : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.blue,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Scan Desktop Bridge QR Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  serverUrl ?? 'Not connected',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedView() {
    return Column(
      children: [
        // Connection Status
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected to Desktop Bridge',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      serverUrl ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: disconnect,
              ),
            ],
          ),
        ),

        // Persona Selector
        if (personas.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: currentPersona,
              decoration: const InputDecoration(
                labelText: 'Select Persona',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: personas
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  currentPersona = value;
                  selectedTools.clear();
                });
                loadTools();
              },
            ),
          ),

        // Tool Selection
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Tools (${availableTools.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: selectAll,
                    child: const Text('Select All'),
                  ),
                  TextButton(
                    onPressed: deselectAll,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tools List
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: availableTools.length,
                  itemBuilder: (context, index) {
                    final tool = availableTools[index];
                    return CheckboxListTile(
                      title: Text(tool.name),
                      subtitle: Text(tool.description),
                      secondary: _getToolIcon(tool.category),
                      value: selectedTools.contains(tool.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedTools.add(tool.id);
                          } else {
                            selectedTools.remove(tool.id);
                          }
                        });
                      },
                    );
                  },
                ),
        ),

        // Save Button
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedTools.isEmpty ? null : saveToolSelection,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: Text(
              'Save Selection (${selectedTools.length} tools)',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Icon _getToolIcon(String category) {
    switch (category) {
      case 'code':
        return const Icon(Icons.code);
      case 'web':
        return const Icon(Icons.language);
      case 'image':
        return const Icon(Icons.image);
      case 'video':
        return const Icon(Icons.video_library);
      case 'document':
        return const Icon(Icons.description);
      case 'data':
        return const Icon(Icons.analytics);
      case 'ai':
        return const Icon(Icons.psychology);
      case 'database':
        return const Icon(Icons.storage);
      case 'security':
        return const Icon(Icons.security);
      case 'network':
        return const Icon(Icons.network_check);
      default:
        return const Icon(Icons.extension);
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      try {
        final data = jsonDecode(scanData.code ?? '');
        setState(() {
          serverUrl = data['server_url'];
          sessionId = data['session_id'];
          isConnected = true;
        });
        await loadPersonas();
        await loadTools();
        controller.dispose();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid QR code: $e')),
        );
        controller.resumeCamera();
      }
    });
  }

  Future<void> loadPersonas() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/personas'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          personas = (data['personas'] as List)
              .map((p) => p['name'] as String)
              .toList();
          if (personas.isNotEmpty) {
            currentPersona = personas.first;
          }
        });
      }
    } catch (e) {
      print('Error loading personas: $e');
    }
  }

  Future<void> loadTools() async {
    setState(() => isLoading = true);
    try {
      final url = currentPersona != null
          ? '$serverUrl/tools?persona=$currentPersona'
          : '$serverUrl/tools';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          availableTools =
              (data['tools'] as List).map((t) => Tool.fromJson(t)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tools: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void selectAll() {
    setState(() {
      selectedTools = availableTools.map((t) => t.id).toSet();
    });
  }

  void deselectAll() {
    setState(() {
      selectedTools.clear();
    });
  }

  Future<void> saveToolSelection() async {
    // Save to SharedPreferences
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Saved ${selectedTools.length} tools for $currentPersona'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void disconnect() {
    setState(() {
      isConnected = false;
      serverUrl = null;
      sessionId = null;
      availableTools.clear();
      selectedTools.clear();
      personas.clear();
      currentPersona = null;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class Tool {
  final String id;
  final String name;
  final String description;
  final String category;
  final bool installed;
  final bool available;

  Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.installed,
    required this.available,
  });

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      installed: json['installed'],
      available: json['available'],
    );
  }
}
