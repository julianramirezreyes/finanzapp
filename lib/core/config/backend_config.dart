enum BackendMode {
  local,
  online;

  String get value {
    switch (this) {
      case BackendMode.local:
        return 'local';
      case BackendMode.online:
        return 'online';
    }
  }

  static BackendMode fromString(String value) {
    switch (value) {
      case 'local':
        return BackendMode.local;
      case 'online':
      default:
        return BackendMode.online;
    }
  }
}

class BackendConfig {
  final BackendMode mode;
  final String localUrl;

  const BackendConfig({
    this.mode = BackendMode.online,
    this.localUrl = 'http://192.168.40.124:8081',
  });

  static const String kProdUrl =
      'https://finanzapp-backend-z6lu.onrender.com/api';

  String get baseUrl {
    if (mode == BackendMode.online) {
      return kProdUrl;
    }
    return localUrl.endsWith('/api') ? localUrl : '$localUrl/api';
  }

  bool get isLocal => mode == BackendMode.local;
  bool get isOnline => mode == BackendMode.online;

  BackendConfig copyWith({BackendMode? mode, String? localUrl}) {
    return BackendConfig(
      mode: mode ?? this.mode,
      localUrl: localUrl ?? this.localUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackendConfig &&
        other.mode == mode &&
        other.localUrl == localUrl;
  }

  @override
  int get hashCode => mode.hashCode ^ localUrl.hashCode;
}
