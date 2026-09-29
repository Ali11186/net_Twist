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

      if (response.statusCode != 200 || response.body.isEmpty) {
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
        const ['tgToken', 'tg_token', 'tg-token'],
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

  Future<AchievementsResult> getAchievements(
    Map<String, String> headers,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/user/loyalty/achievements/v2',
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        return AchievementsResult(
          success: false,
          statusCode: response.statusCode,
          achievements: const [],
        );
      }

      final decoded = jsonDecode(response.body);

      final achievements = _extractList(decoded);

      return AchievementsResult(
        success: true,
        statusCode: response.statusCode,
        achievements: achievements,
      );
    } catch (_) {
      return const AchievementsResult(
        success: false,
        statusCode: 0,
        achievements: [],
      );
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    if (data is Map) {
      final candidates = [
        data['badges'],
        data['achievements'],
        data['tasks'],
        data['data'],
        data['result'],
      ];

      for (final candidate in candidates) {
        final result = _extractList(candidate);

        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return [];
  }

  Future<ActionResult> collectAction({
    required String actionId,
    required Map<String, String> headers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$apiBaseUrl/loyalty/action/'
          '${Uri.encodeComponent(actionId)}',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return const ActionResult(
          success: true,
          completed: false,
          forbidden: false,
          statusCode: 200,
        );
      }

      if (response.statusCode == 400) {
        return const ActionResult(
          success: false,
          completed: true,
          forbidden: false,
          statusCode: 400,
        );
      }

      if (response.statusCode == 403) {
        return const ActionResult(
          success: false,
          completed: false,
          forbidden: true,
          statusCode: 403,
        );
      }

      return ActionResult(
        success: false,
        completed: false,
        forbidden: false,
        statusCode: response.statusCode,
      );
    } catch (_) {
      return const ActionResult(
        success: false,
        completed: false,
        forbidden: false,
        statusCode: 0,
      );
    }
  }

  Future<CollectResult> collectAvailableActions(
    Map<String, String> headers,
  ) async {
    final result = await getAchievements(headers);

    if (!result.success) {
      return CollectResult(
        success: false,
        earned: 0,
        completed: 0,
        stopped: true,
      );
    }

    var earned = 0;
    var completed = 0;
    var stopped = false;

    for (final item in result.achievements) {
      final rewarded = item['rewarded'];

      if (rewarded == true ||
          rewarded?.toString().toLowerCase() == 'true') {
        continue;
      }

      final actionId =
          item['actionId']?.toString() ??
          item['action_id']?.toString() ??
          item['id']?.toString() ??
          '';

      if (actionId.isEmpty) {
        continue;
      }

      for (var attempt = 0;
          attempt < maxCollectAttempts;
          attempt++) {
        final action = await collectAction(
          actionId: actionId,
          headers: headers,
        );

        if (action.success) {
          earned++;
          break;
        }

        if (action.completed) {
          completed++;
          break;
        }

        if (action.forbidden) {
          stopped = true;
          break;
        }

        if (action.statusCode == 0) {
          stopped = true;
          break;
        }
      }

      if (stopped) {
        break;
      }
    }

    return CollectResult(
      success: !stopped,
      earned: earned,
      completed: completed,
      stopped: stopped,
    );
  }


Future<PackagesResult> getPackages(
    Map<String, String> headers,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/user/loyalty/packages',
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        return PackagesResult(
          success: false,
          statusCode: response.statusCode,
          packages: const [],
        );
      }

      final decoded = jsonDecode(response.body);
      final packages = _extractPackages(decoded);

      return PackagesResult(
        success: true,
        statusCode: response.statusCode,
        packages: packages,
      );
    } catch (_) {
      return const PackagesResult(
        success: false,
        statusCode: 0,
        packages: [],
      );
    }
  }

  List<Map<String, dynamic>> _extractPackages(
    dynamic data,
  ) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    if (data is Map) {
      final candidates = [
        data['packages'],
        data['data'],
        data['result'],
        data['items'],
      ];

      for (final candidate in candidates) {
        final result = _extractPackages(candidate);

        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return [];
  }

  Future<RedeemResult> redeemPackage({
    required String redeemCode,
    required Map<String, String> headers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$apiBaseUrl/loyalty/redeem/'
          '${Uri.encodeComponent(redeemCode)}',
        ),
        headers: headers,
      );

      dynamic data;

      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = response.body;
        }
      }

      return RedeemResult(
        success: response.statusCode == 200,
        statusCode: response.statusCode,
        data: data,
      );
    } catch (_) {
      return const RedeemResult(
        success: false,
        statusCode: 0,
        data: null,
      );
    }
  }


  Future<bool> isSessionValid(
    Map<String, String> headers,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/user/loyalty/balance/details',
        ),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
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

class AchievementsResult {
  final bool success;
  final int statusCode;
  final List<Map<String, dynamic>> achievements;

  const AchievementsResult({
    required this.success,
    required this.statusCode,
    required this.achievements,
  });
}

class ActionResult {
  final bool success;
  final bool completed;
  final bool forbidden;
  final int statusCode;

  const ActionResult({
    required this.success,
    required this.completed,
    required this.forbidden,
    required this.statusCode,
  });
}

class CollectResult {
  final bool success;
  final int earned;
  final int completed;
  final bool stopped;

  const CollectResult({
    required this.success,
    required this.earned,
    required this.completed,
    required this.stopped,
  });
}

class PackagesResult {
  final bool success;
  final int statusCode;
  final List<Map<String, dynamic>> packages;

  const PackagesResult({
    required this.success,
    required this.statusCode,
    required this.packages,
  });
}

class RedeemResult {
  final bool success;
  final int statusCode;
  final dynamic data;

  const RedeemResult({
    required this.success,
    required this.statusCode,
    required this.data,
  });
}

