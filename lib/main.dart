import 'package:flutter/material.dart';

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
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  bool otpSent = false;
  bool loading = false;

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void sendOtp() {
    if (phoneController.text.trim().isEmpty) {
      showMessage('اكتب رقم الهاتف أولاً');
      return;
    }

    setState(() {
      loading = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      setState(() {
        loading = false;
        otpSent = true;
      });

      showMessage('تم طلب كود التحقق');
    });
  }

  void login() {
    if (otpController.text.trim().isEmpty) {
      showMessage('اكتب كود التحقق');
      return;
    }

    setState(() {
      loading = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.blue.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'net_Twist',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'إدارة حساب Twist بسهولة',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (otpSent) ...[
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'كود التحقق',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : (otpSent ? login : sendOtp),
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            otpSent
                                ? 'تسجيل الدخول'
                                : 'إرسال كود التحقق',
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('net_Twist'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'مرحبًا 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'لوحة التحكم',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),

          _DashboardCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'الرصيد',
            subtitle: 'عرض رصيد الـ Loyalty',
            onTap: () {},
          ),

          _DashboardCard(
            icon: Icons.task_alt_rounded,
            title: 'المهام',
            subtitle: 'عرض المهام والـ Achievements',
            onTap: () {},
          ),

          _DashboardCard(
            icon: Icons.history_rounded,
            title: 'السجل',
            subtitle: 'عرض سجل العمليات والمعاملات',
            onTap: () {},
          ),

          _DashboardCard(
            icon: Icons.card_giftcard_rounded,
            title: 'الباقات والاستبدال',
            subtitle: 'عرض الباقات المتاحة واستبدال الوحدات',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 26,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
