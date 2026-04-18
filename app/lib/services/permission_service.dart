import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<PermissionStatus> requestMicrophonePermission(BuildContext context) async {
    final currentStatus = await Permission.microphone.status;
    if (currentStatus.isGranted) {
      return currentStatus;
    }

    if (!context.mounted) {
      return currentStatus;
    }

    final shouldRequest = await _showRationale(context);
    if (!shouldRequest) {
      return currentStatus;
    }

    final requested = await Permission.microphone.request();
    if (requested.isPermanentlyDenied && context.mounted) {
      await _showPermanentlyDeniedDialog(context);
    }
    return requested;
  }

  Future<bool> _showRationale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Access'),
        content: const Text(
          'We need microphone access so you can practice speaking 😊',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showPermanentlyDeniedDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Microphone permission is permanently denied. Please enable it in app settings to continue speaking practice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
