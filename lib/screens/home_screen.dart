import 'package:flutter/material.dart';

import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final String phone;
  final Map<String, String> headers;

  const HomeScreen({
    super.key,
    required this.phone,
    required this.headers,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final api = ApiService();

  bool loadingBalance = true;
  bool loadingTasks = false;

  int balance = 0;
  int taskCount = 0;

  @override
  void initState() {
    super.initState();
    loadBalance();
    loadTasks();
  }

  Future<void> loadBalance() async {
    if (mounted) {
      setState(() {
        loadingBalance = true;
      });
    }

    final result = await api.getBalance(widget.headers);

    if (!mounted) return;

    setState(() {
      balance = result;
      loadingBalance = false;
    });
  }

  Future<void> loadTasks() async {
    if (mounted) {
      setState(() {
        loadingTasks = true;
      });
    }

    final result = await api.getAchievements(widget.headers);

    if (!mounted) return;

    setState(() {
      taskCount = result.achievements.length;
      loadingTasks = false;
    });
  }

  Future<void> collectTasks() async {
    setState(() {
      loadingTasks = true;
    });

    final result =
        await api.collectAvailableActions(widget.headers);

    if (!mounted) return;

    setState(() {
      loadingTasks = false;
    });

    if (result.stopped) {
      showMessage(
        'توقف جمع المهام بسبب استجابة من الخادم.',
      );
    } else {
      showMessage(
        'تم جمع ${result.earned} مكافأة، '
        'ومكتمل مسبقًا: ${result.completed}',
      );
    }

    await loadBalance();
    await loadTasks();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('net_Twist'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadBalance();
          await loadTasks();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.music_note_rounded,
              size: 70,
            ),

            const SizedBox(height: 15),

            const Text(
              'مرحباً بك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.phone,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'الرصيد',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    loadingBalance
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '$balance',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.task_alt_outlined,
                ),
                title: const Text(
                  'المهام والإنجازات',
                ),
                subtitle: Text(
                  loadingTasks
                      ? 'جاري التحميل...'
                      : 'عدد المهام: $taskCount',
                ),
                trailing: loadingTasks
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    loadingTasks ? null : collectTasks,
                icon: const Icon(
                  Icons.card_giftcard_outlined,
                ),
                label: const Text(
                  'جمع المكافآت المتاحة',
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: loadingBalance
                    ? null
                    : loadBalance,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'تحديث الرصيد',
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('السجل'),
                subtitle: const Text(
                  'سيتم تفعيله في الخطوة التالية',
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.card_giftcard_outlined,
                ),
                title: const Text(
                  'الباقات والاستبدال',
                ),
                subtitle: const Text(
                  'سيتم تفعيله في الخطوة التالية',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
