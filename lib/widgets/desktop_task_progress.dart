import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DesktopTaskProgress extends StatefulWidget {
  final String serverUrl;
  final String taskId;

  const DesktopTaskProgress({
    Key? key,
    required this.serverUrl,
    required this.taskId,
  }) : super(key: key);

  @override
  State<DesktopTaskProgress> createState() => _DesktopTaskProgressState();
}

class _DesktopTaskProgressState extends State<DesktopTaskProgress> {
  double progress = 0.0;
  String status = 'Starting...';
  bool isCompleted = false;
  String? error;
  String? result;

  @override
  void initState() {
    super.initState();
    _pollProgress();
  }

  Future<void> _pollProgress() async {
    while (!isCompleted && error == null) {
      try {
        final response = await http.get(
          Uri.parse('${widget.serverUrl}/tasks/${widget.taskId}'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            progress = (data['progress'] ?? 0) / 100.0;
            status = data['status'] ?? 'Processing...';
            isCompleted = data['status'] == 'completed';
            error = data['error'];
            result = data['result'];
          });

          if (isCompleted || error != null) {
            break;
          }
        }
      } catch (e) {
        setState(() {
          error = e.toString();
        });
        break;
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Desktop Processing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Progress Indicator
            if (!isCompleted && error == null) ...[
              CircularProgressIndicator(
                value: progress > 0 ? progress : null,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                status,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],

            // Completed
            if (isCompleted && error == null) ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Completed!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, result),
                child: const Text('Done'),
              ),
            ],

            // Error
            if (error != null) ...[
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],

            // Cancel button (only while processing)
            if (!isCompleted && error == null) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Helper function to show progress dialog
Future<dynamic> showDesktopTaskProgress(
  BuildContext context,
  String serverUrl,
  String taskId,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => DesktopTaskProgress(
      serverUrl: serverUrl,
      taskId: taskId,
    ),
  );
}
