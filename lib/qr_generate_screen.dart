import 'widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
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

  String get actionType {
    if (widget.qrData.contains('|')) {
      return widget.qrData.split('|')[0];
    }
    return '';
  }

  String get screenTitle {
    if (actionType == 'START') return 'İşe Başlama QR Kodu';
    if (actionType == 'FINISH') return 'İş Bitirme ve Ödeme QR Kodu';
    return 'QR Kodu';
  }

  @override
  void initState() {
    super.initState();
    // START veya FINISH QR ise her 1.5 saniyede durumu kontrol et
    if (widget.qrData.contains('|')) {
      final parts = widget.qrData.split('|');
      final aType = parts[0];
      final appId = parts[1];

      _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        _checkApplicationStatus(appId, aType);
      });
    }
  }

  Future<void> _checkApplicationStatus(String appId, String aType) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/check_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'application_id': appId}),
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success') {
          final dbStatus = res['data']['status'];
          if (aType == 'FINISH' && dbStatus == 'completed') {
            _timer?.cancel();
            if (mounted) Navigator.pop(context, 'completed');
          } else if (aType == 'START' && dbStatus == 'in_progress') {
            _timer?.cancel();
            if (mounted) Navigator.pop(context, 'in_progress');
          }
        }
      }
    } catch (_) {
      // Ağ anlık gecikmelerini yut
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
      appBar: AppBar(title: Text(screenTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                actionType == 'START'
                    ? 'İşverene bu QR kodu okutarak işi başlatın:'
                    : actionType == 'FINISH'
                        ? 'Çalışana bu QR kodu okutarak işi tamamlayın ve ödemeyi aktarın:'
                        : 'Aşağıdaki kodu okutabilirsiniz:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.qrData,
                  version: QrVersions.auto,
                  size: 220.0,
                ),
              ),
              const SizedBox(height: 20),
              // Kod Değeri ve Kopyalama Çipi
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.qrData));
                  AppToast.showSuccess(context, 'Kod panoya kopyalandı!');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kod: ${widget.qrData}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Canlı Bekleme İndikatörü
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Karşı telefonun okuması bekleniyor...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
