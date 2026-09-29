class TwistSession {
  final String phone;
  final Map<String, String> headers;
  final DateTime lastUsed;

  const TwistSession({
    required this.phone,
    required this.headers,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'headers': headers,
      'last_used': lastUsed.toIso8601String(),
    };
  }

  factory TwistSession.fromJson(Map<String, dynamic> json) {
    return TwistSession(
      phone: json['phone']?.toString() ?? '',
      headers: Map<String, String>.from(
        json['headers'] ?? <String, dynamic>{},
      ),
      lastUsed:
          DateTime.tryParse(json['last_used']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
