import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/theme.dart';
import '../services/socket_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  String? _testResult;
  bool _isTesting = false;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiConfig.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final targetUrl = _urlController.text.trim();
    try {
      final res = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        setState(() {
          _testSuccess = true;
          _testResult = '✓ Connected successfully! BloodBridge backend is online.';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testResult = 'Server returned HTTP ${res.statusCode}: ${res.body}';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Connection failed: $e';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _saveUrl() async {
    final newUrl = _urlController.text.trim();
    await ApiConfig.setCustomBaseUrl(newUrl);
    SocketService.init();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.greenSuccess,
          content: Text('Server URL set to: ${ApiConfig.baseUrl}. Reconnecting services...'),
        ),
      );
    }
  }

  void _usePreset(String url) {
    setState(() {
      _urlController.text = url;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '⚙️ Server & Network Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure your backend server URL for local development, Android emulators, or physical test devices.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: SocketService.isConnected ? AppTheme.greenSuccess : AppTheme.emergencyRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        SocketService.isConnected ? 'Socket.IO Online' : 'Socket.IO Connecting / Idle',
                        style: TextStyle(
                          color: SocketService.isConnected ? AppTheme.greenSuccess : AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Backend Base URL',
                      hintText: 'e.g. http://localhost:5000 or http://10.0.2.2:5000',
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Quick Presets:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Localhost (5000)'),
                        onPressed: () => _usePreset('http://localhost:5000'),
                      ),
                      ActionChip(
                        label: const Text('Android Emulator (10.0.2.2:5000)'),
                        onPressed: () => _usePreset('http://10.0.2.2:5000'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isTesting ? null : _testConnection,
                          child: _isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Test Connection'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveUrl,
                          child: const Text('Save & Apply'),
                        ),
                      ),
                    ],
                  ),

                  if (_testResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _testSuccess ? const Color(0xFFDCFCE7) : AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _testSuccess ? AppTheme.greenSuccess : AppTheme.emergencyRed,
                        ),
                      ),
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testSuccess ? AppTheme.greenSuccess : AppTheme.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
