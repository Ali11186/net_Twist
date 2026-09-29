import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/session_service.dart';

void main() {
  runApp(const NetTwistApp());
}

class NetTwistApp extends StatelessWidget {
  const NetTwistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'net_Twist',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
      ),
      home: const StartupScreen(),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  final sessionService = SessionService();
  final api = ApiService();

  @override
  void initState() {
    super.initState();
    checkSavedSession();
  }

  Future<void> checkSavedSession() async {
    try {
      final sessions = await sessionService.loadSessions();

      if (sessions.isEmpty) {
        goToLogin();
        return;
      }

      sessions.sort(
        (a, b) => b.lastUsed.compareTo(a.lastUsed),
      );

      final session = sessions.first;

      final valid = await api.isSessionValid(
        session.headers,
      );

      if (!mounted) return;

      if (valid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              phone: session.phone,
              headers: session.headers,
            ),
          ),
        );
      } else {
        goToLogin();
      }
    } catch (_) {
      goToLogin();
    }
  }

  void goToLogin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 70,
            ),
            SizedBox(height: 20),
            Text(
              'net_Twist',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text(
              'جاري التحقق من الجلسة...',
            ),
          ],
        ),
      ),
    );
  }
}
