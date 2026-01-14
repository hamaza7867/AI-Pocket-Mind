import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';
import 'dart:io';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

class ServerDashboard extends StatefulWidget {
  const ServerDashboard({super.key});

  @override
  State<ServerDashboard> createState() => _ServerDashboardState();
}

class _ServerDashboardState extends State<ServerDashboard> {
  String _localIP = "Detecting...";
  bool _ollamaOnline = false;
  bool _pythonOnline = false;

  @override
  void initState() {
    super.initState();
    _detectNetworkInfo();
    _checkServices();
  }

  Future<void> _detectNetworkInfo() async {
    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Look for IPv4 addresses that are not loopback
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() {
              _localIP = addr.address;
            });
            return;
          }
        }
      }
      setState(() {
        _localIP = "No Network";
      });
    } catch (e) {
      setState(() {
        _localIP = "Error: $e";
      });
    }
  }

  Future<void> _checkServices() async {
    // Check Ollama (port 11434)
    try {
      final socket = await Socket.connect('127.0.0.1', 11434,
          timeout: const Duration(seconds: 2));
      socket.destroy();
      setState(() => _ollamaOnline = true);
    } catch (_) {
      setState(() => _ollamaOnline = false);
    }

    // Check Python Server (port 5000)
    try {
      final socket = await Socket.connect('127.0.0.1', 5000,
          timeout: const Duration(seconds: 2));
      socket.destroy();
      setState(() => _pythonOnline = true);
    } catch (_) {
      setState(() => _pythonOnline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: FuturisticTheme.getBackgroundColor(isDark),
      body: Container(
        decoration: BoxDecoration(
          gradient: FuturisticTheme.getBackgroundGradient(isDark),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.memory,
                        size: 48, color: FuturisticTheme.neonCyan),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pocket Mind Bridge',
                          style: FuturisticTheme.getHeaderStyle(isDark)
                              .copyWith(fontSize: 32),
                        ),
                        Text(
                          'AI Intelligence Server',
                          style: FuturisticTheme.getMonoStyle(isDark),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon:
                          Icon(Icons.refresh, color: FuturisticTheme.neonCyan),
                      onPressed: () {
                        _detectNetworkInfo();
                        _checkServices();
                      },
                      tooltip: 'Refresh Status',
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // QR Code Pairing
                _buildInfoCard(
                  isDark: isDark,
                  title: 'Quick Setup - Scan QR Code',
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: jsonEncode({
                          'ollama_url': 'http://$_localIP:11434',
                          'python_url': 'http://$_localIP:5000',
                          'version': '1.0',
                        }),
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Connection Info Card
                _buildInfoCard(
                  isDark: isDark,
                  title: 'Mobile Connection',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Phone should connect to:',
                        style: FuturisticTheme.getBodyStyle(isDark).copyWith(
                          color: FuturisticTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCopyableField(
                        isDark: isDark,
                        label: 'Ollama URL',
                        value: 'http://$_localIP:11434',
                      ),
                      const SizedBox(height: 8),
                      _buildCopyableField(
                        isDark: isDark,
                        label: 'Python RAG URL',
                        value: 'http://$_localIP:5000',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Services Status
                _buildInfoCard(
                  isDark: isDark,
                  title: 'Services Status',
                  child: Column(
                    children: [
                      _buildStatusRow(
                        isDark: isDark,
                        service: 'Ollama Server',
                        status: _ollamaOnline,
                        port: '11434',
                      ),
                      const SizedBox(height: 12),
                      _buildStatusRow(
                        isDark: isDark,
                        service: 'Python RAG Backend',
                        status: _pythonOnline,
                        port: '5000',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Instructions
                _buildInfoCard(
                  isDark: isDark,
                  title: 'Quick Setup',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInstructionStep(
                          '1', 'Start Ollama: Run "ollama serve" in terminal'),
                      _buildInstructionStep(
                          '2', 'Start Python: Run "python backend/server.py"'),
                      _buildInstructionStep(
                          '3', 'Open Mobile App: Go to Settings'),
                      _buildInstructionStep('4', 'Enter the URLs shown above'),
                    ],
                  ),
                ),

                const Spacer(),

                // Footer
                Center(
                  child: Text(
                    'Waiting for mobile connection...',
                    style: FuturisticTheme.getMonoStyle(isDark).copyWith(
                      color: FuturisticTheme.textGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: FuturisticTheme.getGlassDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: FuturisticTheme.getTitleStyle(isDark),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCopyableField({
    required bool isDark,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    FuturisticTheme.getMonoStyle(isDark).copyWith(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: FuturisticTheme.neonCyan.withOpacity(0.3),
                  ),
                ),
                child: SelectableText(
                  value,
                  style: FuturisticTheme.getBodyStyle(isDark).copyWith(
                    fontFamily: 'monospace',
                    color: FuturisticTheme.neonCyan,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.copy, color: FuturisticTheme.neonCyan),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied: $value'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          tooltip: 'Copy',
        ),
      ],
    );
  }

  Widget _buildStatusRow({
    required bool isDark,
    required String service,
    required bool status,
    required String port,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: status ? Colors.green : Colors.red,
            boxShadow: [
              BoxShadow(
                color: (status ? Colors.green : Colors.red).withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            service,
            style: FuturisticTheme.getBodyStyle(isDark),
          ),
        ),
        Text(
          'Port $port',
          style: FuturisticTheme.getMonoStyle(isDark).copyWith(fontSize: 12),
        ),
        const SizedBox(width: 12),
        Text(
          status ? 'ONLINE' : 'OFFLINE',
          style: FuturisticTheme.getMonoStyle(isDark).copyWith(
            color: status ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: FuturisticTheme.neonCyan, width: 2),
            ),
            child: Center(
              child: Text(
                number,
                style:
                    FuturisticTheme.getMonoStyle(isDark).copyWith(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: FuturisticTheme.getBodyStyle(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
