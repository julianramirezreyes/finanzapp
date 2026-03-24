import 'package:dio/dio.dart';
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
        _prefs.getString(_keyLocalUrl) ?? 'http://192.168.1.10:8080';
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
    await _clearSessionAndNotify();
  }

  Future<void> setLocalUrl(String url) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _prefs.setString(_keyLocalUrl, url);
      final current = _loadConfig();
      return current.copyWith(localUrl: url);
    });
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
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );

    return dio;
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
