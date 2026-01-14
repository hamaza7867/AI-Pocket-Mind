import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart'; // Import Added
import '../providers/chat_provider.dart';
import '../utils/theme_utils.dart';
import '../widgets/glass_header.dart';
import '../services/auth_service.dart';
// import '../services/database_helper.dart';
// Removed: model_manager (on-device AI deprecated)
import '../services/supabase_service.dart'; // Import Added
import 'knowledge_screen.dart';
import 'personas_screen.dart';
import 'legal_screen.dart';
import 'qr_scanner_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ... (controllers)
  late TextEditingController _urlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _systemPromptController;
  late TextEditingController _customBodyController;
  late TextEditingController _modelController;

  // Removed unused fields
  bool _bioLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBioLock();
    final provider = Provider.of<ChatProvider>(context, listen: false);
    _urlController = TextEditingController(
      text: provider.customBaseUrl.isEmpty
          ? provider.currentDesktopUrl
          : provider.customBaseUrl,
    );
    _apiKeyController = TextEditingController(text: provider.currentApiKey);
    _systemPromptController = TextEditingController(
      text: provider.systemPrompt,
    );
    _customBodyController = TextEditingController(
      text: provider.customBody,
    );
    _modelController = TextEditingController(text: provider.currentCloudModel);
  }

  Future<void> _loadBioLock() async {
    bool enabled = await AuthService().isBioLockEnabled;
    setState(() => _bioLockEnabled = enabled);
  }

  // Import Model Logic Removed (Feature Deprecated)

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: FuturisticTheme.getBackgroundColor(isDark),
      body: SafeArea(
        child: Column(
          children: [
            const GlassHeader(title: 'Settings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                   // 1. Account
                   _buildSectionTitle("Account"),
                   _buildGlassCard(
                     child: ListTile(
                       leading: Icon(Icons.person, color: FuturisticTheme.neonCyan),
                       title: Text('Profile', style: FuturisticTheme.getBodyStyle(isDark)),
                       subtitle: Text('Manage your profile & preferences', style: TextStyle(color: FuturisticTheme.textGray, fontSize: 12)),
                       trailing: Icon(Icons.arrow_forward_ios, size: 16, color: FuturisticTheme.textGray),
                       onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                     ),
                   ),
                   const SizedBox(height: 20),

                   // 2. AI Intelligence (Mode Toggle)
                   _buildSectionTitle("AI Intelligence"),
                   _buildGlassCard(
                     child: Column(
                       children: [
                         Container(
                           width: double.infinity,
                           decoration: BoxDecoration(
                             color: FuturisticTheme.getSurfaceColor(isDark),
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                           ),
                           padding: const EdgeInsets.all(4),
                           child: Row(
                             children: [
                               Expanded(
                                 child: GestureDetector(
                                   onTap: () {
                                      chatProvider.updateSettings(
                                        mode: AIMode.desktopClient,
                                        desktopBridgeUrl: _urlController.text,
                                        apiKey: _apiKeyController.text,
                                        cloudProvider: chatProvider.currentCloudProvider,
                                        cloudModel: chatProvider.currentCloudModel,
                                      );
                                   },
                                   child: Container(
                                     padding: const EdgeInsets.symmetric(vertical: 12),
                                     decoration: BoxDecoration(
                                       color: chatProvider.currentMode == AIMode.desktopClient ? FuturisticTheme.neonCyan : Colors.transparent,
                                       borderRadius: BorderRadius.circular(8),
                                     ),
                                     child: Center(
                                       child: Text("Local AI", style: TextStyle(color: chatProvider.currentMode == AIMode.desktopClient ? Colors.black : FuturisticTheme.textGray, fontWeight: FontWeight.bold)),
                                     ),
                                   ),
                                 ),
                               ),
                               Expanded(
                                 child: GestureDetector(
                                   onTap: () {
                                      chatProvider.updateSettings(
                                        mode: AIMode.byoapi,
                                        desktopBridgeUrl: _urlController.text,
                                        apiKey: _apiKeyController.text,
                                        cloudProvider: chatProvider.currentCloudProvider,
                                        cloudModel: chatProvider.currentCloudModel,
                                      );
                                   },
                                   child: Container(
                                     padding: const EdgeInsets.symmetric(vertical: 12),
                                     decoration: BoxDecoration(
                                       color: chatProvider.currentMode == AIMode.byoapi ? FuturisticTheme.neonPurple : Colors.transparent,
                                       borderRadius: BorderRadius.circular(8),
                                     ),
                                     child: Center(
                                       child: Text("Cloud (BYOAPI)", style: TextStyle(color: chatProvider.currentMode == AIMode.byoapi ? Colors.white : FuturisticTheme.textGray, fontWeight: FontWeight.bold)),
                                     ),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 20),

                   // 3. BYOAPI Config
                   if (chatProvider.currentMode == AIMode.byoapi) ...[
                     _buildSectionTitle("AI Configuration"),
                     _buildGlassCard(
                       child: Column(
                         children: [
                           DropdownButtonFormField<String>(
                             dropdownColor: FuturisticTheme.getSurfaceColor(isDark),
                             initialValue: chatProvider.currentCloudProvider,
                             items: ["OpenAI", "Groq", "DeepSeek", "Mistral AI", "OpenRouter", "Agent Router", "Custom"]
                                 .map((e) => DropdownMenuItem(value: e, child: Text(e, style: FuturisticTheme.getBodyStyle(isDark))))
                                 .toList(),
                             onChanged: (val) {
                               if (val != null) {
                                  String defaultModel = _modelController.text;
                                  if (val == "OpenAI") defaultModel = "gpt-3.5-turbo";
                                  if (val == "Groq") defaultModel = "llama3-8b-8192";
                                  if (val == "Mistral AI") defaultModel = "mistral-small-latest";
                                  if (val == "DeepSeek") defaultModel = "deepseek-chat";
                                  setState(() { _modelController.text = defaultModel; });
                                  chatProvider.updateSettings(
                                    mode: chatProvider.currentMode,
                                    desktopBridgeUrl: _urlController.text,
                                    apiKey: _apiKeyController.text,
                                    cloudProvider: val,
                                    cloudModel: defaultModel,
                                    customBaseUrl: _urlController.text,
                                  );
                               }
                             },
                             decoration: _buildInputDec("Provider"),
                           ),
                           const SizedBox(height: 10),
                           TextField(
                             controller: _modelController,
                             style: FuturisticTheme.getBodyStyle(isDark),
                             decoration: _buildInputDec("Model Name"),
                           ),
                           const SizedBox(height: 10),
                           if (chatProvider.currentCloudProvider == "Custom") ...[
                              TextField(
                                controller: _urlController,
                                style: FuturisticTheme.getBodyStyle(isDark),
                                decoration: _buildInputDec("Full Endpoint URL"),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _customBodyController,
                                style: FuturisticTheme.getBodyStyle(isDark),
                                maxLines: 2,
                                decoration: _buildInputDec('Extra Config (JSON)'),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text("Save"), style: ElevatedButton.styleFrom(backgroundColor: FuturisticTheme.neonCyan.withAlpha(50), foregroundColor: FuturisticTheme.neonCyan), onPressed: _showSaveApiDialog)),
                                  const SizedBox(width: 8),
                                  Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.download), label: const Text("Load"), style: ElevatedButton.styleFrom(backgroundColor: FuturisticTheme.neonPurple.withAlpha(50), foregroundColor: FuturisticTheme.neonPurple), onPressed: _showLoadApiBottomSheet)),
                                ],
                              ),
                              const SizedBox(height: 10),
                           ],
                           TextField(
                             controller: _apiKeyController,
                             style: FuturisticTheme.getBodyStyle(isDark),
                             decoration: _buildInputDec("API Key"),
                             obscureText: true,
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(height: 20),
                   ],

                   // 4. Desktop Connection
                   if (chatProvider.currentMode == AIMode.desktopClient) ...[
                      _buildSectionTitle("Desktop Connection"),
                      _buildGlassCard(
                        child: Column(
                          children: [
                            Icon(Icons.desktop_windows, size: 50, color: FuturisticTheme.neonCyan),
                            const SizedBox(height: 10),
                            Text("Connect to PocketMind Desktop Bridge", textAlign: TextAlign.center, style: FuturisticTheme.getBodyStyle(isDark)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('SCAN DESKTOP QR'),
                              style: ElevatedButton.styleFrom(backgroundColor: FuturisticTheme.neonCyan, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
                                if (result == true && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("✅ Bridge Linked Successfully!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                   ],
                   
                   // 5. System Design
                   _buildSectionTitle("System Design (Persona)"),
                   _buildGlassCard(
                     child: TextField(
                       controller: _systemPromptController,
                       style: FuturisticTheme.getBodyStyle(isDark),
                       maxLines: 4,
                       decoration: _buildInputDec("System Prompt (Bio)"),
                     ),
                   ),
                   const SizedBox(height: 30),

                   // 6. Bio Lock
                   SwitchListTile(
                     title: Text("Bio-Lock Security", style: FuturisticTheme.getBodyStyle(isDark)),
                     subtitle: Text("Require fingerprint on startup", style: TextStyle(color: FuturisticTheme.textGray, fontSize: 12)),
                     activeThumbColor: FuturisticTheme.neonCyan,
                     value: _bioLockEnabled,
                     onChanged: (val) async {
                       bool success = true;
                       if (val) success = await AuthService().authenticate();
                       if (success) {
                         setState(() => _bioLockEnabled = val);
                         AuthService().setBioLock(val);
                       }
                     },
                   ),
                   const SizedBox(height: 10),

                   // 7. Personas
                   ListTile(
                     tileColor: FuturisticTheme.getSurfaceColor(isDark),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2))),
                     leading: const Icon(Icons.people_outline, color: Colors.teal),
                     title: Text("AI Personas", style: FuturisticTheme.getBodyStyle(isDark)),
                     subtitle: Text("Manage custom system personalities.", style: TextStyle(color: FuturisticTheme.textGray)),
                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonasScreen())),
                   ),
                   const SizedBox(height: 10),

                   // 8. Knowledge Base
                   ListTile(
                     tileColor: FuturisticTheme.getSurfaceColor(isDark),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2))),
                     leading: const Icon(Icons.library_books, color: Colors.purple),
                     title: Text("Knowledge Base", style: FuturisticTheme.getBodyStyle(isDark)),
                     subtitle: Text("Manage PDF documents and memory.", style: TextStyle(color: FuturisticTheme.textGray)),
                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeScreen())),
                   ),
                   const SizedBox(height: 10),

                   // 9. Legal
                   ListTile(
                     tileColor: FuturisticTheme.getSurfaceColor(isDark),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2))),
                     leading: const Icon(Icons.policy, color: Colors.grey),
                     title: Text("Legal Documents", style: FuturisticTheme.getBodyStyle(isDark)),
                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen())),
                   ),
                   const SizedBox(height: 10),

                   // 10. Save Button
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton(
                       style: ElevatedButton.styleFrom(backgroundColor: FuturisticTheme.neonCyan, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                       onPressed: () {
                         chatProvider.updateSettings(
                            mode: chatProvider.currentMode,
                            desktopBridgeUrl: _urlController.text,
                            apiKey: _apiKeyController.text,
                            cloudProvider: chatProvider.currentCloudProvider,
                            cloudModel: _modelController.text,
                            customBaseUrl: _urlController.text,
                            customBody: _customBodyController.text,
                            systemPrompt: _systemPromptController.text,
                         );
                         Navigator.pop(context);
                       },
                       child: Text("SAVE CONFIGURATION", style: FuturisticTheme.getTitleStyle(isDark).copyWith(fontSize: 16, color: Colors.black)),
                     ),
                   ),
                   const SizedBox(height: 20),

                   // 11. Logout
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton.icon(
                       icon: const Icon(Icons.logout),
                       label: const Text('LOGOUT'),
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                       onPressed: () async {
                         final shouldLogout = await showDialog<bool>(
                           context: context,
                           builder: (context) => AlertDialog(
                             backgroundColor: FuturisticTheme.getSurfaceColor(isDark),
                             title: Text('Logout', style: FuturisticTheme.getHeaderStyle(isDark)),
                             content: Text('Are you sure you want to logout?', style: FuturisticTheme.getBodyStyle(isDark)),
                             actions: [
                               TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                               TextButton(onPressed: () => Navigator.of(context).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.redAccent), child: const Text('Logout')),
                             ],
                           ),
                         );
                         if (shouldLogout == true && mounted) {
                           await SupabaseService().signOut();
                           if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                         }
                       },
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title, style: FuturisticTheme.getMonoStyle(isDark)),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FuturisticTheme.getGlassDecoration(isDark),
      child: child,
    );
  }

  InputDecoration _buildInputDec(String label) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: isDark ? FuturisticTheme.textGray : Colors.grey[700]),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: FuturisticTheme.getAccentColor(isDark)),
      ),
    );
  }
  // --- BYOAPI Logic ---

  void _showSaveApiDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
        return AlertDialog(
          backgroundColor: FuturisticTheme.getSurfaceColor(isDark),
          title: Text("Save API Config",
              style: FuturisticTheme.getHeaderStyle(isDark)),
          content: TextField(
            controller: nameCtrl,
            style: FuturisticTheme.getBodyStyle(isDark),
            decoration: InputDecoration(
              hintText:
                  "Config Name (e.g. My Groq)", // Currently mapped to 'provider' for now
              hintStyle:
                  TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  // We use the 'provider' field as the unique identifier/name for now in this simple UI
                  // Ideally we'd have a separate 'name' field, but schema said 'provider' check constraints.
                  // Let's use the actual CloudProvider dropdown value + a suffix if needed?
                  // Or just assume the user is saving the current setup for the current provider.

                  // REVISION: The schema has `provider` and `api_key`.
                  // Let's just save for the CURRENT selected provider.

                  final chatProvider =
                      Provider.of<ChatProvider>(context, listen: false);

                  try {
                    await SupabaseService().saveApiConfig(
                      provider: chatProvider.currentCloudProvider,
                      apiKey: _apiKeyController.text,
                      baseUrl: _urlController.text,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "✅ Saved ${chatProvider.currentCloudProvider} Settings to Cloud!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error saving: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLoadApiBottomSheet() async {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    // Show Loading
    showModalBottomSheet(
      context: context,
      backgroundColor: FuturisticTheme.getSurfaceColor(isDark),
      builder: (_) => Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final apis = await SupabaseService().getAllApiConfigs();
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showModalBottomSheet(
        context: context,
        backgroundColor: FuturisticTheme.getSurfaceColor(isDark),
        builder: (_) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Saved API Configurations",
                  style: FuturisticTheme.getHeaderStyle(isDark),
                ),
                const SizedBox(height: 10),
                if (apis.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "No saved configs found.",
                      style: FuturisticTheme.getBodyStyle(isDark),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: apis.length,
                    itemBuilder: (context, index) {
                      final config = apis[index];
                      final provider = config['provider'] ?? "Unknown";
                      final url = config['base_url'] ?? "";

                      return ListTile(
                        leading:
                            Icon(Icons.cloud, color: FuturisticTheme.neonCyan),
                        title: Text(provider,
                            style: FuturisticTheme.getBodyStyle(isDark)),
                        subtitle: Text(url,
                            style: TextStyle(
                                color: FuturisticTheme.textGray, fontSize: 10)),
                        onTap: () {
                          // Load this config
                          final chatProvider =
                              Provider.of<ChatProvider>(context, listen: false);

                          // Update Controllers
                          _apiKeyController.text = config['api_key'] ?? "";
                          _urlController.text = config['base_url'] ?? "";

                          // Update Provider
                          chatProvider.updateSettings(
                            mode: AIMode.byoapi, // Switch to Cloud Mode
                            desktopBridgeUrl:
                                chatProvider.currentDesktopUrl, // Keep existing
                            apiKey: config['api_key'] ?? "",
                            cloudProvider: provider,
                            cloudModel: chatProvider
                                .currentCloudModel, // Keep model or default?
                            customBaseUrl: config['base_url'] ?? "",
                          );

                          setState(() {
                            // Force redraw logic for dropdown
                            // Dropdown value must match items.
                            if ([
                              "OpenAI",
                              "Groq",
                              "DeepSeek",
                              "Mistral AI",
                              "OpenRouter",
                              "Agent Router",
                              "Custom"
                            ].contains(provider)) {
                              // good
                            } else {
                              // Fallback to Custom if unknown provider name in DB
                            }
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("✅ Loaded $provider Profile!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading configs: $e")),
      );
    }
  }
}
