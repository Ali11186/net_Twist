import 'package:flutter/material.dart';

import '../services/api_service.dart';

class PackagesScreen extends StatefulWidget {
  final Map<String, String> headers;

  const PackagesScreen({
    super.key,
    required this.headers,
  });

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final api = ApiService();

  bool loading = true;
  bool redeeming = false;

  List<Map<String, dynamic>> packages = [];

  @override
  void initState() {
    super.initState();
    loadPackages();
  }

  Future<void> loadPackages() async {
    setState(() {
      loading = true;
    });

    final result = await api.getPackages(
      widget.headers,
    );

    if (!mounted) return;

    setState(() {
      packages = result.packages;
      loading = false;
    });

    if (!result.success) {
      showMessage(
        'تعذر تحميل الباقات '
        '(HTTP ${result.statusCode})',
      );
    }
  }

  Future<void> redeem(
    Map<String, dynamic> package,
  ) async {
    final code =
        package['redeemCode']?.toString() ??
        package['redeem_code']?.toString() ??
        package['code']?.toString() ??
        '';

    if (code.isEmpty) {
      showMessage(
        'لم يتم العثور على كود الاستبدال',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الاستبدال'),
          content: const Text(
            'هل تريد تنفيذ استبدال هذه الباقة؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('استبدال'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      redeeming = true;
    });

    final result = await api.redeemPackage(
      redeemCode: code,
      headers: widget.headers,
    );

    if (!mounted) return;

    setState(() {
      redeeming = false;
    });

    if (result.success) {
      showMessage('تم تنفيذ الاستبدال بنجاح');
    } else {
      showMessage(
        'فشل الاستبدال - HTTP ${result.statusCode}',
      );
    }
  }

  String packageName(
    Map<String, dynamic> package,
  ) {
    return package['name']?.toString() ??
        package['title']?.toString() ??
        package['description']?.toString() ??
        'باقة';
  }

  String packageValue(
    Map<String, dynamic> package,
  ) {
    final units =
        package['units'] ??
        package['amount'] ??
        package['value'];

    if (units == null) {
      return '';
    }

    return '$units وحدة';
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
        title: const Text('الباقات'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : packages.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadPackages,
                  child: ListView(
                    children: const [
                      SizedBox(height: 180),
                      Center(
                        child: Text(
                          'لا توجد باقات متاحة',
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadPackages,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final package = packages[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                packageName(package),
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                packageValue(package),
                              ),

                              const SizedBox(height: 14),

                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: redeeming
                                      ? null
                                      : () => redeem(
                                            package,
                                          ),
                                  child: const Text(
                                    'استبدال',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
