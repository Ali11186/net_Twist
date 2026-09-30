import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final api = ApiService();

  bool loading = false;

  String normalizePhone(String value) {
    var phone = value.trim().replaceAll(' ', '');

    if (RegExp(r'^01\\d{9}$').hasMatch(phone)) {
      return '20${phone.substring(1)}';
    }

    if (RegExp(r'^\\+20\\d{10}$').hasMatch(phone)) {
      return phone.substring(1);
    }

    if (RegExp(r'^20\\d{10}$').hasMatch(phone)) {
      return phone;
    }

    return '';
  }

  Future<void> sendOtp() async {
    final phone = normalizePhone(
      phoneController.text,
    );

    if (phone.isEmpty) {
      showMessage('اكتب رقم الهاتف');
      return;
    }

    setState(() => loading = true);

    try {
      final result = await api.sendOtp(phone);

      if (result.response.statusCode != 200) {
        showMessage(
          'فشل إرسال الكود: HTTP ${result.response.statusCode}',
        );
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phone: phone,
            headers: result.headers,
          ),
        ),
      );
    } catch (_) {
      showMessage('تعذر الاتصال بالخادم');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.music_note_rounded,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'net_Twist',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text('تسجيل الدخول'),

                const SizedBox(height: 40),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: '01xxxxxxxxx',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: loading ? null : sendOtp,
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'إرسال كود التحقق',
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
}
