import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/knowledge_service.dart';
import '../widgets/glass_header.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  // Services
  final KnowledgeService _remoteService = KnowledgeService();

  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final docs = await _remoteService.getDocuments();
    setState(() {
      _documents = docs;
    });
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        withData: kIsWeb,
      );

      if (result != null) {
        final platformFile = result.files.first;

        setState(() {
          _isLoading = true;
          _statusMessage = "Processing ${platformFile.name}...";
        });

        // Always use Remote RAG (Python)
        if (kIsWeb) {
          if (platformFile.bytes != null) {
            await _remoteService.addDocumentBytes(
                platformFile.name, platformFile.bytes!);
          }
        } else {
          if (platformFile.path != null) {
            await _remoteService.addDocument(platformFile.path!);
          }
        }

        setState(() {
          _statusMessage = "Successfully indexed!";
        });
        await _loadDocuments();
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearAll() async {
    await _remoteService.clearKnowledge();
    await _loadDocuments();
    setState(() {
      _statusMessage = "Memory cleared.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: FuturisticTheme.getBackgroundColor(isDark),
      body: SafeArea(
        child: Column(
          children: [
            const GlassHeader(title: 'Knowledge Base'),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                              color: FuturisticTheme.neonCyan),
                          const SizedBox(height: 20),
                          Text(_statusMessage ?? "Processing...",
                              style: FuturisticTheme.getBodyStyle(isDark)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildStatCard(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                        const SizedBox(height: 20),
                        Text("INDEXED DOCUMENTS",
                            style: FuturisticTheme.getMonoStyle(isDark)),
                        const SizedBox(height: 10),
                        if (_documents.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                "No documents indexed.\nAdd PDFs to chat with your data.",
                                textAlign: TextAlign.center,
                                style: FuturisticTheme.getBodyStyle(isDark)
                                    .copyWith(color: FuturisticTheme.textGray),
                              ),
                            ),
                          )
                        else
                          ..._documents.map((doc) => _buildDocumentTile(doc)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    int totalChunks =
        _documents.fold(0, (sum, item) => sum + (item['chunks'] as int? ?? 1));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: FuturisticTheme.getGlassDecoration(isDark),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat("Documents", _documents.length.toString()),
          _buildStat("Knowledge Chunks", totalChunks.toString()),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      children: [
        Text(value,
            style: FuturisticTheme.getHeaderStyle(isDark)
                .copyWith(color: FuturisticTheme.neonPurple)),
        Text(label,
            style: FuturisticTheme.getMonoStyle(isDark)
                .copyWith(fontSize: 12, color: FuturisticTheme.textGray)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.upload_file, color: Colors.black),
            label: const Text("ADD DOCUMENT"),
            style: ElevatedButton.styleFrom(
              backgroundColor: FuturisticTheme.neonCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _pickDocument,
          ),
        ),
        const SizedBox(width: 10),
        _buildClearButton(),
      ],
    );
  }

  Widget _buildClearButton() {
    // final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // Unused
    return IconButton(
      icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
      tooltip: "Clear All Memory",
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) {
            final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
            return AlertDialog(
              backgroundColor: FuturisticTheme.getSurfaceColor(isDark),
              title: Text("Clear Memory?",
                  style: FuturisticTheme.getTitleStyle(isDark)),
              content: Text("This will remove all indexed documents.",
                  style: FuturisticTheme.getBodyStyle(isDark)),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(ctx),
                ),
                TextButton(
                  child: const Text("Clear All",
                      style: TextStyle(color: Colors.redAccent)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _clearAll();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentTile(Map<String, dynamic> doc) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: FuturisticTheme.getGlassDecoration(isDark),
      child: ListTile(
        leading: const Icon(Icons.description, color: FuturisticTheme.neonBlue),
        title: Text(doc['title'], style: FuturisticTheme.getBodyStyle(isDark)),
        subtitle: Text("${doc['chunks'] ?? 1} chunks",
            style: TextStyle(color: FuturisticTheme.textGray, fontSize: 12)),
        trailing: const Icon(Icons.check_circle,
            color: FuturisticTheme.neonCyan, size: 16),
      ),
    );
  }
}
