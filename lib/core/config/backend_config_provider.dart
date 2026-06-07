import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_config.dart';

const String _keyMode = 'backend_mode';
const String _keyLocalUrl = 'backend_local_url';

class BackendConfigNotifier extends AsyncNotifier<BackendConfig> {
  late SharedPreferences _prefs;

  @override
  Future<BackendConfig> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _loadConfig();
  }

  BackendConfig _loadConfig() {
    final modeStr = _prefs.getString(_keyMode) ?? 'online';
    final localUrl =
        _prefs.getString(_keyLocalUrl) ?? 'http://192.168.40.124:8081';
    return BackendConfig(
      mode: BackendMode.fromString(modeStr),
      localUrl: localUrl,
    );
  }

  Future<void> setMode(BackendMode mode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _prefs.setString(_keyMode, mode.value);
      final current = _loadConfig();
      return current.copyWith(mode: mode);
    });
  }

  Future<void> setLocalUrl(String url) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _prefs.setString(_keyLocalUrl, url);
      final current = _loadConfig();
      return current.copyWith(localUrl: url);
    });
  }

  Future<void> applyAndRestartSession() async {
    await _clearSessionAndNotify();
  }

  Future<void> _clearSessionAndNotify() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    ref.invalidate(dioProvider);
  }
}

class DioClientNotifier extends Notifier<Dio> {
  @override
  Dio build() {
    final configAsync = ref.watch(backendConfigProvider);
    return configAsync.when(
      data: (config) => _createDio(config),
      loading: () => _createDio(const BackendConfig()),
      error: (e, s) => _createDio(const BackendConfig()),
    );
  }

  Dio _createDio(BackendConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // A 401 usually means the access token expired (or wasn't refreshed yet
          // at startup). Refresh the Supabase session ONCE and retry the original
          // request — onRequest re-attaches the fresh token. Guarded against loops
          // via the __retried401 flag, so a genuinely-dead session still surfaces
          // the 401 instead of looping.
          final is401 = error.response?.statusCode == 401;
          final alreadyRetried =
              error.requestOptions.extra['__retried401'] == true;
          if (is401 && !alreadyRetried) {
            try {
              await Supabase.instance.client.auth.refreshSession();
              final opts = error.requestOptions;
              opts.extra = {...opts.extra, '__retried401': true};
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {
              // Refresh/retry failed (session truly gone) — surface the original
              // error so the UI can react instead of hanging.
            }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// Check backend health by calling a lightweight endpoint.
  /// Returns true if the backend responds successfully.
  Future<bool> checkHealth() async {
    final client = ref.read(dioProvider);
    debugPrint('[HealthCheck] Testing connection...');
    try {
      // Try root endpoint first - returns 404 if no routes match
      final response = await client.get('/');
      debugPrint('[HealthCheck] GET / → ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      debugPrint('[HealthCheck] GET / failed: $e');
      // Fallback: try /health (requires endpoint on Go)
      try {
        final fallback = await client.get('/health');
        debugPrint('[HealthCheck] GET /health → ${fallback.statusCode}');
        return fallback.statusCode == 200;
      } catch (e2) {
        debugPrint('[HealthCheck] GET /health failed: $e2');
        return false;
      }
    }
  }
}

final backendConfigProvider =
    AsyncNotifierProvider<BackendConfigNotifier, BackendConfig>(
      BackendConfigNotifier.new,
    );

final dioProvider = NotifierProvider<DioClientNotifier, Dio>(
  DioClientNotifier.new,
);

final baseUrlProvider = Provider<String>((ref) {
  final configAsync = ref.watch(backendConfigProvider);
  return configAsync.when(
    data: (config) => config.baseUrl,
    loading: () => BackendConfig.kProdUrl,
    error: (e, s) => BackendConfig.kProdUrl,
  );
});

/// Provider for checking backend health status.
final backendHealthProvider = FutureProvider<bool>((ref) async {
  final dio = ref.watch(dioProvider);
  debugPrint('[backendHealthProvider] Checking...');
  try {
    // Try root endpoint first - returns 404 if no routes match but means backend is up
    final response = await dio.get('/');
    debugPrint('[backendHealthProvider] GET / → ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 404;
  } catch (e) {
    debugPrint('[backendHealthProvider] GET / failed: $e');
    // Fallback: try /health (requires endpoint on Go)
    try {
      final fallback = await dio.get('/health');
      debugPrint(
        '[backendHealthProvider] GET /health → ${fallback.statusCode}',
      );
      return fallback.statusCode == 200;
    } catch (e2) {
      debugPrint('[backendHealthProvider] GET /health failed: $e2');
      return false;
    }
  }
});
