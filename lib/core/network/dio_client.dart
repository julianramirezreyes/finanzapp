import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/foundation.dart';

// Use Android emulator localhost alias for now.
// For web/iOS, use localhost or machine IP.
// Android Emulator: 10.0.2.2
// iOS Simulator / Web: localhost

// PROD URL for Release Mode
const String _prodUrl = 'https://finanzapp-backend-z6lu.onrender.com/api';
// DEV URL for Local Debugging
const String _devUrl =
    'http://10.0.2.2:8080/api'; // Changed port to 8080 (standard) or keep 8081 if that's what user uses locally

const String kBaseUrl = kReleaseMode ? _prodUrl : (kIsWeb ? _prodUrl : _devUrl);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
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
        // Global error handling could go here (e.g. 401 logout)
        return handler.next(error);
      },
    ),
  );

  return dio;
});
