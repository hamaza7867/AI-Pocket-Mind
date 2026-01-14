import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/database_helper.dart'; // Uncommented
import '../utils/theme_utils.dart';
import '../widgets/glass_header.dart';
import '../providers/theme_provider.dart'; // Added

class PersonasScreen extends StatefulWidget {
  const PersonasScreen({super.key});

  @override
  State<PersonasScreen> createState() => _PersonasScreenState();
}

class _PersonasScreenState extends State<PersonasScreen> {
  List<Map<String, dynamic>> _personas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonas();
  }

  Future<void> _loadPersonas() async {
    setState(() => _isLoading = true);
    final personas = await DatabaseHelper.instance.getPersonas();
    setState(() {
      _personas = personas;
      _isLoading = false;
    });
  }

  void _addPersona() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final promptCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
        return AlertDialog(
          backgroundColor: FuturisticTheme.getSurfaceColor(isDark),
          title: Text("Create Persona",
              style: FuturisticTheme.getTitleStyle(isDark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField("Name", nameCtrl),
                const SizedBox(height: 10),
                _buildField("Description", descCtrl),
                const SizedBox(height: 10),
                _buildField("System Prompt", promptCtrl, maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: FuturisticTheme.getAccentColor(isDark)),
              child:
                  const Text("Create", style: TextStyle(color: Colors.black)),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && promptCtrl.text.isNotEmpty) {
                  await DatabaseHelper.instance.createPersona(
                    nameCtrl.text,
                    descCtrl.text,
                    promptCtrl.text,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadPersonas();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    // Access theme from context (this method is inside State class, so 'context' is available)
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: FuturisticTheme.getBodyStyle(isDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: FuturisticTheme.textGray),
        enabledBorder:
            OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: FuturisticTheme.neonCyan)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: FuturisticTheme.getBackgroundColor(isDark),
      body: SafeArea(
        child: Column(
          children: [
            const GlassHeader(title: 'AI Personas'),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _personas.isEmpty
                      ? Center(
                          child: Text(
                            "No Custom Personas Yet.\nCreate one to get started!",
                            textAlign: TextAlign.center,
                            style: FuturisticTheme.getBodyStyle(isDark)
                                .copyWith(color: FuturisticTheme.textGray),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _personas.length,
                          itemBuilder: (ctx, i) {
                            final p = _personas[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              // We need a dynamic decoration method or just manually build it
                              decoration: BoxDecoration(
                                color: FuturisticTheme.getSurfaceColor(isDark)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        FuturisticTheme.getAccentColor(isDark)
                                            .withOpacity(0.3)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      FuturisticTheme.getAccentColor(isDark)
                                          .withOpacity(0.2),
                                  child: Text(
                                    (p['name'] as String).isNotEmpty
                                        ? p['name'][0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        color: FuturisticTheme.getAccentColor(
                                            isDark)),
                                  ),
                                ),
                                title: Text(p['name'],
                                    style:
                                        FuturisticTheme.getHeaderStyle(isDark)
                                            .copyWith(fontSize: 18)),
                                subtitle: Text(p['description'],
                                    style: TextStyle(
                                        color: FuturisticTheme.textGray,
                                        fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.play_arrow,
                                          color: FuturisticTheme.getAccentColor(
                                              isDark)),
                                      onPressed: () {
                                        // Activate
                                        final provider =
                                            Provider.of<ChatProvider>(context,
                                                listen: false);
                                        provider.updateSettings(
                                          desktopBridgeUrl:
                                              provider.currentDesktopUrl,
                                          apiKey: provider.currentApiKey,
                                          mode: provider.currentMode,
                                          cloudProvider:
                                              provider.currentCloudProvider,
                                          cloudModel:
                                              provider.currentCloudModel,
                                          systemPrompt: p['prompt'],
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    "Activated ${p['name']}!")));
                                        Navigator.pop(
                                            context); // Go back (likely to settings or chat)
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent, size: 20),
                                      onPressed: () async {
                                        await DatabaseHelper.instance
                                            .deletePersona(p['id']);
                                        _loadPersonas();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: FuturisticTheme.getAccentColor(isDark),
        onPressed: _addPersona,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
