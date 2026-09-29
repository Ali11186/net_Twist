import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class ApiService {
  Map<String, String> baseHeaders() {
    final random = Random();

    final sessionId = List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();

    return {
      'user-agent':
          'Twist-Mobile/9999 (Android; 12; SM-A217F; music; ar-AE)',
      'app_version': '9999',
      'appversion': '9999',
      'channel': 'mobileapp',
      'content-type': 'application/json',
      'platform': 'android',
      'accept': 'application/json',
      'accept-language': 'ar',
      'host': 'api.twistmena.com',
      'device_id': 'SP1A.210812.016',
      'tgdeviceid': '26284330',
      'device_token': '',
      'tg-token': '',
      'tg-refresh-token': '',
      'access-token': '',
      'sessionid': sessionId,
      'accept-encoding': 'gzip',
      'connection': 'keep-alive',
    };
  }

  Future<SendOtpResult> sendOtp(String phone) async {
    final headers = baseHeaders();

    final response = await http.post(
      Uri.parse('$apiBaseUrl/Dlogin/sendCode'),
      headers: headers,
      body: jsonEncode({
        'dial': phone,
      }),
    );

    return SendOtpResult(
      response: response,
      headers: headers,
    );
  }

  Future<http.Response> verifyOtp({
    required String phone,
    required String code,
    required Map<String, String> headers,
  }) {
    return http.post(
      Uri.parse('$apiBaseUrl/Dlogin/verify'),
      headers: headers,
      body: jsonEncode({
        'dial': phone,
        'verifyCode': code,
        'socialServiceName': '',
        'socialServiceToken': '',
      }),
    );
  }

  Future<ProfileTokensResult?> getProfileAndTokens({
    required String apiToken,
    required Map<String, String> headers,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/register/getProfile?api_token='
          '${Uri.encodeQueryComponent(apiToken)}',
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        return null;
      }

      if (response.body.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return null;
      }

      final data = Map<String, dynamic>.from(decoded);

      final result = <String, String>{};

      _extractToken(
        result,
        data,
        'tg-token',
        const [
          'tgToken',
          'tg_token',
          'tg-token',
        ],
      );

      _extractToken(
        result,
        data,
        'tg-refresh-token',
        const [
          'tgRefreshToken',
          'tg_refresh_token',
          'tg-refresh-token',
        ],
      );

      _extractToken(
        result,
        data,
        'access-token',
        const [
          'accessToken',
          'access_token',
          'access-token',
        ],
      );

      _extractToken(
        result,
        data,
        'tgdeviceid',
        const [
          'tgDeviceId',
          'tg_device_id',
          'tgdeviceid',
        ],
      );

      return ProfileTokensResult(
        tokens: result,
        data: data,
      );
    } catch (_) {
      return null;
    }
  }

  void _extractToken(
    Map<String, String> result,
    Map<String, dynamic> data,
    String headerName,
    List<String> possibleNames,
  ) {
    for (final name in possibleNames) {
      final value = data[name];

      if (value != null && value.toString().isNotEmpty) {
        result[headerName] = value.toString();
        return;
      }
    }

    final nestedCandidates = [
      data['data'],
      data['result'],
      data['profile'],
    ];

    for (final candidate in nestedCandidates) {
      if (candidate is Map) {
        final nested = Map<String, dynamic>.from(candidate);

        for (final name in possibleNames) {
          final value = nested[name];

          if (value != null && value.toString().isNotEmpty) {
            result[headerName] = value.toString();
            return;
          }
        }
      }
    }
  }

  Future<int> getBalance(
    Map<String, String> headers,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/user/loyalty/balance/details',
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        return 0;
      }

      final data = jsonDecode(response.body);

      if (data is! Map) {
        return 0;
      }

      return int.tryParse(
            data['balance']?.toString() ??
                data['data']?['balance']?.toString() ??
                '0',
          ) ??
          0;
    } catch (_) {
      return 0;
    }
  }
}

class SendOtpResult {
  final http.Response response;
  final Map<String, String> headers;

  const SendOtpResult({
    required this.response,
    required this.headers,
  });
}

class ProfileTokensResult {
  final Map<String, String> tokens;
  final Map<String, dynamic> data;

  const ProfileTokensResult({
    required this.tokens,
    required this.data,
  });
}
