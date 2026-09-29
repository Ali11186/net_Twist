import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/session.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final Map<String, String> headers;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.headers,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final codeController = TextEditingController();

  final api = ApiService();
  final sessionService = SessionService();

  bool loading = false;
  int attempts = 0;

  Future<void> verifyCode() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      showMessage('اكتب كود التحقق');
      return;
    }

    if (attempts >= maxOtpAttempts) {
      showMessage('انتهت محاولات التحقق');
      return;
    }

    setState(() {
      loading = true;
      attempts++;
    });

    try {
      final response = await api.verifyOtp(
        phone: widget.phone,
        code: code,
        headers: widget.headers,
      );

      if (response.statusCode != 200) {
        showMessage(
          'الكود غير صحيح. المتبقي: '
          '${maxOtpAttempts - attempts}',
        );
        return;
      }

      final data = _decode(response.body);

      var token =
          data['token']?.toString() ??
          data['authorization']?.toString() ??
          '';

      if (token.isEmpty) {
        token = response.headers['authorization'] ?? '';
      }

      token = token.replaceFirst(
        RegExp(r'^Bearer\s+'),
        '',
      );

      if (token.isEmpty) {
        showMessage(
          'لم يتم استلام رمز التوثيق من الخادم',
        );
        return;
      }

      final headers =
          Map<String, String>.from(widget.headers);

      headers['authorization'] = 'Bearer $token';

      headers['access-token'] =
          _firstValue(data, const [
        'accessToken',
        'access_token',
      ]);

      headers['tg-token'] =
          _firstValue(data, const [
        'tgToken',
        'tg_token',
        'tg-token',
      ]);

      headers['tg-refresh-token'] =
          _firstValue(data, const [
        'tgRefreshToken',
        'tg_refresh_token',
        'tg-refresh-token',
      ]);

      headers['tgdeviceid'] =
          _firstValue(data, const [
        'tgDeviceId',
        'tg_device_id',
        'tgdeviceid',
      ]);

      /*
       * بعض الاستجابات لا ترجع tg-token مباشرة.
       * في هذه الحالة نستخدم الـ API token
       * للحصول على بيانات الـ profile والـ tokens.
       */
      if (headers['tg-token'] == null ||
          headers['tg-token']!.isEmpty) {
        final profile = await api.getProfileAndTokens(
          apiToken: token,
          headers: headers,
        );

        if (profile != null) {
          profile.tokens.forEach(
            (key, value) {
              if (value.isNotEmpty) {
                headers[key] = value;
              }
            },
          );
        }
      }

      final sessions =
          await sessionService.loadSessions();

      sessions.removeWhere(
        (session) => session.phone == widget.phone,
      );

      sessions.add(
        TwistSession(
          phone: widget.phone,
          headers: headers,
          lastUsed: DateTime.now(),
        ),
      );

      await sessionService.saveSessions(sessions);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            phone: widget.phone,
            headers: headers,
          ),
        ),
        (_) => false,
      );
    } catch (_) {
      showMessage(
        'حدث خطأ أثناء الاتصال بالخادم',
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String _firstValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) {
      return {};
    }

    try {
      final data = jsonDecode(body);

      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {}

    return {};
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Icon(
              Icons.sms_outlined,
              size: 70,
            ),

            const SizedBox(height: 20),

            Text(
              'أدخل كود التحقق المرسل إلى\n'
              '${widget.phone}',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'كود التحقق',
                border: OutlineInputBorder(),
              ),
            ),

            Text(
              'المحاولات: $attempts / $maxOtpAttempts',
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed:
                    loading ? null : verifyCode,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('تحقق من الكود'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
