import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'server_config.dart';

class QRGenerateScreen extends StatefulWidget {
  final String qrData;

  const QRGenerateScreen({super.key, this.qrData = ''});

  @override
  State<QRGenerateScreen> createState() => _QRGenerateScreenState();
}

class _QRGenerateScreenState extends State<QRGenerateScreen> {
  Timer? _timer;

  static String get _baseUrl => ServerConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    // If this is a FINISH or START QR, we should poll the server to see if the status changed.
    if (widget.qrData.contains('|')) {
      final parts = widget.qrData.split('|');
      final actionType = parts[0]; // FINISH or START
      final appId = parts[1];

      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _checkApplicationStatus(appId, actionType);
      });
    }
  }

  Future<void> _checkApplicationStatus(String appId, String actionType) async {
    try {
      // Just a direct lightweight call to check status
      final response = await http.post(
        Uri.parse('$_baseUrl/check_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'application_id': appId}),
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success') {
          final dbStatus = res['data']['status'];
          if (actionType == 'FINISH' && dbStatus == 'completed') {
            _timer?.cancel();
            if (mounted) Navigator.pop(context, 'completed');
          } else if (actionType == 'START' && dbStatus == 'in_progress') {
            _timer?.cancel();
            if (mounted) Navigator.pop(context, 'in_progress');
          }
        }
      }
    } catch (e) {
      // Ignore poll errors
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Kodum')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Aşağıdaki kodu okutabilirsiniz:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
