import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/backend_config_provider.dart';
import '../../dashboard/data/dashboard_provider.dart';
import '../domain/splash_state.dart';

/// Initial poll delay in milliseconds (fast first check).
const int kInitialPollDelayMs = 500;

/// Maximum timeout in seconds before showing error state.
const int kMaxTimeoutSeconds = 60;

/// Maximum number of retry attempts.
const int kMaxRetries = 20;

/// Exponential backoff delays in milliseconds: 500ms, 1s, 2s, 4s, 8s...
const List<int> kBackoffDelaysMs = [500, 1000, 2000, 4000, 8000];

/// Notifier that manages splash screen health polling logic.
class SplashHealthNotifier extends Notifier<SplashState> {
  Timer? _pollingTimer;
  DateTime? _startTime;
  int _retryCount = 0;

  @override
  SplashState build() {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });
    return SplashState.connecting;
  }

  /// Start polling the backend health endpoint.
  void startPolling() {
    debugPrint('[Splash] startPolling() called');
    _startTime = DateTime.now();
    _retryCount = 0;
    state = SplashState.connecting;

    _pollingTimer?.cancel();
    _scheduleNextPoll();
  }

  /// Retry after timeout or error.
  void retry() {
    _retryCount = 0;
    _startTime = DateTime.now();
    state = SplashState.connecting;
    startPolling();
  }

  void _scheduleNextPoll() {
    _pollingTimer?.cancel();

    // Use exponential backoff based on retry count
    final delayMs = _retryCount < kBackoffDelaysMs.length
        ? kBackoffDelaysMs[_retryCount]
        : kBackoffDelaysMs.last;

    debugPrint('[Splash] Next poll in ${delayMs}ms');
    _pollingTimer = Timer(Duration(milliseconds: delayMs), _executePoll);
  }

  Future<void> _executePoll() async {
    // Check if already in terminal state
    if (state == SplashState.ready || state == SplashState.error) {
      debugPrint('[Splash] Terminal state: $state');
      return;
    }

    // Check timeout
    if (_startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!).inSeconds;
      if (elapsed >= kMaxTimeoutSeconds) {
        debugPrint('[Splash] Timeout: $elapsed s');
        _pollingTimer?.cancel();
        state = SplashState.error;
        return;
      }
    }

    _retryCount++;

    bool isHealthy = false;

    try {
      final dio = ref.read(dioProvider);

      debugPrint('[Splash] Retry #$_retryCount');

      // Try POST first (wakes up Render more reliably)
      try {
        final response = await dio.post('/');
        debugPrint('[Splash] POST / → ${response.statusCode} = UP!');
        isHealthy = true;
      } on DioException catch (e) {
        // Check if we got ANY response (even 404) = backend is awake
        if (e.response?.statusCode != null) {
          debugPrint('[Splash] POST / → ${e.response?.statusCode} = UP!');
          isHealthy = true;
        } else {
          debugPrint('[Splash] POST no response, trying GET');

          // Try GET /
          try {
            final getResp = await dio.get('/');
            if (getResp.statusCode == 200 || getResp.statusCode == 404) {
              debugPrint('[Splash] GET / → ${getResp.statusCode} = UP!');
              isHealthy = true;
            }
          } catch (_) {
            // Try /health last
            try {
              final health = await dio.get('/health');
              if (health.statusCode == 200) {
                debugPrint('[Splash] GET /health �� 200 = UP!');
                isHealthy = true;
              }
            } catch (_) {
              debugPrint('[Splash] All failed');
              isHealthy = false;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Splash] Exception: $e');
    }

    if (isHealthy) {
      debugPrint('[Splash] Backend UP! Preloading dashboard...');

      // Preload dashboard data while showing splash
      try {
        await ref.read(dashboardProvider.future);
        debugPrint('[Splash] Dashboard loaded! Ready to navigate.');
      } catch (e) {
        debugPrint('[Splash] Dashboard preload failed: $e');
      }

      _pollingTimer?.cancel();
      _pollingTimer = null;
      state = SplashState.ready;
    } else if (_retryCount < kMaxRetries) {
      debugPrint('[Splash] Retry...');
      _scheduleNextPoll();
    } else {
      debugPrint('[Splash] Error state');
      state = SplashState.error;
    }
  }
}

/// Provider for splash health notifier.
final splashHealthProvider =
    NotifierProvider<SplashHealthNotifier, SplashState>(
      SplashHealthNotifier.new,
    );
