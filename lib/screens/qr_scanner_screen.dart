import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    try {
      // Parse QR code data
      final data = jsonDecode(code);
      final ollamaUrl = data['ollama_url'] as String?;
      // final pythonUrl = data['python_url'] as String?; // Legacy

      if (ollamaUrl != null) {
        // Auto-configure settings
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);

        await chatProvider.updateSettings(
          desktopBridgeUrl: ollamaUrl,
          apiKey: chatProvider.currentApiKey,
          mode: AIMode.desktopClient, // Switch to Desktop Client
          cloudProvider: chatProvider.currentCloudProvider,
          cloudModel: chatProvider.currentCloudModel,
          // pythonServerUrl removed
        );

        if (mounted) {
          // Show success and go back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Connected to Desktop Bridge at ${ollamaUrl.split('://')[1].split(':')[0]}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pop(context);
        }
      } else {
        throw Exception('Invalid QR code format');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Invalid QR Code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: FuturisticTheme.getBackgroundColor(isDark),
      appBar: AppBar(
        title: Text(
          'Scan Desktop QR Code',
          style: FuturisticTheme.getTitleStyle(isDark),
        ),
        backgroundColor: FuturisticTheme.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // Overlay with instructions
          Column(
            children: [
              const SizedBox(height: 40),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Point camera at QR code on Desktop Dashboard',
                  textAlign: TextAlign.center,
                  style: FuturisticTheme.getBodyStyle(isDark).copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              // Manual entry button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Enter IP Manually'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FuturisticTheme.neonCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to settings instead
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ),
            ],
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: FuturisticTheme.neonCyan,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
