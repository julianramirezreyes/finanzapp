/// Enum representing the possible states of the splash screen during backend connection.
enum SplashState {
  /// Initial state - polling the backend, showing animated loading states.
  connecting,

  /// Backend responded successfully, ready to navigate.
  ready,

  /// Connection timeout or error - show retry button.
  error,
}

/// Financial-themed loading messages that cycle during connecting state.
class SplashLoadingMessages {
  SplashLoadingMessages._();

  static const List<String> cycling = [
    'Conectando...',
    'Iniciando servicios...',
    'Cargando datos...',
  ];
}

/// Extension to provide display messages for each state.
extension SplashStateExtension on SplashState {
  bool get isTerminal {
    return this == SplashState.ready || this == SplashState.error;
  }
}
