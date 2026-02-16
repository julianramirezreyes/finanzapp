import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

// Import para Supabase Export Service
import 'supabase_export.dart';

// Import condicional para web
import 'package:universal_html/html.dart' as html;

// Import condicional para dart:io (solo disponible fuera de web)
import 'dart:io' if (dart.library.html) 'io_stub.dart' as io;

// Formateador de moneda global para toda la aplicación
// Global currency formatter for the entire application
final formatoMoneda = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);

//==============================================================================
// 🌐 WEB HELPER FUNCTIONS
//==============================================================================

/// Descarga un archivo en web usando el navegador
/// Downloads a file in web using the browser
Future<void> descargarArchivoWeb(Uint8List bytes, String nombreArchivo) async {
  if (kIsWeb) {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Error al descargar archivo en web: $e');
    }
  }
}

//==============================================================================
// 🎨 THEME AND GLOBAL STYLES SECTION
//==============================================================================

class TemaApp {
  static const Color _colorPrimario = Color(0xFF00897B); // Teal oscuro
  static const Color _colorAcentoClaro = Color(0xFF4DB6AC); // Teal claro
  static const Color _colorAcentoOscuro = Color(
    0xFF80CBC4,
  ); // Teal más claro para modo oscuro
  static const Color _colorError = Color(0xFFD32F2F);
  static const Color _colorAdvertencia = Color(0xFFFFA000);

  // --- TEMA CLARO ---
  static ThemeData get temaClaro {
    final temaBase = ThemeData.light(useMaterial3: true);
    return temaBase.copyWith(
      primaryColor: _colorPrimario,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Un gris muy claro
      colorScheme: ColorScheme.fromSeed(
        seedColor: _colorPrimario,
        primary: _colorPrimario,
        secondary: _colorAcentoClaro,
        error: _colorError,
        brightness: Brightness.light,
        surface: const Color(0xFFF5F5F5),
      ),
      textTheme: GoogleFonts.interTextTheme(temaBase.textTheme).apply(
        bodyColor: const Color(0xFF333333),
        displayColor: const Color(0xFF333333),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: temaBase.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: _colorPrimario),
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFF333333),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _colorPrimario, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorPrimario,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0.5,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: _colorPrimario,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _colorPrimario,
        foregroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // --- TEMA OSCURO ---
  static ThemeData get temaOscuro {
    final temaBase = ThemeData.dark(useMaterial3: true);
    return temaBase.copyWith(
      primaryColor: _colorAcentoOscuro,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: _colorPrimario,
        primary: _colorAcentoOscuro,
        secondary: _colorAcentoOscuro,
        error: _colorError,
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
      ),
      textTheme: GoogleFonts.interTextTheme(temaBase.textTheme).apply(
        bodyColor: const Color(0xFFE0E0E0),
        displayColor: const Color(0xFFE0E0E0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: _colorAcentoOscuro),
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFFE0E0E0),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _colorAcentoOscuro, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: Colors.grey[400]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorAcentoOscuro,
          foregroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: _colorAcentoOscuro,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _colorAcentoOscuro,
        foregroundColor: Color(0xFF121212),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

//==============================================================================
// 🚀 MAIN APP SECTION (main, MyApp)
//==============================================================================

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Inicializar Hive - en web no necesita path
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final directorioAppDoc = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(directorioAppDoc.path);
    }

    // Opening all Hive boxes
    // Apertura de todas las cajas de Hive
    await Hive.openBox('debitos');
    await Hive.openBox('bancos');
    await Hive.openBox('movimientos');
    await Hive.openBox('notas');
    await Hive.openBox('ajustes');
    await Hive.openBox('metas');
    await Hive.openBox('metasHogar'); // NUEVA CAJA: Metas del Hogar
    await Hive.openBox('cuentasUVT');
    await Hive.openBox('uvtValoresIniciales');
    await Hive.openBox('bienesUVT');
    await Hive.openBox('fechaDeclaracionUVT');
    await Hive.openBox('categorias');
    await Hive.openBox('uvt');
    await Hive.openBox('recordatorios');
    await Hive.openBox('finanzasHogar'); // NUEVA CAJA: Datos del Hogar
    await Hive.openBox('historialHogarEditable');

    await initializeDateFormatting('es', null);

    // Solo ejecutar débitos automáticos si no estamos en web
    if (!kIsWeb) {
      await ejecutarDebitosAutomaticos();
    }

    runApp(const MiApp());
  } catch (e, stackTrace) {
    debugPrint('Error al inicializar la aplicación: $e');
    debugPrint('Stack trace: $stackTrace');
    // Aún así intentar ejecutar la app
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error al inicializar: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    main();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanzas Personales',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.temaClaro,
      darkTheme: TemaApp.temaOscuro,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Español
      ],
      initialRoute: '/home',
      routes: {
        '/home': (context) => const PantallaInicio(),
        '/add_account': (context) => const PantallaAgregarCuenta(),
        '/add_transaction': (context) => const PantallaAgregarMovimiento(),
        '/history': (context) => const PantallaHistorialMovimientos(),
        '/notes': (context) => const PantallaNotas(),
        '/debits': (context) => const PantallaDebitos(),
        '/budget': (context) => const PantallaPresupuesto(),
        '/uvt_control': (context) => const PantallaControlUVT(),
        '/backup': (context) => const PantallaCopiaSeguridad(),
        '/debug': (context) => const PantallaDepuracionHive(),
        '/reminders': (context) => const PantallaRecordatorios(),
        // NUEVA RUTA PARA FINANZAS HOGAR
        '/finanzas_hogar': (context) => const PantallaFinanzasHogar(),
      },
    );
  }
}

//==============================================================================
// 🏠 HOME SCREEN
//==============================================================================

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  EstadoPantallaInicio createState() => EstadoPantallaInicio();
}

class EstadoPantallaInicio extends State<PantallaInicio>
    with SingleTickerProviderStateMixin {
  final cajaBancos = Hive.box('bancos');

  @override
  void initState() {
    super.initState();
    sincronizarOrdenCuentas();
  }

  void sincronizarOrdenCuentas() {
    final cajaAjustes = Hive.box('ajustes');
    final llavesActuales = cajaBancos.keys.cast<int>().toList();
    final ordenGuardado = cajaAjustes.get('ordenCuentas');

    if (ordenGuardado == null) {
      cajaAjustes.put('ordenCuentas', llavesActuales);
    } else {
      final orden = List<int>.from(ordenGuardado);
      final llavesFaltantes = llavesActuales
          .where((k) => !orden.contains(k))
          .toList();
      if (llavesFaltantes.isNotEmpty) {
        cajaAjustes.put('ordenCuentas', [...orden, ...llavesFaltantes]);
      }
      final llavesExistentes = orden
          .where((k) => llavesActuales.contains(k))
          .toList();
      if (llavesExistentes.length != orden.length) {
        cajaAjustes.put('ordenCuentas', llavesExistentes);
      }
    }
  }

  Map<String, double> obtenerResumenMensual() {
    final cajaMovimientos = Hive.box('movimientos');
    final ahora = DateTime.now();
    double ingresos = 0;
    double gastos = 0;

    for (var mov in cajaMovimientos.values) {
      final fechaMov = DateTime.parse(mov['date']);
      if (fechaMov.year == ahora.year && fechaMov.month == ahora.month) {
        if (mov['type'] == 'Ingreso') {
          ingresos += mov['amount'];
        } else if (mov['type'] == 'Gasto') {
          gastos += mov['amount'];
        }
      }
    }
    return {
      'ingresos': ingresos,
      'gastos': gastos,
      'balance': ingresos - gastos,
    };
  }

  Map<int, double> _calcularTotalesDebitos() {
    final cajaDebitos = Hive.box('debitos');
    Map<int, double> totales = {
      for (var key in cajaBancos.keys) key as int: 0.0,
    };

    for (var debito in cajaDebitos.values) {
      final idCuenta = debito['cuentaId'];
      final monto = debito['monto'] as double;
      if (totales.containsKey(idCuenta)) {
        totales[idCuenta] = (totales[idCuenta] ?? 0.0) + monto;
      }
    }
    return totales;
  }

  double obtenerBalanceTotal() {
    return cajaBancos.values.fold(
      0.0,
      (sum, acc) => sum + (acc['balance'] ?? 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notes_outlined),
            tooltip: 'Notas',
            onPressed: () => Navigator.pushNamed(context, '/notes'),
          ),
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Historial',
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('bancos').listenable(),
        builder: (context, Box box, _) {
          sincronizarOrdenCuentas();

          final accounts = getOrderedAccounts();

          final totalesDebitos = _calcularTotalesDebitos();
          final bancosConDebitos = accounts
              .where((entry) => (totalesDebitos[entry.key] ?? 0.0) > 0)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const SizedBox(height: 16),
                _construirTarjetaBalanceTotal(obtenerBalanceTotal()),
                const SizedBox(height: 16),
                _construirTarjetaResumenMensual(obtenerResumenMensual()),
                const SizedBox(height: 24),
                _construirEncabezadoSeccion(
                  'Mis Cuentas',
                  Icons.account_balance_wallet_outlined,
                ),
                _construirListaCuentasReordenables(accounts),
                const SizedBox(height: 24),
                if (bancosConDebitos.isNotEmpty) ...[
                  _construirEncabezadoSeccion(
                    'Próximos Débitos',
                    Icons.event_repeat_outlined,
                  ),
                  _construirResumenDebitos(bancosConDebitos, totalesDebitos),
                  const SizedBox(height: 24),
                ],
                _construirTarjetaRecordatoriosProximos(),
                const SizedBox(height: 24),
                _construirTarjetaNotasRecientes(),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _construirDialVelocidad(),
    );
  }

  Widget _construirEncabezadoSeccion(String titulo, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icono, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaBalanceTotal(double balanceTotal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SALDO TOTAL',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatoMoneda.format(balanceTotal),
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaResumenMensual(Map<String, double> resumen) {
    // Asegurarse de que el resumen tenga todos los campos necesarios
    final ingresos = resumen['ingresos'] ?? 0.0;
    final gastos = resumen['gastos'] ?? 0.0;
    final balance = resumen['balance'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de ${DateFormat.yMMMM('es').format(DateTime.now())}',
              style:
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _construirFilaResumen('Ingresos', ingresos, Colors.green.shade600),
            _construirFilaResumen(
              'Gastos Totales',
              gastos,
              Colors.red.shade600,
            ),

            const Divider(height: 24),
            _construirFilaResumen(
              'Balance del Mes',
              balance,
              balance >= 0 ? Colors.green.shade600 : Colors.red.shade600,
              esNegrita: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirFilaResumen(
    String titulo,
    double monto,
    Color color, {
    bool esNegrita = false,
    double? fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontWeight: esNegrita ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize ?? 16,
            ),
          ),
          Text(
            formatoMoneda.format(monto), // Usar el formateador de moneda
            style: TextStyle(
              color: color,
              fontWeight: esNegrita ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize ?? 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirListaCuentasReordenables(
    List<MapEntry<int, dynamic>> accounts,
  ) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (indiceAntiguo, nuevoIndice) {
        if (nuevoIndice > indiceAntiguo) nuevoIndice--;

        final llavesVisibles = accounts.map((e) => e.key).toList();
        final llaveMovida = llavesVisibles.removeAt(indiceAntiguo);
        llavesVisibles.insert(nuevoIndice, llaveMovida);

        final cajaAjustes = Hive.box('ajustes');
        cajaAjustes.put('ordenCuentas', llavesVisibles);
        setState(() {});
      },
      children: accounts.asMap().entries.map((entry) {
        final index = entry.key;
        final cuenta = entry.value.value;
        final llave = entry.value.key;

        return Card(
          key: ValueKey('cuenta_${llave}_$index'),
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(26),
              child: Icon(
                Icons.account_balance,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              cuenta['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              formatoMoneda.format(cuenta['balance']),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaEditarCuenta(llaveCuenta: llave),
                ),
              ).whenComplete(() => setState(() {}));
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _construirResumenDebitos(
    List<MapEntry<int, dynamic>> bancosConDebitos,
    Map<int, double> totalesDebitos,
  ) {
    final cajaDebitos = Hive.box('debitos');
    return Column(
      children: bancosConDebitos.map((entry) {
        final key = entry.key;
        final cuenta = entry.value;
        final totalDebitoCuenta = totalesDebitos[key]!;
        final balance = cuenta['balance'] as double;
        final suficiente = balance >= totalDebitoCuenta;
        final colorEstado = suficiente
            ? Colors.green.shade600
            : TemaApp._colorAdvertencia;

        final debito = cajaDebitos.values.firstWhere(
          (d) => d['cuentaId'] == key,
          orElse: () => null,
        );
        String diasRestantesTexto = '';
        if (debito != null && debito['proximaFecha'] != null) {
          final proximaFecha = DateTime.parse(debito['proximaFecha']);
          final diasRestantes = proximaFecha.difference(DateTime.now()).inDays;
          if (diasRestantes == 0) {
            diasRestantesTexto = ' (Hoy)';
          } else if (diasRestantes > 0) {
            diasRestantesTexto = ' (Faltan $diasRestantes días)';
          } else {
            diasRestantesTexto = ' (Vencido hace ${diasRestantes.abs()} días)';
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: colorEstado.withAlpha(26),
              child: Icon(
                suficiente
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: colorEstado,
              ),
            ),
            title: Text(
              cuenta['name'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Débitos: ${formatoMoneda.format(totalDebitoCuenta)}$diasRestantesTexto',
            ),
            trailing: Text(
              formatoMoneda.format(balance),
              style: TextStyle(
                color: colorEstado,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _construirTarjetaRecordatoriosProximos() {
    final cajaRecordatorios = Hive.box('recordatorios');
    final ahora = DateTime.now();

    final recordatoriosConFechaProxima = cajaRecordatorios
        .toMap()
        .entries
        .map((entrada) {
          final recordatorio = entrada.value;
          final proximaFecha = _calcularProximaFechaRecordatorio(recordatorio);
          return MapEntry(entrada.key, {
            'data': recordatorio,
            'proximaFecha': proximaFecha,
          });
        })
        .where(
          (entrada) =>
              entrada.value['proximaFecha'] != null &&
              (entrada.value['proximaFecha'] as DateTime).isAfter(
                ahora.subtract(const Duration(days: 1)),
              ),
        )
        .toList();

    recordatoriosConFechaProxima.sort(
      (a, b) => (a.value['proximaFecha'] as DateTime).compareTo(
        b.value['proximaFecha'] as DateTime,
      ),
    );

    if (recordatoriosConFechaProxima.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirEncabezadoSeccion(
          'Próximos Recordatorios',
          Icons.alarm_on_outlined,
        ),
        Card(
          child: Column(
            children: [
              ...recordatoriosConFechaProxima.take(3).map((entrada) {
                final recordatorio = entrada.value['data'];
                final proximaFecha = entrada.value['proximaFecha'] as DateTime;
                final diasRestantes = proximaFecha.difference(ahora).inDays;
                final tieneValor =
                    recordatorio['valor'] != null && recordatorio['valor'] > 0;

                Color colorIcono;
                if (diasRestantes <= 0) {
                  colorIcono = TemaApp._colorError;
                } else if (diasRestantes <= 7) {
                  colorIcono = TemaApp._colorAdvertencia;
                } else if (diasRestantes <= 15) {
                  colorIcono = Colors.amber.shade600;
                } else if (diasRestantes <= 30) {
                  colorIcono = Colors.lightBlue.shade600;
                } else {
                  colorIcono = Theme.of(context).colorScheme.primary;
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorIcono.withAlpha(26),
                    child: Icon(Icons.alarm_on_outlined, color: colorIcono),
                  ),
                  title: Text(
                    recordatorio['nombre'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${DateFormat('dd MMM y', 'es').format(proximaFecha)} ${tieneValor ? ' - ${formatoMoneda.format(recordatorio['valor'])}' : ''}${diasRestantes >= 0 ? ' (faltan $diasRestantes días)' : ' (Vencido)'}',
                  ),
                  onTap: () => Navigator.pushNamed(context, '/reminders'),
                );
              }).toList(),
              if (recordatoriosConFechaProxima.length > 3)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/reminders'),
                  child: const Text('Ver todos los recordatorios'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirTarjetaNotasRecientes() {
    final cajaNotas = Hive.box('notas');
    final notasRecientes = cajaNotas.values.toList().reversed.take(3).toList();
    if (notasRecientes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirEncabezadoSeccion(
          'Notas Recientes',
          Icons.edit_note_outlined,
        ),
        Card(
          child: Column(
            children: [
              ...notasRecientes.map(
                (nota) => ListTile(
                  title: Text(
                    nota,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  onTap: () => Navigator.pushNamed(context, '/notes'),
                ),
              ),
              if (cajaNotas.length > 3)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/notes'),
                  child: const Text('Ver todas las notas'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  SpeedDial _construirDialVelocidad() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      overlayColor: Colors.black,
      overlayOpacity: 0.4,
      spacing: 12,
      spaceBetweenChildren: 12,
      children: [
        _construirHijoDialVelocidad(
          Icons.add_card_outlined,
          'Registrar Movimiento',
          () => Navigator.pushNamed(context, '/add_transaction'),
        ),
        _construirHijoDialVelocidad(
          Icons.account_balance_outlined,
          'Agregar Cuenta',
          () => Navigator.pushNamed(context, '/add_account'),
        ),
        // Botón para Finanzas Hogar
        _construirHijoDialVelocidad(
          Icons.home_work_outlined,
          'Finanzas Hogar',
          () => Navigator.pushNamed(context, '/finanzas_hogar'),
          color: Colors.deepPurple,
        ),
        _construirHijoDialVelocidad(
          Icons.pie_chart_outline,
          'Presupuesto & Metas',
          () => Navigator.pushNamed(context, '/budget'),
        ),
        _construirHijoDialVelocidad(
          Icons.event_repeat_outlined,
          'Débitos Automáticos',
          () => Navigator.pushNamed(context, '/debits'),
        ),
        _construirHijoDialVelocidad(
          Icons.alarm_on_outlined,
          'Recordatorios',
          () => Navigator.pushNamed(context, '/reminders'),
        ),
        _construirHijoDialVelocidad(
          Icons.assignment_outlined,
          'Control UVT / DIAN',
          () => Navigator.pushNamed(context, '/uvt_control'),
        ),
        _construirHijoDialVelocidad(
          Icons.backup_outlined,
          'Copia de Seguridad',
          () => Navigator.pushNamed(context, '/backup'),
          color: Colors.blueGrey,
        ),
        _construirHijoDialVelocidad(
          Icons.bug_report_outlined,
          'Depurar Hive',
          () => Navigator.pushNamed(context, '/debug'),
          color: Colors.orange.shade800,
        ),
      ],
    );
  }

  SpeedDialChild _construirHijoDialVelocidad(
    IconData icono,
    String etiqueta,
    VoidCallback alTocar, {
    Color? color,
  }) {
    return SpeedDialChild(
      child: Icon(icono),
      label: etiqueta,
      backgroundColor: color ?? Theme.of(context).colorScheme.secondary,
      foregroundColor: Colors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      onTap: alTocar,
    );
  }
}

//==============================================================================
// ➕ ADD ACCOUNT SCREEN
//==============================================================================

class PantallaAgregarCuenta extends StatefulWidget {
  const PantallaAgregarCuenta({super.key});

  @override
  EstadoPantallaAgregarCuenta createState() => EstadoPantallaAgregarCuenta();
}

class EstadoPantallaAgregarCuenta extends State<PantallaAgregarCuenta> {
  final _claveFormulario = GlobalKey<FormState>();
  final controladorNombre = TextEditingController();
  final controladorSaldo = TextEditingController();

  Future<void> _saveAccount() async {
    if (_claveFormulario.currentState!.validate()) {
      final nombre = controladorNombre.text.trim();
      final saldo = double.tryParse(controladorSaldo.text) ?? 0.0;

      final cajaBancos = Hive.box('bancos');
      final cajaAjustes = Hive.box('ajustes');

      final nuevaLlave = await cajaBancos.add({
        'name': nombre,
        'balance': saldo,
        'cards': [],
        'linkedAccounts': [],
      });

      // Se añade la nueva cuenta al final del orden existente.
      // The new account is added to the end of the existing order.
      final ordenActual = List<int>.from(
        cajaAjustes.get('ordenCuentas', defaultValue: []),
      );
      ordenActual.add(nuevaLlave);
      await cajaAjustes.put('ordenCuentas', ordenActual);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _claveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: controladorNombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Cuenta o Banco',
                ),
                validator: (valor) => (valor == null || valor.isEmpty)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controladorSaldo,
                decoration: const InputDecoration(
                  labelText: 'Saldo Inicial',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'El saldo es obligatorio';
                  }
                  if (double.tryParse(valor) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Guardar Cuenta'),
                onPressed: _saveAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//==============================================================================
// ✏️ EDIT ACCOUNT SCREEN
//==============================================================================
class PantallaEditarCuenta extends StatefulWidget {
  final int llaveCuenta;
  const PantallaEditarCuenta({super.key, required this.llaveCuenta});

  @override
  EstadoPantallaEditarCuenta createState() => EstadoPantallaEditarCuenta();
}

class EstadoPantallaEditarCuenta extends State<PantallaEditarCuenta> {
  final controladorNombre = TextEditingController();
  final cajaBancos = Hive.box('bancos');
  late Map _cuenta;

  // Mapa para rastrear el estado de visualización de cada tarjeta.
  // Map to track the visibility state of each card.
  final Map<int, bool> _mostrarDatosTarjeta = {};

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  void _loadAccountData() {
    _cuenta = Map.from(cajaBancos.get(widget.llaveCuenta));
    controladorNombre.text = _cuenta['name'];
  }

  // --- INICIO: FUNCIONES ACTUALIZADAS (SECCIÓN 2) ---

  /// Formatea un número de tarjeta para mostrarlo con espacios cada 4 dígitos.
  /// Formats a card number for display with spaces every 4 digits.
  String _formatCardNumberForDisplay(String? number) {
    if (number == null || number.isEmpty) return '';
    number = number.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += number[i];
    }
    return formatted;
  }

  /// Formatea un texto para mostrar solo los últimos 4 dígitos.
  /// Formats text to show only the last 4 digits.
  String _formatHiddenText(String? text, {int visibleDigits = 4}) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= visibleDigits) return '•' * text.length;
    return '•' * (text.length - visibleDigits) +
        text.substring(text.length - visibleDigits);
  }

  /// Formatea un CVV para mostrar solo el último dígito.
  /// Formats a CVV to show only the last digit.
  String _formatHiddenCVV(String? cvv) {
    if (cvv == null || cvv.isEmpty) return '';
    if (cvv.length <= 1) return '•' * cvv.length;
    return '•' * (cvv.length - 1) + cvv.substring(cvv.length - 1);
  }

  // --- FIN: FUNCIONES ACTUALIZADAS (SECCIÓN 2) ---

  void _saveChanges() {
    _cuenta['name'] = controladorNombre.text.trim();
    cajaBancos.put(widget.llaveCuenta, _cuenta);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: Text(
          'Estás a punto de eliminar "${_cuenta['name']}". Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: TemaApp._colorError),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cajaBancos.delete(widget.llaveCuenta);
      final cajaAjustes = Hive.box('ajustes');
      final orden = List<int>.from(
        cajaAjustes.get('ordenCuentas', defaultValue: []),
      );
      orden.remove(widget.llaveCuenta);
      cajaAjustes.put('ordenCuentas', orden);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cuenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: TemaApp._colorError),
            tooltip: 'Eliminar Cuenta',
            onPressed: _deleteAccount,
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: cajaBancos.listenable(keys: [widget.llaveCuenta]),
        builder: (context, box, _) {
          if (!box.containsKey(widget.llaveCuenta)) {
            // Si la cuenta fue eliminada, no intentar construir el widget.
            // If the account was deleted, do not attempt to build the widget.
            return const Center(child: Text("Esta cuenta ya no existe."));
          }
          _loadAccountData();
          final List tarjetas = _cuenta['cards'] ?? [];
          final List cuentasVinculadas = _cuenta['linkedAccounts'] ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: controladorNombre,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Cuenta',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveChanges,
                        child: const Text('Guardar Nombre'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildEditableSectionHeader(
                'Tarjetas Guardadas',
                Icons.credit_card_outlined,
                () async {
                  final tarjeta = await Navigator.push<Map<String, String>>(
                    context,
                    MaterialPageRoute(builder: (_) => PantallaAgregarTarjeta()),
                  );
                  if (tarjeta != null) {
                    final tarjetasActualizadas = [...tarjetas, tarjeta];
                    _cuenta['cards'] = tarjetasActualizadas;
                    cajaBancos.put(widget.llaveCuenta, _cuenta);
                  }
                },
              ),
              if (tarjetas.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay tarjetas guardadas.'),
                  ),
                )
              else
                ...tarjetas.asMap().entries.map(
                  (e) => _buildCardTile(e.key, e.value),
                ),
              const SizedBox(height: 24),
              _buildEditableSectionHeader(
                'Cuentas Asociadas',
                Icons.people_outline,
                () async {
                  final nuevaCuenta = await Navigator.push<Map<String, String>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PantallaAgregarCuentaVinculada(),
                    ),
                  );
                  if (nuevaCuenta != null) {
                    final cuentasActualizadas = [
                      ...cuentasVinculadas,
                      nuevaCuenta,
                    ];
                    _cuenta['linkedAccounts'] = cuentasActualizadas;
                    cajaBancos.put(widget.llaveCuenta, _cuenta);
                  }
                },
              ),
              if (cuentasVinculadas.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay cuentas asociadas.'),
                  ),
                )
              else
                ...cuentasVinculadas.asMap().entries.map(
                  (e) => _buildLinkedAccountTile(e.key, e.value),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditableSectionHeader(
    String title,
    IconData icon,
    VoidCallback onAdd,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        IconButton.filledTonal(
          icon: const Icon(Icons.add),
          tooltip: 'Agregar',
          onPressed: onAdd,
        ),
      ],
    );
  }

  // Widget para mostrar una tarjeta guardada, con lógica de ocultar/mostrar y copiar.
  // Widget to display a saved card, with hide/show and copy logic.
  Widget _buildCardTile(int index, Map card) {
    _mostrarDatosTarjeta[index] ??= false;
    final bool isVisible = _mostrarDatosTarjeta[index]!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          card['name'] ?? 'Tarjeta sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- INICIO: CAMBIOS APLICADOS (SECCIÓN 2) ---
            _buildCopiableField(
              'Número',
              isVisible
                  ? _formatCardNumberForDisplay(card['number'])
                  : _formatHiddenText(card['number']),
              card['number'] ?? '',
            ),
            _buildCopiableField(
              'Vence',
              isVisible
                  ? (card['expiry'] ?? '')
                  : _formatHiddenText(card['expiry']),
              card['expiry'] ?? '',
            ),
            _buildCopiableField(
              'CVV',
              isVisible ? (card['cvv'] ?? '') : _formatHiddenCVV(card['cvv']),
              card['cvv'] ?? '',
            ),
            // --- FIN: CAMBIOS APLICADOS (SECCIÓN 2) ---
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(
                () =>
                    _mostrarDatosTarjeta[index] = !_mostrarDatosTarjeta[index]!,
              ),
              tooltip: isVisible ? 'Ocultar datos' : 'Mostrar datos',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'Editar') {
                  final editedCard = await Navigator.push<Map<String, String>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaAgregarTarjeta(
                        initialData: Map<String, String>.from(card),
                      ),
                    ),
                  );
                  if (editedCard != null) {
                    final currentCards = List.from(_cuenta['cards']);
                    currentCards[index] = editedCard;
                    _cuenta['cards'] = currentCards;
                    cajaBancos.put(widget.llaveCuenta, _cuenta);
                  }
                } else if (value == 'Eliminar') {
                  final currentCards = List.from(_cuenta['cards']);
                  currentCards.removeAt(index);
                  _cuenta['cards'] = currentCards;
                  cajaBancos.put(widget.llaveCuenta, _cuenta);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Editar', child: Text('Editar')),
                const PopupMenuItem(value: 'Eliminar', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedAccountTile(int index, Map account) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          account['nombre']?.isNotEmpty == true
              ? account['nombre']
              : 'Cuenta sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${account['tipo']}'),
            // --- INICIO: CAMBIOS APLICADOS (SECCIÓN 2) ---
            _buildCopiableField('Cuenta', account['numero'], account['numero']),
            // --- FIN: CAMBIOS APLICADOS (SECCIÓN 2) ---
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'Editar') {
              final updatedAccount = await _showEditLinkedAccountDialog(
                account,
              );
              if (updatedAccount != null) {
                final currentAccounts = List.from(_cuenta['linkedAccounts']);
                currentAccounts[index] = updatedAccount;
                _cuenta['linkedAccounts'] = currentAccounts;
                cajaBancos.put(widget.llaveCuenta, _cuenta);
              }
            } else if (value == 'Eliminar') {
              final currentAccounts = List.from(_cuenta['linkedAccounts']);
              currentAccounts.removeAt(index);
              _cuenta['linkedAccounts'] = currentAccounts;
              cajaBancos.put(widget.llaveCuenta, _cuenta);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Editar', child: Text('Editar')),
            const PopupMenuItem(value: 'Eliminar', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>?> _showEditLinkedAccountDialog(Map account) async {
    final nameController = TextEditingController(text: account['nombre']);
    final numberController = TextEditingController(text: account['numero']);
    String type = account['tipo'];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar Cuenta Asociada'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Cuenta',
                    ),
                    items: ['Ahorro', 'Corriente', 'Llave']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => type = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: numberController,
                    // --- INICIO: CAMBIO APLICADO (SECCIÓN 2) ---
                    keyboardType: TextInputType.text, // Teclado alfanumérico
                    // --- FIN: CAMBIO APLICADO (SECCIÓN 2) ---
                    decoration: const InputDecoration(labelText: 'Cuenta'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Guardar'),
                onPressed: () {
                  Navigator.pop(context, {
                    'nombre': nameController.text.trim(),
                    'tipo': type,
                    'numero': numberController.text.trim(),
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget reutilizable para mostrar un campo con un botón de copiar.
  // Reusable widget to display a field with a copy button.
  Widget _buildCopiableField(
    String label,
    String? displayValue,
    String originalValue,
  ) {
    if (displayValue == null || displayValue.isEmpty) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: originalValue));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copiado al portapapeles.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: Text(displayValue, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.copy_all_outlined, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

//==============================================================================
// 💳 ADD CARD AND LINKED ACCOUNT SCREENS
//==============================================================================
class PantallaAgregarTarjeta extends StatelessWidget {
  final Map<String, String>? initialData;
  PantallaAgregarTarjeta({super.key, this.initialData});

  final nameController = TextEditingController();
  final numberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (initialData != null) {
      nameController.text = initialData!['name'] ?? '';
      numberController.text = initialData!['number'] ?? '';
      expiryController.text = initialData!['expiry'] ?? '';
      cvvController.text = initialData!['cvv'] ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(initialData == null ? 'Nueva Tarjeta' : 'Editar Tarjeta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la tarjeta (Ej: "Visa Gold")',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(labelText: 'Número de tarjeta'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: expiryController,
              decoration: const InputDecoration(
                labelText: 'Fecha de vencimiento (MM/AA)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cvvController,
              decoration: const InputDecoration(labelText: 'CVV'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              child: const Text('Guardar Tarjeta'),
              onPressed: () {
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'number': numberController.text.trim(),
                  'expiry': expiryController.text.trim(),
                  'cvv': cvvController.text.trim(),
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PantallaAgregarCuentaVinculada extends StatefulWidget {
  const PantallaAgregarCuentaVinculada({super.key});

  @override
  EstadoPantallaAgregarCuentaVinculada createState() =>
      EstadoPantallaAgregarCuentaVinculada();
}

class EstadoPantallaAgregarCuentaVinculada
    extends State<PantallaAgregarCuentaVinculada> {
  final nameController = TextEditingController();
  final numberController = TextEditingController();
  String accountType = 'Ahorro';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Cuenta Asociada')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre (ej: "Juan Pérez")',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: accountType,
              decoration: const InputDecoration(labelText: 'Tipo de Cuenta'),
              items: [
                'Ahorro',
                'Corriente',
                'Llave',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => accountType = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Número de cuenta o llave',
              ),
              // --- INICIO: CAMBIO APLICADO (SECCIÓN 2) ---
              keyboardType: TextInputType.text, // Permite letras y números.
              // --- FIN: CAMBIO APLICADO (SECCIÓN 2) ---
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              child: const Text('Guardar Cuenta'),
              onPressed: () {
                Navigator.pop(context, {
                  'nombre': nameController.text.trim(),
                  'tipo': accountType,
                  'numero': numberController.text.trim(),
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

//==============================================================================
// 💸 TRANSACTION MANAGEMENT SCREENS (Add, Edit, History)
//==============================================================================
class PantallaAgregarMovimiento extends StatefulWidget {
  const PantallaAgregarMovimiento({super.key});
  @override
  EstadoPantallaAgregarMovimiento createState() =>
      EstadoPantallaAgregarMovimiento();
}

class EstadoPantallaAgregarMovimiento extends State<PantallaAgregarMovimiento> {
  final _claveFormulario = GlobalKey<FormState>();
  String tipo = 'Gasto';
  double monto = 0;
  String tipoGasto = 'Personal';
  int? cuentaSeleccionada;
  int? cuentaDestino;
  int? metaSeleccionada; // NUEVO
  String descripcion = '';
  DateTime fechaSeleccionada = DateTime.now();
  bool yaReflejado = false;
  final controladorMonto = TextEditingController();
  final controladorDescripcion = TextEditingController();

  void _guardarMovimiento() {
    if (!_claveFormulario.currentState!.validate()) return;
    _claveFormulario.currentState!.save();

    final cajaMovimientos = Hive.box('movimientos');
    final cajaBancos = Hive.box('bancos');

    final datosMovimiento = {
      'type': tipo,
      'amount': monto,
      'description': descripcion,
      'date': fechaSeleccionada.toIso8601String(),
      'reflejado': yaReflejado,
      'tipoGasto': tipo == 'Gasto' ? tipoGasto : null,
      'idMetaPresupuesto': tipo == 'Gasto' ? metaSeleccionada : null, // NUEVO
      'esMetaHogar': tipo == 'Gasto' ? (tipoGasto == 'Hogar') : null, // NUEVO
    };

    if (tipo == 'Ingreso' || tipo == 'Gasto') {
      final cuenta = cajaBancos.get(cuentaSeleccionada);
      datosMovimiento['account'] = cuenta['name'];
      if (!yaReflejado) {
        final nuevoBalance =
            cuenta['balance'] + (tipo == 'Ingreso' ? monto : -monto);
        cajaBancos.put(cuentaSeleccionada, {
          ...cuenta,
          'balance': nuevoBalance,
        });
      }
    } else if (tipo == 'Transferencia') {
      final cuentaOrigen = cajaBancos.get(cuentaSeleccionada);
      final cuentaDest = cajaBancos.get(cuentaDestino);
      datosMovimiento['from'] = cuentaOrigen['name'];
      datosMovimiento['to'] = cuentaDest['name'];
      if (!yaReflejado) {
        cajaBancos.put(cuentaSeleccionada, {
          ...cuentaOrigen,
          'balance': cuentaOrigen['balance'] - monto,
        });
        cajaBancos.put(cuentaDestino, {
          ...cuentaDest,
          'balance': cuentaDest['balance'] + monto,
        });
      }
    }
    cajaMovimientos.add(datosMovimiento);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // --- INICIO: CAMBIO APLICADO (SECCIÓN 3) ---
    // Se obtienen las cuentas en el orden definido por el usuario.
    // Accounts are fetched in the user-defined order.
    final orderedAccounts = getOrderedAccounts();
    // --- FIN: CAMBIO APLICADO (SECCIÓN 3) ---

    // Preparar lista de metas según selección
    List<DropdownMenuItem<int>> menuItemsMetas = [];
    if (tipo == 'Gasto') {
      final cajaMetas = Hive.box(tipoGasto == 'Hogar' ? 'metasHogar' : 'metas');
      final metas = cajaMetas.toMap();
      menuItemsMetas = metas.entries.map((entry) {
        final meta = entry.value;
        return DropdownMenuItem<int>(
          value: entry.key,
          child: Text(
            '${meta['nombre']} (${meta['categoria']})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Movimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _claveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Movimiento',
                ),
                items: ['Gasto', 'Ingreso', 'Transferencia']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() {
                  tipo = val!;
                  cuentaSeleccionada = null;
                  cuentaDestino = null;
                  metaSeleccionada = null;
                }),
              ),
              const SizedBox(height: 16),
              if (tipo == 'Gasto') ...[
                DropdownButtonFormField<String>(
                  initialValue: tipoGasto,
                  decoration: const InputDecoration(labelText: 'Tipo de Gasto'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Personal',
                      child: Text('Personal'),
                    ),
                    DropdownMenuItem(value: 'Hogar', child: Text('Hogar')),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      tipoGasto = value ?? 'Personal';
                      metaSeleccionada = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (menuItemsMetas.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    initialValue: metaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Vincular a Meta (Opcional)',
                      helperText: 'Suma al presupuesto',
                    ),
                    items: menuItemsMetas,
                    onChanged: (val) => setState(() => metaSeleccionada = val),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              TextFormField(
                controller: controladorMonto,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                ),
                onSaved: (val) => monto = double.tryParse(val ?? '0') ?? 0,
                validator: (val) {
                  if (val == null ||
                      val.isEmpty ||
                      (double.tryParse(val) ?? 0) <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (tipo != 'Transferencia')
                DropdownButtonFormField<int>(
                  initialValue: cuentaSeleccionada,
                  hint: const Text('Seleccionar cuenta'),
                  decoration: const InputDecoration(labelText: 'Cuenta'),
                  isExpanded: true,
                  // --- INICIO: CAMBIO APLICADO (SECCIÓN 3) ---
                  items: orderedAccounts
                      .map<DropdownMenuItem<int>>(
                        (entry) => DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(entry.value['name']),
                        ),
                      )
                      .toList(),
                  // --- FIN: CAMBIO APLICADO (SECCIÓN 3) ---
                  onChanged: (val) => setState(() => cuentaSeleccionada = val),
                  validator: (val) =>
                      val == null ? 'Selecciona una cuenta' : null,
                ),
              if (tipo == 'Transferencia') ...[
                DropdownButtonFormField<int>(
                  initialValue: cuentaSeleccionada,
                  hint: const Text('Cuenta Origen'),
                  decoration: const InputDecoration(labelText: 'Desde'),
                  isExpanded: true,
                  // --- INICIO: CAMBIO APLICADO (SECCIÓN 3) ---
                  items: orderedAccounts
                      .map<DropdownMenuItem<int>>(
                        (entry) => DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text('Desde: ${entry.value['name']}'),
                        ),
                      )
                      .toList(),
                  // --- FIN: CAMBIO APLICADO (SECCIÓN 3) ---
                  onChanged: (val) => setState(() => cuentaSeleccionada = val),
                  validator: (val) => val == null ? 'Selecciona origen' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: cuentaDestino,
                  hint: const Text('Cuenta Destino'),
                  decoration: const InputDecoration(labelText: 'Hacia'),
                  isExpanded: true,
                  // --- INICIO: CAMBIO APLICADO (SECCIÓN 3) ---
                  items: orderedAccounts
                      .where((entry) => entry.key != cuentaSeleccionada)
                      .map<DropdownMenuItem<int>>(
                        (entry) => DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text('Hacia: ${entry.value['name']}'),
                        ),
                      )
                      .toList(),
                  // --- FIN: CAMBIO APLICADO (SECCIÓN 3) ---
                  onChanged: (val) => setState(() => cuentaDestino = val),
                  validator: (val) => val == null ? 'Selecciona destino' : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: controladorDescripcion,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
                onSaved: (val) => descripcion = val?.trim() ?? '',
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha del movimiento'),
                subtitle: Text(
                  DateFormat('EEEE, d MMM y', 'es').format(fechaSeleccionada),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final seleccionada = await showDatePicker(
                    context: context,
                    initialDate: fechaSeleccionada,
                    firstDate: DateTime(DateTime.now().year - 5),
                    lastDate: DateTime.now(),
                    locale: const Locale('es'),
                  );
                  if (seleccionada != null) {
                    setState(() => fechaSeleccionada = seleccionada);
                  }
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('No afectar saldo'),
                subtitle: const Text(
                  'Marcar si el movimiento ya se reflejó en el banco.',
                ),
                value: yaReflejado,
                onChanged: (val) => setState(() => yaReflejado = val),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Guardar Movimiento'),
                onPressed: _guardarMovimiento,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PantallaEditarMovimiento extends StatefulWidget {
  const PantallaEditarMovimiento({
    super.key,
    required this.llaveMovimiento,
    required this.datosMovimiento,
  });

  final dynamic llaveMovimiento;
  final Map datosMovimiento;

  @override
  EstadoPantallaEditarMovimiento createState() =>
      EstadoPantallaEditarMovimiento();
}

class EstadoPantallaEditarMovimiento extends State<PantallaEditarMovimiento> {
  late String tipo;
  late double monto;
  late String descripcion;
  late DateTime fechaSeleccionada;
  late bool yaReflejado;
  late double montoOriginal;
  late bool reflejadoOriginal;
  late String tipoGasto;
  int? metaSeleccionada; // NUEVO
  final _controladorMonto = TextEditingController();
  final _controladorDescripcion = TextEditingController();

  @override
  void initState() {
    super.initState();
    tipo = widget.datosMovimiento['type'];
    monto = widget.datosMovimiento['amount'];
    descripcion = widget.datosMovimiento['description'] ?? '';
    fechaSeleccionada = DateTime.parse(widget.datosMovimiento['date']);
    yaReflejado = widget.datosMovimiento['reflejado'] == true;
    montoOriginal = monto;
    reflejadoOriginal = yaReflejado;
    reflejadoOriginal = yaReflejado;
    tipoGasto = widget.datosMovimiento['tipoGasto'] ?? 'Personal';
    metaSeleccionada = widget.datosMovimiento['idMetaPresupuesto']; // NUEVO

    _controladorMonto.text = monto.toStringAsFixed(0);
    _controladorDescripcion.text = descripcion;
  }

  void _revertirMovimientoOriginal() {
    if (reflejadoOriginal) return;
    final cajaCuentas = Hive.box('bancos');
    if (tipo == 'Ingreso' || tipo == 'Gasto') {
      final llaveCuenta = _encontrarLlaveCuentaPorNombre(
        widget.datosMovimiento['account'],
      );
      if (llaveCuenta == null) return;
      final cuenta = cajaCuentas.get(llaveCuenta);
      final balanceOriginal =
          cuenta['balance'] +
          (tipo == 'Ingreso' ? -montoOriginal : montoOriginal);
      cajaCuentas.put(llaveCuenta, {...cuenta, 'balance': balanceOriginal});
    } else if (tipo == 'Transferencia') {
      final llaveOrigen = _encontrarLlaveCuentaPorNombre(
        widget.datosMovimiento['from'],
      );
      final llaveDestino = _encontrarLlaveCuentaPorNombre(
        widget.datosMovimiento['to'],
      );
      if (llaveOrigen == null || llaveDestino == null) return;
      final cuentaOrigen = cajaCuentas.get(llaveOrigen);
      final cuentaDestino = cajaCuentas.get(llaveDestino);
      cajaCuentas.put(llaveOrigen, {
        ...cuentaOrigen,
        'balance': cuentaOrigen['balance'] + montoOriginal,
      });
      cajaCuentas.put(llaveDestino, {
        ...cuentaDestino,
        'balance': cuentaDestino['balance'] - montoOriginal,
      });
    }
  }

  void _aplicarNuevoMovimiento() {
    if (yaReflejado) return;
    final cajaCuentas = Hive.box('bancos');
    if (tipo == 'Ingreso' || tipo == 'Gasto') {
      final llaveCuenta = _encontrarLlaveCuentaPorNombre(
        widget.datosMovimiento['account'],
      );
      if (llaveCuenta == null) return;
      final cuenta = cajaCuentas.get(llaveCuenta);
      final nuevoBalance =
          cuenta['balance'] + (tipo == 'Ingreso' ? monto : -monto);
      cajaCuentas.put(llaveCuenta, {...cuenta, 'balance': nuevoBalance});
    } else if (tipo == 'Transferencia') {
      final llaveOrigen = _encontrarLlaveCuentaPorNombre(
        widget.datosMovimiento['from'],
      );
      final llaveDestino = _encontrarLlaveCuentaPorNombre(
        widget.datosMovimiento['to'],
      );
      if (llaveOrigen == null || llaveDestino == null) return;
      final cuentaOrigen = cajaCuentas.get(llaveOrigen);
      final cuentaDestino = cajaCuentas.get(llaveDestino);
      cajaCuentas.put(llaveOrigen, {
        ...cuentaOrigen,
        'balance': cuentaOrigen['balance'] - monto,
      });
      cajaCuentas.put(llaveDestino, {
        ...cuentaDestino,
        'balance': cuentaDestino['balance'] + monto,
      });
    }
  }

  void _actualizarMovimiento() {
    if (monto <= 0) return;
    _revertirMovimientoOriginal();
    _aplicarNuevoMovimiento();
    Hive.box('movimientos').put(widget.llaveMovimiento, {
      ...widget.datosMovimiento,
      'amount': monto,
      'description': descripcion,
      'date': fechaSeleccionada.toIso8601String(),
      'reflejado': yaReflejado,
      'tipoGasto': tipo == 'Gasto' ? tipoGasto : null,
      'idMetaPresupuesto': tipo == 'Gasto' ? metaSeleccionada : null, // NUEVO
      'esMetaHogar': tipo == 'Gasto' ? (tipoGasto == 'Hogar') : null, // NUEVO
    });
    Navigator.pop(context);
  }

  int? _encontrarLlaveCuentaPorNombre(String nombre) {
    final cajaBancos = Hive.box('bancos');
    for (var key in cajaBancos.keys) {
      if (cajaBancos.get(key)['name'] == nombre) {
        return key;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Preparar lista de metas según selección
    List<DropdownMenuItem<int>> menuItemsMetas = [];
    if (tipo == 'Gasto') {
      final cajaMetas = Hive.box(tipoGasto == 'Hogar' ? 'metasHogar' : 'metas');
      final metas = cajaMetas.toMap();
      menuItemsMetas = metas.entries.map((entry) {
        final meta = entry.value;
        return DropdownMenuItem<int>(
          value: entry.key,
          child: Text(
            '${meta['nombre']} (${meta['categoria']})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Movimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Chip(
              label: Text(
                'Tipo: $tipo',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            if (tipo == 'Gasto') ...[
              DropdownButtonFormField<String>(
                initialValue: tipoGasto,
                decoration: const InputDecoration(labelText: 'Tipo de Gasto'),
                items: const [
                  DropdownMenuItem(value: 'Personal', child: Text('Personal')),
                  DropdownMenuItem(value: 'Hogar', child: Text('Hogar')),
                ],
                onChanged: (String? value) {
                  setState(() => tipoGasto = value ?? 'Personal');
                },
              ),
              const SizedBox(height: 16),
              // NUEVO: Dropdown para editar meta
              if (menuItemsMetas.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: metaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Vincular a Meta (Opcional)',
                    helperText: 'Suma al presupuesto',
                  ),
                  items: menuItemsMetas,
                  onChanged: (val) => setState(() => metaSeleccionada = val),
                  isExpanded: true,
                ),
                const SizedBox(height: 16),
              ],
            ],
            TextField(
              controller: _controladorMonto,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto'),
              onChanged: (val) => monto = double.tryParse(val) ?? 0,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorDescripcion,
              decoration: const InputDecoration(labelText: 'Descripción'),
              onChanged: (val) => descripcion = val.trim(),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha del movimiento'),
              subtitle: Text(
                DateFormat('EEEE, d MMM y', 'es').format(fechaSeleccionada),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final seleccionada = await showDatePicker(
                  context: context,
                  initialDate: fechaSeleccionada,
                  firstDate: DateTime(DateTime.now().year - 5),
                  lastDate: DateTime.now(),
                  locale: const Locale('es'),
                );
                if (seleccionada != null) {
                  setState(() => fechaSeleccionada = seleccionada);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('No afectó saldo'),
              subtitle: const Text(
                'El saldo no fue modificado por esta transacción.',
              ),
              value: yaReflejado,
              onChanged: (val) => setState(() => yaReflejado = val),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _actualizarMovimiento,
              child: const Text('Actualizar Movimiento'),
            ),
          ],
        ),
      ),
    );
  }
}

class PantallaHistorialMovimientos extends StatefulWidget {
  const PantallaHistorialMovimientos({super.key});
  @override
  EstadoPantallaHistorialMovimientos createState() =>
      EstadoPantallaHistorialMovimientos();
}

class EstadoPantallaHistorialMovimientos
    extends State<PantallaHistorialMovimientos> {
  final cajaMovimientos = Hive.box('movimientos');
  DateTime? mesSeleccionado;

  @override
  void initState() {
    super.initState();
    mesSeleccionado = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _irMesAnterior() {
    setState(
      () => mesSeleccionado = DateTime(
        mesSeleccionado!.year,
        mesSeleccionado!.month - 1,
        1,
      ),
    );
  }

  void _irMesSiguiente() {
    setState(
      () => mesSeleccionado = DateTime(
        mesSeleccionado!.year,
        mesSeleccionado!.month + 1,
        1,
      ),
    );
  }

  // 1. Asegurémonos de que el método calcularResumenMensual esté correcto
  Map<String, double> calcularResumenMensual(DateTime mes) {
    double ingresos = 0, gastos = 0, transferencias = 0;
    double gastosPersonales = 0, gastosHogar = 0;

    for (var mov in cajaMovimientos.values) {
      final fecha = DateTime.parse(mov['date']);
      if (fecha.month == mes.month && fecha.year == mes.year) {
        final monto = mov['amount'] as double;
        if (mov['type'] == 'Ingreso') {
          ingresos += monto;
        } else if (mov['type'] == 'Gasto') {
          gastos += monto;
          // Asegurarse de que el tipo de gasto se está leyendo correctamente
          final tipoGasto = mov['tipoGasto'] as String?;
          if (tipoGasto == 'Hogar') {
            gastosHogar += monto;
          } else if (tipoGasto == 'Personal') {
            gastosPersonales += monto;
          } else {
            // Si no tiene tipo, lo contamos como personal (o como prefieras)
            gastosPersonales += monto;
          }
        } else if (mov['type'] == 'Transferencia') {
          transferencias += monto;
        }
      }
    }

    double balance = ingresos - gastos;
    return {
      'ingresos': ingresos,
      'gastos': gastos,
      'gastosPersonales': gastosPersonales,
      'gastosHogar': gastosHogar,
      'movimientos': ingresos + gastos + (transferencias * 2),
      'balance': balance,
    };
  }

  Future<void> exportarMovimientosAExcel(DateTime mes) async {
    final excel = Excel.createExcel();
    final hoja = excel['Movimientos_${DateFormat('MM_yyyy').format(mes)}'];
    hoja.appendRow(const [
      'Fecha',
      'Tipo',
      'Tipo Gasto',
      'Cuenta Origen',
      'Cuenta Destino',
      'Monto',
      'Descripción',
    ]);
    for (var mov in cajaMovimientos.values) {
      final fechaMov = DateTime.parse(mov['date']);
      if (fechaMov.year == mes.year && fechaMov.month == mes.month) {
        hoja.appendRow([
          DateFormat('yyyy-MM-dd HH:mm').format(fechaMov),
          mov['type'],
          mov['tipoGasto'] ?? '',
          mov['account'] ?? mov['from'] ?? '',
          mov['to'] ?? '',
          mov['amount'],
          mov['description'] ?? '',
        ]);
      }
    }
    try {
      final nombreArchivo =
          'movimientos_${DateFormat('MMMM_yyyy', 'es').format(mes)}.xlsx';
      final bytesArchivo = excel.save();
      if (bytesArchivo != null) {
        if (kIsWeb) {
          // Descargar directamente en web
          await descargarArchivoWeb(
            Uint8List.fromList(bytesArchivo),
            nombreArchivo,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Archivo descargado: $nombreArchivo')),
            );
          }
        } else {
          // Código existente para móvil
          final dir = await obtenerRutaDescarga();
          if (dir == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo encontrar la carpeta de descargas.'),
              ),
            );
            return;
          }
          final rutaArchivo = '$dir/$nombreArchivo';
          io.File(rutaArchivo)
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytesArchivo);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Archivo guardado en: $rutaArchivo')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  Future<String?> obtenerRutaDescarga() async {
    if (kIsWeb) {
      // En web no hay ruta, se descarga directamente
      return null;
    }

    dynamic directorio;
    try {
      if (io.Platform.isIOS) {
        directorio = await getApplicationDocumentsDirectory();
      } else {
        directorio = io.Directory('/storage/emulated/0/Download');
        if (!await directorio.exists()) {
          directorio = await getExternalStorageDirectory();
        }
      }
    } catch (err) {
      debugPrint("No se pudo obtener la ruta de la carpeta de descargas");
    }
    return directorio?.path;
  }

  void _eliminarMovimiento(dynamic llave, Map mov) {
    final cajaBancos = Hive.box('bancos');
    final reflejado = mov['reflejado'] == true;
    final tipo = mov['type'];
    final monto = mov['amount'];

    int? encontrarLlave(String? n) {
      try {
        return cajaBancos.keys.firstWhere(
          (k) => cajaBancos.get(k)['name'] == n,
          orElse: () => -1,
        );
      } catch (e) {
        return null;
      }
    }

    if (!reflejado) {
      if (tipo == 'Ingreso' || tipo == 'Gasto') {
        final llaveCuenta = encontrarLlave(mov['account']);
        if (llaveCuenta != null && llaveCuenta != -1) {
          final cuenta = cajaBancos.get(llaveCuenta);
          final nuevoBalance =
              cuenta['balance'] + (tipo == 'Ingreso' ? -monto : monto);
          cajaBancos.put(llaveCuenta, {...cuenta, 'balance': nuevoBalance});
        }
      } else if (tipo == 'Transferencia') {
        final llaveOrigen = encontrarLlave(mov['from']);
        final llaveDestino = encontrarLlave(mov['to']);
        if (llaveOrigen != null &&
            llaveOrigen != -1 &&
            llaveDestino != null &&
            llaveDestino != -1) {
          final cuentaOrigen = cajaBancos.get(llaveOrigen);
          final cuentaDestino = cajaBancos.get(llaveDestino);
          cajaBancos.put(llaveOrigen, {
            ...cuentaOrigen,
            'balance': cuentaOrigen['balance'] + monto,
          });
          cajaBancos.put(llaveDestino, {
            ...cuentaDestino,
            'balance': cuentaDestino['balance'] - monto,
          });
        }
      }
    }
    cajaMovimientos.delete(llave);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _irMesAnterior,
            ),
            Expanded(
              child: Text(
                mesSeleccionado != null
                    ? DateFormat.yMMMM('es').format(mesSeleccionado!)
                    : 'Historial',
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _irMesSiguiente,
            ),
          ],
        ),
        actions: [
          if (mesSeleccionado != null)
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined),
              tooltip: 'Exportar a Excel',
              onPressed: () => exportarMovimientosAExcel(mesSeleccionado!),
            ),
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            tooltip: 'Filtrar por mes',
            onPressed: () async {
              final ahora = DateTime.now();
              final seleccionada = await showDatePicker(
                context: context,
                initialDate: mesSeleccionado ?? ahora,
                firstDate: DateTime(ahora.year - 5),
                lastDate: ahora,
                locale: const Locale('es'),
                initialEntryMode: DatePickerEntryMode.calendarOnly,
              );
              if (seleccionada != null) {
                setState(
                  () => mesSeleccionado = DateTime(
                    seleccionada.year,
                    seleccionada.month,
                  ),
                );
              }
            },
          ),
          if (mesSeleccionado != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => mesSeleccionado = null),
            ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: cajaMovimientos.listenable(),
        builder: (context, Box box, _) {
          final todasLasLlaves = box.keys.toList();
          final pares = List.generate(
            box.length,
            (i) => MapEntry(todasLasLlaves[i], box.get(todasLasLlaves[i])),
          );
          pares.sort(
            (a, b) => DateTime.parse(
              b.value['date'],
            ).compareTo(DateTime.parse(a.value['date'])),
          );
          final paresFiltrados = mesSeleccionado == null
              ? pares
              : pares.where((e) {
                  final fechaMov = DateTime.parse(e.value['date']);
                  return fechaMov.year == mesSeleccionado!.year &&
                      fechaMov.month == mesSeleccionado!.month;
                }).toList();

          if (paresFiltrados.isEmpty) {
            return const Center(
              child: Text('No hay movimientos en este periodo.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (mesSeleccionado != null)
                _construirTarjetaResumenMensualHistorial(
                  calcularResumenMensual(mesSeleccionado!),
                ),
              ...paresFiltrados.map(
                (e) => _construirTileMovimiento(e.key, e.value),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _construirTarjetaResumenMensualHistorial(Map<String, double> resumen) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del Mes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            _construirFilaResumenHistorial(
              'Ingresos',
              resumen['ingresos']!,
              Colors.green.shade600,
            ),
            _construirFilaResumenHistorial(
              'Gastos Totales',
              resumen['gastos']!,
              TemaApp._colorError,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4, bottom: 4),
              child: _construirFilaResumenHistorial(
                '• Personales',
                resumen['gastosPersonales']!,
                Colors.orange.shade600,
                fontSize: 14,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4),
              child: _construirFilaResumenHistorial(
                '• Hogar',
                resumen['gastosHogar']!,
                Colors.purple.shade600,
                fontSize: 14,
              ),
            ),
            _construirFilaResumenHistorial(
              'Balance del Mes',
              resumen['balance']!,
              resumen['balance']! >= 0
                  ? Colors.green.shade600
                  : TemaApp._colorError,
            ),
            _construirFilaResumenHistorial(
              'Total Movimientos',
              resumen['movimientos']!,
              Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirFilaResumenHistorial(
    String titulo,
    double monto,
    Color color, {
    double? fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: TextStyle(fontSize: fontSize ?? 16)),
          Text(
            formatoMoneda.format(monto),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: fontSize ?? 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTileMovimiento(dynamic llave, Map mov) {
    final fecha = DateTime.parse(mov['date']);
    final fechaFormateada = DateFormat('dd MMM, HH:mm', 'es').format(fecha);
    IconData icono;
    Color color;

    switch (mov['type']) {
      case 'Ingreso':
        icono = Icons.arrow_downward_rounded;
        color = Colors.green.shade600;
        break;
      case 'Gasto':
        icono = Icons.arrow_upward_rounded;
        color = TemaApp._colorError;
        break;
      case 'Transferencia':
        icono = Icons.swap_horiz_rounded;
        color = Colors.blue.shade600;
        break;
      default:
        icono = Icons.receipt_long_outlined;
        color = Theme.of(context).textTheme.bodySmall!.color!;
    }

    String titulo = mov['type'] == 'Transferencia'
        ? '${mov['from']} → ${mov['to']}'
        : (mov['description']?.isNotEmpty == true
              ? mov['description']
              : mov['account']);

    String subtitulo = fechaFormateada;
    if (mov['type'] == 'Gasto' && mov['tipoGasto'] != null) {
      subtitulo += ' (${mov['tipoGasto']})';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(26),
          child: Icon(icono, color: color),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitulo),
        trailing: Text(
          '${mov['type'] == 'Ingreso' ? '+' : '-'}${formatoMoneda.format(mov['amount'])}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () => _mostrarDetallesMovimiento(llave, mov, color, icono),
      ),
    );
  }

  void _mostrarDetallesMovimiento(
    dynamic llave,
    Map mov,
    Color color,
    IconData icono,
  ) {
    final fecha = DateTime.parse(mov['date']);
    final fechaFormateada = DateFormat(
      'EEEE, d MMM y, HH:mm',
      'es',
    ).format(fecha);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withAlpha(26),
                    child: Icon(icono, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      mov['type'],
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Text(
                    formatoMoneda.format(mov['amount']),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: color),
                  ),
                ],
              ),
              const Divider(height: 32),
              if (mov['description'] != null && mov['description'].isNotEmpty)
                _filaDetalle('Descripción:', mov['description']),
              if (mov['type'] == 'Ingreso' || mov['type'] == 'Gasto')
                _filaDetalle('Cuenta:', mov['account']),
              if (mov['type'] == 'Transferencia') ...[
                _filaDetalle('Desde:', mov['from']),
                _filaDetalle('Hacia:', mov['to']),
              ],
              _filaDetalle('Fecha:', fechaFormateada),
              if (mov['reflejado'] == true)
                _filaDetalle(
                  'Estado:',
                  'No afectó el saldo de la cuenta.',
                  icono: Icons.push_pin_outlined,
                ),
              if (mov['type'] == 'Gasto' && mov['tipoGasto'] != null)
                _filaDetalle(
                  'Tipo de Gasto:',
                  mov['tipoGasto'],
                  icono: Icons.category_outlined,
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TemaApp._colorError,
                      side: const BorderSide(color: TemaApp._colorError),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _eliminarMovimiento(llave, mov);
                    },
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaEditarMovimiento(
                            llaveMovimiento: llave,
                            datosMovimiento: mov,
                          ),
                        ),
                      ).whenComplete(() {
                        setState(() {});
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filaDetalle(String etiqueta, String valor, {IconData? icono}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono ?? Icons.label_important_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$etiqueta ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

//==============================================================================
// 🏡 HOME FINANCES SCREEN
//==============================================================================

class PantallaFinanzasHogar extends StatefulWidget {
  const PantallaFinanzasHogar({super.key});

  @override
  EstadoPantallaFinanzasHogar createState() => EstadoPantallaFinanzasHogar();
}

class EstadoPantallaFinanzasHogar extends State<PantallaFinanzasHogar> {
  final cajaMovimientos = Hive.box('movimientos');
  final cajaFinanzasHogar = Hive.box('finanzasHogar');
  final cajaHistorialEditable = Hive.box('historialHogarEditable');
  DateTime mesSeleccionado = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  final _controladorIngresoPareja = TextEditingController();
  final _controladorGastoPareja = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
    _asegurarCopiaMes();
    _controladorIngresoPareja.addListener(_savePartnerData);
    _controladorGastoPareja.addListener(_savePartnerData);
  }

  @override
  void dispose() {
    _controladorIngresoPareja.removeListener(_savePartnerData);
    _controladorGastoPareja.removeListener(_savePartnerData);
    _controladorIngresoPareja.dispose();
    _controladorGastoPareja.dispose();
    super.dispose();
  }

  String _getClaveMes() => DateFormat('yyyy-MM').format(mesSeleccionado);

  void _asegurarCopiaMes() {
    final clave = _getClaveMes();
    final existente = cajaHistorialEditable.get(clave);
    if (existente == null) {
      _sincronizarConOriginal();
    }
  }

  List<Map> _obtenerListaEditableMes() {
    final clave = _getClaveMes();
    final lista = cajaHistorialEditable.get(clave, defaultValue: []);
    return List<Map>.from(lista.map((e) => Map<String, dynamic>.from(e)));
  }

  void _guardarListaEditableMes(List<Map> lista) {
    final clave = _getClaveMes();
    cajaHistorialEditable.put(clave, lista);
    if (mounted) setState(() {});
  }

  String _claveMovimiento(Map m) {
    final d = m['date']?.toString() ?? '';
    final t = m['type']?.toString() ?? '';
    final a = m['amount']?.toString() ?? '';
    final desc = (m['description'] ?? '').toString();
    final acc = (m['account'] ?? m['from'] ?? '').toString();
    final to = (m['to'] ?? '').toString();
    final tg = (m['tipoGasto'] ?? '').toString();
    return '$d|$t|$a|$desc|$acc|$to|$tg';
  }

  int _buscarIndiceMovimiento(Map mov) {
    final base = _obtenerListaEditableMes();
    final k = _claveMovimiento(mov);
    for (int i = 0; i < base.length; i++) {
      if (_claveMovimiento(base[i]) == k) return i;
    }
    return -1;
  }

  void _sincronizarConOriginal() {
    final clave = _getClaveMes();
    final lista = cajaMovimientos.values
        .where((mov) {
          final fecha = DateTime.parse(mov['date']);
          final esMes =
              fecha.year == mesSeleccionado.year &&
              fecha.month == mesSeleccionado.month;
          final esHogar =
              mov['type'] == 'Ingreso' ||
              (mov['type'] == 'Gasto' && mov['tipoGasto'] == 'Hogar');
          return esMes && esHogar;
        })
        .map((m) {
          final copia = Map<String, dynamic>.from(m);
          copia['owner'] = (copia['owner'] ?? 'yo');
          return copia;
        })
        .toList();
    cajaHistorialEditable.put(clave, lista);
    if (mounted) setState(() {});
  }

  Future<void> _importarHistorialPareja() async {
    final resultado = await FilePicker.platform.pickFiles(type: FileType.any);
    if (resultado == null || resultado.files.isEmpty) return;
    final archivo = resultado.files.first;

    String contenido;
    String nombreArchivo = archivo.name;
    if (kIsWeb) {
      // En web, leer los bytes directamente
      final bytes = archivo.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudieron leer los bytes del archivo'),
            ),
          );
        }
        return;
      }
      contenido = utf8.decode(bytes);
    } else {
      // En móvil, leer desde la ruta
      final ruta = archivo.path;
      if (ruta == null) return;
      contenido = await io.File(ruta).readAsString();
      nombreArchivo = ruta;
    }
    List<Map> importados = [];
    final rutaLower = nombreArchivo.toLowerCase();
    if (rutaLower.endsWith('.json')) {
      final data = jsonDecode(contenido);
      if (data is List) {
        importados = data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } else if (rutaLower.endsWith('.csv')) {
      final lineas = contenido
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lineas.isNotEmpty) {
        final headers = lineas.first
            .split(',')
            .map((h) => h.trim().toLowerCase())
            .toList();
        for (int i = 1; i < lineas.length; i++) {
          final cols = lineas[i].split(',');
          if (cols.length < headers.length) continue;
          final Map<String, String> fila = {};
          for (int c = 0; c < headers.length; c++) {
            fila[headers[c]] = cols[c].trim();
          }

          final fechaStr = (fila['date'] ?? fila['fecha'] ?? '').trim();
          final tipoStr = (fila['type'] ?? fila['tipo'] ?? '').trim();
          final tipoGastoStr =
              (fila['tipogasto'] ??
                      fila['tipo_gasto'] ??
                      fila['categoria'] ??
                      '')
                  .trim();
          final cuentaStr =
              (fila['account'] ?? fila['cuenta'] ?? fila['from'] ?? '').trim();
          final destinoStr = (fila['to'] ?? fila['destino'] ?? '').trim();
          final montoStr = (fila['amount'] ?? fila['monto'] ?? '').trim();
          final descStr =
              (fila['descripcion'] ??
                      fila['descripción'] ??
                      fila['description'] ??
                      '')
                  .trim();

          DateTime? fecha;
          try {
            fecha = DateTime.parse(fechaStr);
          } catch (_) {
            fecha = null;
          }
          final monto =
              double.tryParse(
                montoStr.replaceAll('.', '').replaceAll(',', '.'),
              ) ??
              0;
          final tipo = tipoStr.isEmpty ? '' : tipoStr;
          if (fecha != null &&
              monto > 0 &&
              (tipo == 'Ingreso' || tipo == 'Gasto')) {
            importados.add({
              'date': fecha.toIso8601String(),
              'type': tipo,
              'tipoGasto': tipo == 'Gasto'
                  ? (tipoGastoStr.isEmpty ? 'Hogar' : tipoGastoStr)
                  : null,
              'account': cuentaStr,
              'to': destinoStr.isEmpty ? null : destinoStr,
              'amount': monto,
              'description': descStr,
            });
          }
        }
      }
    }
    int totalLeidos = 0;
    int validosMes = 0;
    int agregados = 0;
    int duplicados = 0;

    List<Map> candidatos = [];
    for (final raw in importados) {
      totalLeidos++;
      final mapa = Map<String, dynamic>.from(raw);
      final fechaStr = (mapa['date'] ?? mapa['fecha'] ?? '').toString().trim();
      final tipoStr = (mapa['type'] ?? mapa['tipo'] ?? '').toString().trim();
      final tipoGastoStr =
          (mapa['tipoGasto'] ??
                  mapa['tipogasto'] ??
                  mapa['tipo_gasto'] ??
                  mapa['categoria'] ??
                  '')
              .toString()
              .trim();
      final cuentaStr =
          (mapa['account'] ?? mapa['cuenta'] ?? mapa['from'] ?? '')
              .toString()
              .trim();
      final destinoStr = (mapa['to'] ?? mapa['destino'] ?? '')
          .toString()
          .trim();
      final dynamic valorAmount = (mapa['amount'] ?? mapa['monto']);
      double monto;
      if (valorAmount is num) {
        monto = valorAmount.toDouble();
      } else {
        final montoStr = (valorAmount ?? '').toString().trim();
        monto =
            double.tryParse(
              montoStr.replaceAll('.', '').replaceAll(',', '.'),
            ) ??
            0;
      }
      final descStr =
          (mapa['description'] ??
                  mapa['descripcion'] ??
                  mapa['descripción'] ??
                  '')
              .toString()
              .trim();

      DateTime? fecha;
      try {
        fecha = DateTime.parse(fechaStr);
      } catch (_) {
        fecha = null;
      }
      final tipo = tipoStr;
      if (fecha == null ||
          monto <= 0 ||
          (tipo != 'Ingreso' && tipo != 'Gasto')) {
        continue;
      }
      if (!(fecha.year == mesSeleccionado.year &&
          fecha.month == mesSeleccionado.month)) {
        continue;
      }
      validosMes++;
      candidatos.add({
        'date': fecha.toIso8601String(),
        'type': tipo,
        'tipoGasto': tipo == 'Gasto'
            ? (tipoGastoStr.isEmpty ? 'Hogar' : tipoGastoStr)
            : null,
        'account': cuentaStr,
        'to': destinoStr.isEmpty ? null : destinoStr,
        'amount': monto,
        'description': descStr,
      });
    }

    final aInsertar = candidatos.map((m) {
      final copia = Map<String, dynamic>.from(m);
      copia['owner'] = 'pareja';
      return copia;
    }).toList();

    final actuales = _obtenerListaEditableMes();
    final antes = actuales.length;
    final fusionados = _fusionarListasSinDuplicados(actuales, aInsertar);
    agregados = fusionados.length - antes;
    duplicados = validosMes - agregados;
    _guardarListaEditableMes(fusionados);

    if (mounted) {
      final mensaje = validosMes == 0
          ? 'No se encontraron movimientos válidos para ${DateFormat('MMMM yyyy', 'es').format(mesSeleccionado)}.'
          : 'Importación: leídos $totalLeidos, válidos $validosMes, agregados $agregados, duplicados $duplicados';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  List<Map> _fusionarListasSinDuplicados(List<Map> base, List<Map> nuevos) {
    final setClaves = <String>{};
    String k(Map m) =>
        '${m['date']}|${m['type']}|${m['amount']}|${(m['description'] ?? '').toString()}|${(m['owner'] ?? '').toString()}';
    for (final m in base) {
      setClaves.add(k(m));
    }
    final resultado = List<Map>.from(
      base.map((e) => Map<String, dynamic>.from(e)),
    );
    for (final m in nuevos) {
      if (!setClaves.contains(k(m))) {
        resultado.add(Map<String, dynamic>.from(m));
      }
    }
    return resultado;
  }

  Future<void> _agregarOModificarMovimiento({Map? mov, int? index}) async {
    final controladorDescripcion = TextEditingController(
      text: mov?['description'] ?? '',
    );
    final controladorMonto = TextEditingController(
      text: mov?['amount']?.toString() ?? '',
    );
    String tipo = mov?['type'] ?? 'Gasto';
    String tipoGasto = mov?['tipoGasto'] ?? 'Hogar';
    DateTime fecha = mov != null ? DateTime.parse(mov['date']) : DateTime.now();
    String cuenta = mov?['account'] ?? '';
    String destino = mov?['to'] ?? '';
    String propietario = (mov?['owner'] ?? 'yo').toString();

    final res = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            index == null
                ? 'Nuevo movimiento hogar'
                : 'Editar movimiento hogar',
          ),
          content: StatefulBuilder(
            builder: (context, setSt) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      items: const [
                        DropdownMenuItem(
                          value: 'Ingreso',
                          child: Text('Ingreso'),
                        ),
                        DropdownMenuItem(value: 'Gasto', child: Text('Gasto')),
                      ],
                      onChanged: (v) => setSt(() => tipo = v ?? 'Gasto'),
                      decoration: const InputDecoration(labelText: 'Tipo'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: propietario,
                      items: const [
                        DropdownMenuItem(
                          value: 'yo',
                          child: Text('Mi movimiento'),
                        ),
                        DropdownMenuItem(
                          value: 'pareja',
                          child: Text('Movimiento de mi pareja'),
                        ),
                      ],
                      onChanged: (v) => setSt(() => propietario = v ?? 'yo'),
                      decoration: const InputDecoration(
                        labelText: 'Propietario',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (tipo == 'Gasto')
                      DropdownButtonFormField<String>(
                        initialValue: tipoGasto,
                        items: const [
                          DropdownMenuItem(
                            value: 'Hogar',
                            child: Text('Hogar'),
                          ),
                          DropdownMenuItem(
                            value: 'Personal',
                            child: Text('Personal'),
                          ),
                        ],
                        onChanged: (v) => setSt(() => tipoGasto = v ?? 'Hogar'),
                        decoration: const InputDecoration(
                          labelText: 'Tipo de gasto',
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controladorDescripcion,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controladorMonto,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Monto'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(fecha),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.date_range),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: fecha,
                              firstDate: DateTime(2015),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                              locale: const Locale('es'),
                            );
                            if (d != null) {
                              setSt(
                                () => fecha = DateTime(
                                  d.year,
                                  d.month,
                                  d.day,
                                  fecha.hour,
                                  fecha.minute,
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.schedule),
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(fecha),
                            );
                            if (t != null) {
                              setSt(
                                () => fecha = DateTime(
                                  fecha.year,
                                  fecha.month,
                                  fecha.day,
                                  t.hour,
                                  t.minute,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: cuenta),
                      onChanged: (v) => cuenta = v,
                      decoration: const InputDecoration(
                        labelText: 'Cuenta Origen',
                      ),
                    ),
                    if (tipo == 'Transferencia')
                      TextField(
                        controller: TextEditingController(text: destino),
                        onChanged: (v) => destino = v,
                        decoration: const InputDecoration(
                          labelText: 'Cuenta Destino',
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    if (res != true) return;
    final monto =
        double.tryParse(
          controladorMonto.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
    if (monto <= 0) return;
    final nuevo = {
      'date': fecha.toIso8601String(),
      'type': tipo,
      'tipoGasto': tipo == 'Gasto' ? tipoGasto : null,
      'account': cuenta,
      'to': destino.isEmpty ? null : destino,
      'amount': monto,
      'description': controladorDescripcion.text.trim(),
      'owner': propietario,
    };
    final lista = _obtenerListaEditableMes();
    if (index == null) {
      lista.add(nuevo);
    } else {
      lista[index] = nuevo;
    }
    _guardarListaEditableMes(lista);
  }

  Future<void> exportarMovimientosAExcel(DateTime mes) async {
    final excel = Excel.createExcel();
    final hoja =
        excel['Movimientos_Hogar_${DateFormat('MM_yyyy').format(mes)}'];
    hoja.appendRow(const [
      'Fecha',
      'Tipo',
      'Tipo Gasto',
      'Cuenta Origen',
      'Cuenta Destino',
      'Monto',
      'Descripción',
    ]);

    final movimientosMes = _obtenerListaEditableMes();

    for (var mov in movimientosMes) {
      final fechaMov = DateTime.parse(mov['date']);
      hoja.appendRow([
        DateFormat('yyyy-MM-dd HH:mm').format(fechaMov),
        mov['type'],
        mov['tipoGasto'] ?? '',
        mov['account'] ?? mov['from'] ?? '',
        mov['to'] ?? '',
        mov['amount'],
        mov['description'] ?? '',
      ]);
    }

    try {
      final nombreArchivo =
          'movimientos_hogar_${DateFormat('MMMM_yyyy', 'es').format(mes)}.xlsx';
      final bytesArchivo = excel.save();
      if (bytesArchivo != null) {
        if (kIsWeb) {
          // Descargar directamente en web
          await descargarArchivoWeb(
            Uint8List.fromList(bytesArchivo),
            nombreArchivo,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Archivo descargado: $nombreArchivo')),
            );
          }
        } else {
          // Código existente para móvil
          final dir = await obtenerRutaDescarga();
          if (dir == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo encontrar la carpeta de descargas.'),
              ),
            );
            return;
          }
          final rutaArchivo = '$dir/$nombreArchivo';
          io.File(rutaArchivo)
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytesArchivo);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Archivo guardado en: $rutaArchivo')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  Future<String?> obtenerRutaDescarga() async {
    if (kIsWeb) {
      // En web no hay ruta, se descarga directamente
      return null;
    }

    dynamic directorio;
    try {
      if (io.Platform.isIOS) {
        directorio = await getApplicationDocumentsDirectory();
      } else {
        directorio = io.Directory('/storage/emulated/0/Download');
        if (!await directorio.exists()) {
          directorio = await getExternalStorageDirectory();
        }
      }
    } catch (err) {
      debugPrint("No se pudo obtener la ruta de la carpeta de descargas");
    }
    return directorio?.path;
  }

  Future<void> exportarMovimientosAJson(DateTime mes) async {
    try {
      final lista = _obtenerListaEditableMes().where((m) {
        final f = DateTime.parse(m['date']);
        return f.year == mes.year && f.month == mes.month;
      }).toList();
      final nombre =
          'movimientos_hogar_${DateFormat('MMMM_yyyy', 'es').format(mes)}.json';
      final jsonStr = const JsonEncoder.withIndent('  ').convert(lista);
      if (kIsWeb) {
        // Descargar directamente en web
        await SupabaseExportService.exportHomeFinanceMovements(
          lista.map((m) => Map<String, dynamic>.from(m)).toList(),
          DateFormat('MMMM_yyyy', 'es').format(mes),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Archivo descargado: $nombre'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: '¿Dónde?',
                onPressed: () {
                  _mostrarDialogoUbicacionArchivo(nombre);
                },
              ),
            ),
          );
        }
      } else {
        // Código existente para móvil
        final dir = await obtenerRutaDescarga();
        if (dir == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo encontrar la carpeta de descargas.'),
            ),
          );
          return;
        }
        final ruta = '$dir/$nombre';
        io.File(ruta)
          ..createSync(recursive: true)
          ..writeAsStringSync(jsonStr);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Archivo guardado en: $ruta')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  void _loadPartnerData() {
    final claveMes = _getClaveMes();
    final datosMes = cajaFinanzasHogar.get(claveMes, defaultValue: {});
    _controladorIngresoPareja.text = (datosMes['ingresoPareja'] ?? 0.0)
        .toStringAsFixed(0);
    _controladorGastoPareja.text = (datosMes['gastoPareja'] ?? 0.0)
        .toStringAsFixed(0);
    if (mounted) {
      setState(() {});
    }
  }

  // --- INICIO: FUNCIÓN CORREGIDA (SECCIÓN 4) ---
  /// Guarda los datos de la pareja y actualiza la UI para reflejar los cambios.
  /// Saves partner's data and updates the UI to reflect changes.
  void _savePartnerData() {
    final claveMes = _getClaveMes();
    final datosMes = cajaFinanzasHogar.get(claveMes, defaultValue: {});

    datosMes['ingresoPareja'] =
        double.tryParse(_controladorIngresoPareja.text) ?? 0.0;
    datosMes['gastoPareja'] =
        double.tryParse(_controladorGastoPareja.text) ?? 0.0;

    cajaFinanzasHogar.put(claveMes, datosMes);

    // Se llama a setState para forzar una reconstrucción del widget y
    // recalcular los totales con los nuevos valores ingresados.
    // setState is called to force a widget rebuild and recalculate
    // totals with the newly entered values.
    if (mounted) {
      setState(() {});
    }
  }
  // --- FIN: FUNCIÓN CORREGIDA (SECCIÓN 4) ---

  void _marcarComoSaldado(bool saldado) {
    final claveMes = _getClaveMes();
    final datosMes = cajaFinanzasHogar.get(claveMes, defaultValue: {});
    datosMes['saldado'] = saldado;
    cajaFinanzasHogar.put(claveMes, datosMes);
    setState(() {});
  }

  void _irMesAnterior() {
    setState(() {
      mesSeleccionado = DateTime(
        mesSeleccionado.year,
        mesSeleccionado.month - 1,
        1,
      );
      _loadPartnerData();
      _asegurarCopiaMes();
    });
  }

  void _irMesSiguiente() {
    setState(() {
      mesSeleccionado = DateTime(
        mesSeleccionado.year,
        mesSeleccionado.month + 1,
        1,
      );
      _loadPartnerData();
      _asegurarCopiaMes();
    });
  }

  Map<String, double> calcularResumenHogar(DateTime mes) {
    double misIngresos = 0;
    double misGastosHogar = 0;
    double ingresosParejaHist = 0;
    double gastosParejaHist = 0;

    final lista = _obtenerListaEditableMes();
    for (var mov in lista) {
      final fecha = DateTime.parse(mov['date']);
      if (fecha.month == mes.month && fecha.year == mes.year) {
        final monto = (mov['amount'] as num).toDouble();
        final owner = (mov['owner'] ?? 'yo').toString();
        if (mov['type'] == 'Ingreso') {
          if (owner == 'yo') {
            misIngresos += monto;
          } else {
            ingresosParejaHist += monto;
          }
        } else if (mov['type'] == 'Gasto' && mov['tipoGasto'] == 'Hogar') {
          if (owner == 'yo') {
            misGastosHogar += monto;
          } else {
            gastosParejaHist += monto;
          }
        }
      }
    }

    final ingresoParejaCampo =
        double.tryParse(_controladorIngresoPareja.text) ?? 0.0;
    final gastoParejaCampo =
        double.tryParse(_controladorGastoPareja.text) ?? 0.0;
    final ingresoPareja = ingresoParejaCampo > 0
        ? ingresoParejaCampo
        : ingresosParejaHist;
    final gastoPareja = gastoParejaCampo > 0
        ? gastoParejaCampo
        : gastosParejaHist;

    return {
      'misIngresos': misIngresos,
      'misGastosHogar': misGastosHogar,
      'ingresoPareja': ingresoPareja,
      'gastoPareja': gastoPareja,
      'totalIngresos': misIngresos + ingresoPareja,
      'totalGastosHogar': misGastosHogar + gastoPareja,
    };
  }

  void _mostrarDialogoUbicacionArchivo(String nombreArchivo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📁 ¿Dónde está mi archivo?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archivo: $nombreArchivo'),
            const SizedBox(height: 16),
            const Text(
              'Ubicación:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Carpeta de descargas de tu navegador'),
            const SizedBox(height: 12),
            const Text(
              'Para encontrarlo rápidamente:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Chrome: Ctrl+J'),
            const Text('• Firefox: Ctrl+J'),
            const Text('• Safari: Cmd+Option+L'),
            const Text('• Edge: Ctrl+J'),
            const SizedBox(height: 12),
            Text(
              '💡 Tip: Busca por nombre: "$nombreArchivo"',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _irMesAnterior,
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM('es').format(mesSeleccionado),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _irMesSiguiente,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            tooltip: 'Filtrar por mes',
            onPressed: () async {
              final ahora = DateTime.now();
              final seleccionada = await showDatePicker(
                context: context,
                initialDate: mesSeleccionado,
                firstDate: DateTime(ahora.year - 5),
                lastDate: ahora,
                locale: const Locale('es'),
              );
              if (seleccionada != null) {
                setState(() {
                  mesSeleccionado = DateTime(
                    seleccionada.year,
                    seleccionada.month,
                  );
                  _loadPartnerData();
                  _asegurarCopiaMes();
                });
              }
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: cajaHistorialEditable.listenable(),
        builder: (context, Box box, _) {
          final resumen = calcularResumenHogar(mesSeleccionado);
          final todosLosMovimientos = _obtenerListaEditableMes();

          todosLosMovimientos.sort(
            (a, b) =>
                DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCardDatosPareja(),
              const SizedBox(height: 16),
              _buildCardResumenIngresos(resumen),
              const SizedBox(height: 16),
              _buildCardResumenGastos(resumen),
              const SizedBox(height: 16),
              _buildCardLiquidacion(resumen),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Movimientos del Hogar del Mes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Añadir',
                    onPressed: () => _agregarOModificarMovimiento(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Importar',
                    onPressed: _importarHistorialPareja,
                  ),
                  IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: 'Sincronizar',
                    onPressed: _sincronizarConOriginal,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Exportar a JSON',
                    onPressed: () => exportarMovimientosAJson(mesSeleccionado),
                  ),
                ],
              ),
              const Divider(),
              if (todosLosMovimientos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text('No hay ingresos o gastos de hogar este mes.'),
                  ),
                )
              else
                ...todosLosMovimientos.asMap().entries.map((e) {
                  final i = e.key;
                  final mov = e.value;
                  return Dismissible(
                    key: ValueKey('hogar_$i'),
                    background: Container(color: Colors.redAccent),
                    onDismissed: (_) {
                      final baseIndex = _buscarIndiceMovimiento(mov);
                      if (baseIndex >= 0) {
                        final lista = _obtenerListaEditableMes();
                        lista.removeAt(baseIndex);
                        _guardarListaEditableMes(lista);
                      }
                    },
                    child: InkWell(
                      onTap: () {
                        final baseIndex = _buscarIndiceMovimiento(mov);
                        _agregarOModificarMovimiento(
                          mov: mov,
                          index: baseIndex >= 0 ? baseIndex : null,
                        );
                      },
                      child: _construirTileMovimiento(mov),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Card _buildCardDatosPareja() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos de tu Pareja',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorIngresoPareja,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              decoration: const InputDecoration(
                labelText: 'Ingreso mensual de tu pareja',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorGastoPareja,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              decoration: const InputDecoration(
                labelText: 'Gasto de hogar de tu pareja',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Card _buildCardResumenIngresos(Map<String, double> resumen) {
    final totalIngresos = resumen['totalIngresos']!;
    final misIngresos = resumen['misIngresos']!;
    final ingresoPareja = resumen['ingresoPareja']!;

    final miPorcentaje = totalIngresos > 0
        ? (misIngresos / totalIngresos) * 100
        : 0;
    final porcentajePareja = totalIngresos > 0
        ? (ingresoPareja / totalIngresos) * 100
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Ingresos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 20),
            _buildFilaResumen(
              'Mis Ingresos',
              misIngresos,
              Colors.blue,
              '${miPorcentaje.toStringAsFixed(1)}%',
            ),
            _buildFilaResumen(
              'Ingresos Pareja',
              ingresoPareja,
              Colors.pink,
              '${porcentajePareja.toStringAsFixed(1)}%',
            ),
            const Divider(height: 20),
            _buildFilaResumen(
              'Total Ingresos',
              totalIngresos,
              Theme.of(context).textTheme.bodyLarge!.color!,
              '100%',
              true,
            ),
          ],
        ),
      ),
    );
  }

  Card _buildCardResumenGastos(Map<String, double> resumen) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Gastos del Hogar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 20),
            _buildFilaResumen(
              'Mis Gastos Hogar',
              resumen['misGastosHogar']!,
              Colors.blue,
            ),
            _buildFilaResumen(
              'Gastos Hogar Pareja',
              resumen['gastoPareja']!,
              Colors.pink,
            ),
            const Divider(height: 20),
            _buildFilaResumen(
              'Total Gastos Hogar',
              resumen['totalGastosHogar']!,
              Theme.of(context).textTheme.bodyLarge!.color!,
              '',
              true,
            ),
          ],
        ),
      ),
    );
  }

  Card _buildCardLiquidacion(Map<String, double> resumen) {
    final totalIngresos = resumen['totalIngresos']!;
    final misIngresos = resumen['misIngresos']!;
    final totalGastos = resumen['totalGastosHogar']!;
    final misGastos = resumen['misGastosHogar']!;

    String mensaje = 'Ingresa los datos para calcular.';
    double diferencia = 0;

    if (totalIngresos > 0 && totalGastos > 0) {
      final miPorcentajeIngreso = misIngresos / totalIngresos;
      final miAporteIdeal = totalGastos * miPorcentajeIngreso;
      diferencia = miAporteIdeal - misGastos;

      if (diferencia > 0) {
        mensaje = 'Debes transferir a tu pareja:';
      } else if (diferencia < 0) {
        mensaje = 'Tu pareja debe transferirte:';
      } else {
        mensaje = 'Las cuentas están saldadas.';
      }
    }

    final claveMes = _getClaveMes();
    final bool saldado =
        cajaFinanzasHogar.get(claveMes, defaultValue: {})['saldado'] ?? false;

    return Card(
      color: saldado ? Colors.green.shade50 : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Liquidación del Mes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 20),
            Text(mensaje, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              formatoMoneda.format(diferencia.abs()),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: diferencia > 0
                    ? Colors.red.shade700
                    : Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Marcar como saldado'),
              value: saldado,
              onChanged: (diferencia != 0)
                  ? (value) => _marcarComoSaldado(value)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaResumen(
    String titulo,
    double monto,
    Color color, [
    String? porcentaje,
    bool esNegrita = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 5),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontWeight: esNegrita ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (porcentaje != null)
            Text(
              porcentaje,
              style: TextStyle(
                fontWeight: esNegrita ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey.shade600,
              ),
            ),
          const SizedBox(width: 10),
          Text(
            formatoMoneda.format(monto),
            style: TextStyle(
              fontWeight: esNegrita ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTileMovimiento(Map mov) {
    IconData icono;
    Color color;

    switch (mov['type']) {
      case 'Ingreso':
        icono = Icons.arrow_downward_rounded;
        color = Colors.green.shade600;
        break;
      case 'Gasto':
        icono = Icons.arrow_upward_rounded;
        color = TemaApp._colorError;
        break;
      default:
        icono = Icons.receipt_long_outlined;
        color = Theme.of(context).textTheme.bodySmall!.color!;
    }
    final titulo = (mov['description']?.toString().isNotEmpty == true)
        ? mov['description']
        : (mov['account']?.toString().isNotEmpty == true ? mov['account'] : '');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(26),
          child: Icon(icono, color: color),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('dd MMM, HH:mm', 'es').format(DateTime.parse(mov['date']))} · ${(mov['owner'] ?? 'yo') == 'yo' ? 'Mío' : 'Pareja'}',
        ),
        trailing: Text(
          '${mov['type'] == 'Ingreso' ? '+' : '-'}${formatoMoneda.format(mov['amount'])}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

//==============================================================================
// 🔄 AUTOMATIC DEBITS SCREEN
//==============================================================================

class PantallaDebitos extends StatefulWidget {
  const PantallaDebitos({super.key});

  @override
  EstadoPantallaDebitos createState() => EstadoPantallaDebitos();
}

class EstadoPantallaDebitos extends State<PantallaDebitos> {
  final cajaDebitos = Hive.box('debitos');
  final cajaBancos = Hive.box('bancos');

  void _mostrarDialogoDebito({int? llave, Map? debito}) {
    final controladorNombre = TextEditingController(
      text: debito?['nombre'] ?? '',
    );
    final controladorMonto = TextEditingController(
      text: debito?['monto']?.toString() ?? '',
    );
    int diaSeleccionado = debito?['dia'] ?? 1;
    int? idCuentaSeleccionada = debito?['cuentaId'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          llave == null ? 'Nuevo Débito Automático' : 'Editar Débito',
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter establecerEstado) {
            // --- INICIO: CAMBIO APLICADO (SECCIÓN 3) ---
            final orderedAccounts = getOrderedAccounts();
            // --- FIN: CAMBIO APLICADO (SECCIÓN 3) ---

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextField(
                    controller: controladorNombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre (Ej: Netflix, Arriendo)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controladorMonto,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: diaSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Día del cobro',
                    ),
                    items: List.generate(28, (i) => i + 1)
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text('Día $d de cada mes'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        establecerEstado(() => diaSeleccionado = val!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: idCuentaSeleccionada,
                    hint: const Text('Seleccionar cuenta a debitar'),
                    decoration: const InputDecoration(
                      labelText: 'Cuenta de Origen',
                    ),
                    isExpanded: true,
                    // --- INICIO: CAMBIO APLICADO (SECCIÓN 3) ---
                    items: orderedAccounts.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value['name']),
                      );
                    }).toList(),
                    // --- FIN: CAMBIO APLICADO (SECCIÓN 3) ---
                    onChanged: (val) =>
                        establecerEstado(() => idCuentaSeleccionada = val!),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Guardar'),
            onPressed: () {
              final nombre = controladorNombre.text.trim();
              final monto = double.tryParse(controladorMonto.text) ?? 0;
              if (nombre.isNotEmpty &&
                  monto > 0 &&
                  idCuentaSeleccionada != null) {
                final datos = {
                  'nombre': nombre,
                  'monto': monto,
                  'dia': diaSeleccionado,
                  'cuentaId': idCuentaSeleccionada,
                  'ultimaEjecucion': debito?['ultimaEjecucion'],
                };
                datos['proximaFecha'] = debito?['proximaFecha'];
                if (llave == null) {
                  cajaDebitos.add(datos);
                } else {
                  cajaDebitos.put(llave, datos);
                }
                Navigator.pop(context);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Débitos Automáticos')),
      body: ValueListenableBuilder(
        valueListenable: cajaDebitos.listenable(),
        builder: (context, Box box, _) {
          final debitos = box.toMap();
          if (debitos.isEmpty) {
            return const Center(
              child: Text('No has configurado débitos automáticos.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(8),
            children: debitos.entries.map((entrada) {
              final debito = entrada.value;
              final cuenta = cajaBancos.get(debito['cuentaId']);
              String proximaFecha;
              if (debito['proximaFecha'] != null) {
                proximaFecha = DateFormat(
                  'dd/MM/yyyy',
                ).format(DateTime.parse(debito['proximaFecha']));
              } else {
                proximaFecha = 'Pendiente';
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.event_repeat_outlined),
                  ),
                  title: Text(
                    debito['nombre'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Día ${debito['dia']} de cada mes\n'
                    'Desde: ${cuenta?['name'] ?? 'N/A'}\n'
                    'Próximo cobro: $proximaFecha',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatoMoneda.format(debito['monto']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (valor) {
                          if (valor == 'Editar') {
                            _mostrarDialogoDebito(
                              llave: entrada.key,
                              debito: debito,
                            );
                          } else if (valor == 'Eliminar') {
                            cajaDebitos.delete(entrada.key);
                            setState(() {});
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Editar',
                            child: Text('Editar'),
                          ),
                          const PopupMenuItem(
                            value: 'Eliminar',
                            child: Text('Eliminar'),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoDebito(),
        label: const Text('Nuevo Débito'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

//==============================================================================
// 📝 NOTES SCREEN
//==============================================================================

class PantallaNotas extends StatefulWidget {
  const PantallaNotas({super.key});

  @override
  EstadoPantallaNotas createState() => EstadoPantallaNotas();
}

class EstadoPantallaNotas extends State<PantallaNotas> {
  final cajaNotas = Hive.box('notas');
  final TextEditingController _controlador = TextEditingController();

  void _mostrarDialogoNota({int? llave, String? textoExistente}) {
    _controlador.text = textoExistente ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(llave == null ? 'Nueva Nota' : 'Editar Nota'),
        content: TextField(
          controller: _controlador,
          autofocus: true,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Escribe tus ideas, recordatorios, etc.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Guardar'),
            onPressed: () {
              final texto = _controlador.text.trim();
              if (texto.isNotEmpty) {
                if (llave == null) {
                  cajaNotas.add(texto);
                } else {
                  cajaNotas.put(llave, texto);
                }
              }
              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notas Rápidas')),
      body: ValueListenableBuilder(
        valueListenable: cajaNotas.listenable(),
        builder: (context, Box box, _) {
          final notas = box.toMap().entries.toList();
          if (notas.isEmpty) {
            return const Center(child: Text('No hay notas guardadas.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notas.length,
            itemBuilder: (context, indice) {
              final entrada = notas[indice];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: ListTile(
                  title: Text(
                    entrada.value,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _mostrarDialogoNota(
                    llave: entrada.key,
                    textoExistente: entrada.value,
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: TemaApp._colorError,
                    ),
                    onPressed: () {
                      cajaNotas.delete(entrada.key);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nueva Nota',
        child: const Icon(Icons.add),
        onPressed: () => _mostrarDialogoNota(),
      ),
    );
  }
}

//==============================================================================
// ⏰ REMINDERS SCREEN
//==============================================================================

class PantallaRecordatorios extends StatefulWidget {
  const PantallaRecordatorios({super.key});

  @override
  EstadoPantallaRecordatorios createState() => EstadoPantallaRecordatorios();
}

class EstadoPantallaRecordatorios extends State<PantallaRecordatorios> {
  final cajaRecordatorios = Hive.box('recordatorios');
  final TextEditingController _controladorNombre = TextEditingController();
  final TextEditingController _controladorValor = TextEditingController();
  final TextEditingController _controladorNotas = TextEditingController();

  String _tipoFrecuencia = 'Una vez';
  DateTime _fechaSeleccionada = DateTime.now();
  int? _diaSeleccionado;
  int? _mesSeleccionado;

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorValor.dispose();
    _controladorNotas.dispose();
    super.dispose();
  }

  void _mostrarDialogoRecordatorio({int? llave, Map? recordatorioExistente}) {
    _controladorNombre.text = recordatorioExistente?['nombre'] ?? '';
    _controladorValor.text = recordatorioExistente?['valor']?.toString() ?? '';
    _controladorNotas.text = recordatorioExistente?['notas'] ?? '';

    _tipoFrecuencia = recordatorioExistente?['tipoFrecuencia'] ?? 'Una vez';
    if (recordatorioExistente != null) {
      if (_tipoFrecuencia == 'Una vez' &&
          recordatorioExistente['fecha'] != null) {
        _fechaSeleccionada = DateTime.parse(recordatorioExistente['fecha']);
      } else if (_tipoFrecuencia == 'Mensual' &&
          recordatorioExistente['dia'] != null) {
        _diaSeleccionado = recordatorioExistente['dia'] as int;
        _fechaSeleccionada = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          _diaSeleccionado ?? 1,
        );
      } else if (_tipoFrecuencia == 'Anual' &&
          recordatorioExistente['dia'] != null &&
          recordatorioExistente['mes'] != null) {
        _diaSeleccionado = recordatorioExistente['dia'] as int;
        _mesSeleccionado = recordatorioExistente['mes'] as int;
        _fechaSeleccionada = DateTime(
          DateTime.now().year,
          _mesSeleccionado ?? 1,
          _diaSeleccionado ?? 1,
        );
      } else {
        _fechaSeleccionada = DateTime.now();
      }
    } else {
      _fechaSeleccionada = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          llave == null ? 'Nuevo Recordatorio' : 'Editar Recordatorio',
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter establecerEstadoDialogo) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _controladorNombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Recordatorio',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controladorValor,
                    decoration: const InputDecoration(
                      labelText: 'Valor (opcional)',
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controladorNotas,
                    decoration: const InputDecoration(
                      labelText: 'Notas / Observaciones (opcional)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _tipoFrecuencia,
                    decoration: const InputDecoration(labelText: 'Frecuencia'),
                    items: ['Una vez', 'Mensual', 'Anual']
                        .map(
                          (tipo) =>
                              DropdownMenuItem(value: tipo, child: Text(tipo)),
                        )
                        .toList(),
                    onChanged: (val) {
                      establecerEstadoDialogo(() {
                        _tipoFrecuencia = val!;
                        _fechaSeleccionada = DateTime.now();
                        _diaSeleccionado = null;
                        _mesSeleccionado = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_tipoFrecuencia == 'Una vez')
                    ListTile(
                      title: const Text('Fecha'),
                      subtitle: Text(
                        DateFormat(
                          'EEEE, d MMM y',
                          'es',
                        ).format(_fechaSeleccionada),
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final fechaElegida = await showDatePicker(
                          context: context,
                          initialDate: _fechaSeleccionada,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365 * 5),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 5),
                          ),
                          locale: const Locale('es'),
                        );
                        if (fechaElegida != null) {
                          establecerEstadoDialogo(
                            () => _fechaSeleccionada = fechaElegida,
                          );
                        }
                      },
                    ),
                  if (_tipoFrecuencia == 'Mensual')
                    DropdownButtonFormField<int>(
                      initialValue: _diaSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Día del mes',
                      ),
                      items: List.generate(28, (i) => i + 1)
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text('Día $d'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => establecerEstadoDialogo(
                        () => _diaSeleccionado = val!,
                      ),
                      validator: (val) =>
                          val == null ? 'Selecciona un día' : null,
                    ),
                  if (_tipoFrecuencia == 'Anual') ...[
                    DropdownButtonFormField<int>(
                      initialValue: _mesSeleccionado,
                      decoration: const InputDecoration(labelText: 'Mes'),
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                DateFormat.MMMM('es').format(DateTime(2023, m)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => establecerEstadoDialogo(
                        () => _mesSeleccionado = val!,
                      ),
                      validator: (val) =>
                          val == null ? 'Selecciona un mes' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _diaSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Día del mes',
                      ),
                      items: List.generate(31, (i) => i + 1)
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text('Día $d'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => establecerEstadoDialogo(
                        () => _diaSeleccionado = val!,
                      ),
                      validator: (val) =>
                          val == null ? 'Selecciona un día' : null,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Guardar'),
            onPressed: () {
              final nombre = _controladorNombre.text.trim();
              final valor = double.tryParse(_controladorValor.text);
              final notas = _controladorNotas.text.trim();

              if (nombre.isNotEmpty) {
                final datos = {
                  'nombre': nombre,
                  'valor': valor,
                  'notas': notas,
                  'tipoFrecuencia': _tipoFrecuencia,
                };

                if (_tipoFrecuencia == 'Una vez') {
                  datos['fecha'] = _fechaSeleccionada.toIso8601String();
                } else if (_tipoFrecuencia == 'Mensual') {
                  if (_diaSeleccionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, selecciona un día para el recordatorio mensual.',
                        ),
                      ),
                    );
                    return;
                  }
                  datos['dia'] = _diaSeleccionado;
                } else if (_tipoFrecuencia == 'Anual') {
                  if (_diaSeleccionado == null || _mesSeleccionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, selecciona un día y un mes para el recordatorio anual.',
                        ),
                      ),
                    );
                    return;
                  }
                  datos['dia'] = _diaSeleccionado;
                  datos['mes'] = _mesSeleccionado;
                }

                if (llave == null) {
                  cajaRecordatorios.add(datos);
                } else {
                  cajaRecordatorios.put(llave, datos);
                }
                Navigator.pop(context);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  void _eliminarRecordatorio(dynamic llave) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar recordatorio?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: TemaApp._colorError),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      cajaRecordatorios.delete(llave);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios')),
      body: ValueListenableBuilder(
        valueListenable: cajaRecordatorios.listenable(),
        builder: (context, Box box, _) {
          final recordatoriosConFechaProxima = box
              .toMap()
              .entries
              .map((entrada) {
                final recordatorio = entrada.value;
                final proximaFecha = _calcularProximaFechaRecordatorio(
                  recordatorio,
                );
                return MapEntry(entrada.key, {
                  'data': recordatorio,
                  'proximaFecha': proximaFecha,
                });
              })
              .where((entrada) => entrada.value['proximaFecha'] != null)
              .toList();

          recordatoriosConFechaProxima.sort(
            (a, b) => (a.value['proximaFecha'] as DateTime).compareTo(
              b.value['proximaFecha'] as DateTime,
            ),
          );

          if (recordatoriosConFechaProxima.isEmpty) {
            return const Center(child: Text('No hay recordatorios guardados.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: recordatoriosConFechaProxima.length,
            itemBuilder: (context, indice) {
              final entrada = recordatoriosConFechaProxima[indice];
              final recordatorio = entrada.value['data'];
              final proximaFecha = entrada.value['proximaFecha'] as DateTime;
              final diasRestantes = proximaFecha
                  .difference(DateTime.now())
                  .inDays;
              final tieneValor =
                  recordatorio['valor'] != null && recordatorio['valor'] > 0;
              final tieneNotas =
                  recordatorio['notas'] != null &&
                  recordatorio['notas'].isNotEmpty;

              Color cardColor;
              Color iconColor;
              TextStyle textStyle = TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              );
              TextDecoration? textDecoration;

              if (diasRestantes < 0) {
                cardColor = Colors.grey.shade200;
                iconColor = Colors.grey.shade600;
                textDecoration = TextDecoration.lineThrough;
                textStyle = TextStyle(
                  color: Colors.grey.shade600,
                  decoration: textDecoration,
                );
              } else if (diasRestantes <= 7) {
                cardColor = Color.fromRGBO(
                  (TemaApp._colorAdvertencia.r * 255.0).round() & 0xff,
                  (TemaApp._colorAdvertencia.g * 255.0).round() & 0xff,
                  (TemaApp._colorAdvertencia.b * 255.0).round() & 0xff,
                  0.1,
                );
                iconColor = TemaApp._colorAdvertencia;
              } else if (diasRestantes <= 15) {
                cardColor = Colors.amber.shade100;
                iconColor = Colors.amber.shade700;
              } else if (diasRestantes <= 30) {
                cardColor = Colors.lightBlue.shade100;
                iconColor = Colors.lightBlue.shade700;
              } else {
                cardColor = Theme.of(context).cardColor;
                iconColor = Theme.of(context).colorScheme.primary;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                color: cardColor,
                child: ListTile(
                  leading: Icon(Icons.alarm_on_outlined, color: iconColor),
                  title: Text(
                    recordatorio['nombre'],
                    style: textStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('dd MMM y', 'es').format(proximaFecha)} ${tieneValor ? ' - ${formatoMoneda.format(recordatorio['valor'])}' : ''}',
                        style: textStyle,
                      ),
                      Text(
                        diasRestantes >= 0
                            ? 'Faltan $diasRestantes días'
                            : 'Vencido hace ${diasRestantes.abs()} días',
                        style: textStyle.copyWith(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (tieneNotas)
                        Text(
                          'Notas: ${recordatorio['notas']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _mostrarDialogoRecordatorio(
                          llave: entrada.key,
                          recordatorioExistente: recordatorio,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: TemaApp._colorError,
                        ),
                        onPressed: () => _eliminarRecordatorio(entrada.key),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoRecordatorio(),
        label: const Text('Nuevo Recordatorio'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

//==============================================================================
// 📊 BUDGET AND GOALS SCREEN
//==============================================================================
class PantallaPresupuesto extends StatefulWidget {
  const PantallaPresupuesto({super.key});

  @override
  EstadoPantallaPresupuesto createState() => EstadoPantallaPresupuesto();
}

// --- INICIO: SECCIÓN ACTUALIZADA (SECCIÓN 5) ---
// Se añade 'SingleTickerProviderStateMixin' para el TabController.
// Added 'SingleTickerProviderStateMixin' for the TabController.
class EstadoPantallaPresupuesto extends State<PantallaPresupuesto>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Box cajaAjustes = Hive.box('ajustes');
  final Box cajaMetas = Hive.box('metas');
  final Box cajaMetasHogar = Hive.box('metasHogar');

  // Controladores para presupuesto personal
  final controllerIngresoPersonal = TextEditingController();
  final controllerGastoPersonal = TextEditingController();
  final controllerAhorroPersonal = TextEditingController();
  final controllerInversionPersonal = TextEditingController();
  final controllerMetaPersonal = TextEditingController();
  final controllerPrecioPersonal = TextEditingController();
  final controllerMesesPersonal = TextEditingController();

  // Controladores para presupuesto del hogar
  final controllerIngresoPareja = TextEditingController();
  final controllerGastoHogar = TextEditingController();
  final controllerAhorroHogar = TextEditingController();
  final controllerInversionHogar = TextEditingController();
  final controllerMetaHogar = TextEditingController();
  final controllerPrecioHogar = TextEditingController();
  final controllerMesesHogar = TextEditingController();

  String categoriaSeleccionadaPersonal = 'Gasto';
  String categoriaSeleccionadaHogar = 'Gasto';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarAjustes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all controllers
    controllerIngresoPersonal.dispose();
    controllerGastoPersonal.dispose();
    controllerAhorroPersonal.dispose();
    controllerInversionPersonal.dispose();
    controllerMetaPersonal.dispose();
    controllerPrecioPersonal.dispose();
    controllerMesesPersonal.dispose();
    controllerIngresoPareja.dispose();
    controllerGastoHogar.dispose();
    controllerAhorroHogar.dispose();
    controllerInversionHogar.dispose();
    controllerMetaHogar.dispose();
    controllerPrecioHogar.dispose();
    controllerMesesHogar.dispose();
    super.dispose();
  }

  void _cargarAjustes() {
    // Cargar datos personales
    controllerIngresoPersonal.text = cajaAjustes
        .get('ingresoPersonal', defaultValue: 0.0)
        .toStringAsFixed(0);
    controllerGastoPersonal.text = cajaAjustes
        .get('gastoPersonal', defaultValue: 50.0)
        .toStringAsFixed(0);
    controllerAhorroPersonal.text = cajaAjustes
        .get('ahorroPersonal', defaultValue: 25.0)
        .toStringAsFixed(0);
    controllerInversionPersonal.text = cajaAjustes
        .get('inversionPersonal', defaultValue: 25.0)
        .toStringAsFixed(0);

    // Cargar datos del hogar
    controllerIngresoPareja.text = cajaAjustes
        .get('ingresoPareja', defaultValue: 0.0)
        .toStringAsFixed(0);
    controllerGastoHogar.text = cajaAjustes
        .get('gastoHogar', defaultValue: 70.0)
        .toStringAsFixed(0);
    controllerAhorroHogar.text = cajaAjustes
        .get('ahorroHogar', defaultValue: 20.0)
        .toStringAsFixed(0);
    controllerInversionHogar.text = cajaAjustes
        .get('inversionHogar', defaultValue: 10.0)
        .toStringAsFixed(0);
    setState(() {});
  }

  void _guardarAjustes() {
    // Guardar datos personales
    cajaAjustes.put(
      'ingresoPersonal',
      double.tryParse(controllerIngresoPersonal.text) ?? 0.0,
    );
    cajaAjustes.put(
      'gastoPersonal',
      double.tryParse(controllerGastoPersonal.text) ?? 0.0,
    );
    cajaAjustes.put(
      'ahorroPersonal',
      double.tryParse(controllerAhorroPersonal.text) ?? 0.0,
    );
    cajaAjustes.put(
      'inversionPersonal',
      double.tryParse(controllerInversionPersonal.text) ?? 0.0,
    );

    // Guardar datos del hogar
    cajaAjustes.put(
      'ingresoPareja',
      double.tryParse(controllerIngresoPareja.text) ?? 0.0,
    );
    cajaAjustes.put(
      'gastoHogar',
      double.tryParse(controllerGastoHogar.text) ?? 0.0,
    );
    cajaAjustes.put(
      'ahorroHogar',
      double.tryParse(controllerAhorroHogar.text) ?? 0.0,
    );
    cajaAjustes.put(
      'inversionHogar',
      double.tryParse(controllerInversionHogar.text) ?? 0.0,
    );
    setState(() {});
  }

  // Lógica para metas personales
  Future<void> _agregarMetaPersonal() async {
    final nombre = controllerMetaPersonal.text.trim();
    final precio = double.tryParse(controllerPrecioPersonal.text) ?? 0;
    final meses = int.tryParse(controllerMesesPersonal.text) ?? 1;

    if (nombre.isNotEmpty && precio > 0 && meses > 0) {
      await cajaMetas.add({
        'nombre': nombre,
        'precio': precio,
        'meses': meses,
        'categoria': categoriaSeleccionadaPersonal,
      });
      controllerMetaPersonal.clear();
      controllerPrecioPersonal.clear();
      controllerMesesPersonal.clear();
      setState(() {});
    }
  }

  // Lógica para metas del hogar
  Future<void> _agregarMetaHogar() async {
    final nombre = controllerMetaHogar.text.trim();
    final precio = double.tryParse(controllerPrecioHogar.text) ?? 0;
    final meses = int.tryParse(controllerMesesHogar.text) ?? 1;

    if (nombre.isNotEmpty && precio > 0 && meses > 0) {
      await cajaMetasHogar.add({
        'nombre': nombre,
        'precio': precio,
        'meses': meses,
        'categoria': categoriaSeleccionadaHogar,
      });
      controllerMetaHogar.clear();
      controllerPrecioHogar.clear();
      controllerMesesHogar.clear();
      setState(() {});
    }
  }

  // Se reutiliza para editar metas personales y del hogar.
  // Reused for editing personal and home goals.
  void _editarMeta(int llave, Map meta, bool esMetaHogar) {
    final box = esMetaHogar ? cajaMetasHogar : cajaMetas;
    final controllerNombre = TextEditingController(text: meta['nombre']);
    final controllerPrecio = TextEditingController(
      text: meta['precio'].toStringAsFixed(0),
    );
    final controllerMeses = TextEditingController(
      text: meta['meses'].toString(),
    );
    String nuevaCategoria = meta['categoria'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Meta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controllerNombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controllerPrecio,
                  decoration: const InputDecoration(labelText: 'Valor total'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controllerMeses,
                  decoration: const InputDecoration(labelText: 'Meses'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: nuevaCategoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: ['Gasto', 'Ahorro', 'Inversion']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => nuevaCategoria = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                box.delete(llave);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: TemaApp._colorError),
              ),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () {
                box.put(llave, {
                  'nombre': controllerNombre.text.trim(),
                  'precio':
                      double.tryParse(controllerPrecio.text) ?? meta['precio'],
                  'meses': int.tryParse(controllerMeses.text) ?? meta['meses'],
                  'categoria': nuevaCategoria,
                });
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto y Metas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: "Personal"),
            Tab(icon: Icon(Icons.home_work_outlined), text: "Hogar"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPersonalBudgetView(), _buildHomeBudgetView()],
      ),
    );
  }

  // --- Vista para Presupuesto del Hogar ---
  Widget _buildHomeBudgetView() {
    double ingresoPersonal =
        double.tryParse(controllerIngresoPersonal.text) ?? 0.0;
    double ingresoPareja = double.tryParse(controllerIngresoPareja.text) ?? 0.0;
    double ingresoTotalHogar = ingresoPersonal + ingresoPareja;

    return ValueListenableBuilder(
      valueListenable: cajaMetasHogar.listenable(),
      builder: (context, Box box, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHomeConfigCard(ingresoTotalHogar),
            const SizedBox(height: 24),
            _buildBudgetCard(
              "Presupuesto Disponible del Hogar",
              ingresoTotalHogar,
              double.tryParse(controllerGastoHogar.text) ?? 0.0,
              double.tryParse(controllerAhorroHogar.text) ?? 0.0,
              double.tryParse(controllerInversionHogar.text) ?? 0.0,
              cajaMetasHogar,
            ),
            const SizedBox(height: 24),
            _buildAddGoalCard(true),
            const SizedBox(height: 24),
            _buildGoalsList(true),
          ],
        );
      },
    );
  }

  // --- Vista para Presupuesto Personal ---
  Widget _buildPersonalBudgetView() {
    double ingresoPersonal =
        double.tryParse(controllerIngresoPersonal.text) ?? 0.0;
    double ingresoPareja = double.tryParse(controllerIngresoPareja.text) ?? 0.0;
    double ingresoTotalHogar = ingresoPersonal + ingresoPareja;

    double miPorcentajeAporte = ingresoTotalHogar > 0
        ? (ingresoPersonal / ingresoTotalHogar)
        : 0;

    double totalMetasHogar = cajaMetasHogar.values.fold(
      0.0,
      (sum, meta) => sum + (meta['precio'] / meta['meses']),
    );
    double miAporteHogar = totalMetasHogar * miPorcentajeAporte;
    double ingresoPersonalRestante = ingresoPersonal - miAporteHogar;

    return ValueListenableBuilder(
      valueListenable: cajaMetas.listenable(),
      builder: (context, Box box, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPersonalSummaryCard(
              ingresoPersonal,
              miAporteHogar,
              ingresoPersonalRestante,
            ),
            const SizedBox(height: 24),
            _buildPersonalConfigCard(),
            const SizedBox(height: 24),
            _buildBudgetCard(
              "Presupuesto Personal Disponible",
              ingresoPersonalRestante,
              double.tryParse(controllerGastoPersonal.text) ?? 0.0,
              double.tryParse(controllerAhorroPersonal.text) ?? 0.0,
              double.tryParse(controllerInversionPersonal.text) ?? 0.0,
              cajaMetas,
            ),
            const SizedBox(height: 24),
            _buildAddGoalCard(false),
            const SizedBox(height: 24),
            _buildGoalsList(false),
          ],
        );
      },
    );
  }

  // --- Widgets Reutilizables y Específicos ---

  Card _buildPersonalSummaryCard(
    double ingreso,
    double aporte,
    double restante,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Resumen de Aportes al Hogar",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 20),
            _buildSummaryRow("Tu ingreso pronosticado:", ingreso),
            _buildSummaryRow(
              "Tu aporte a metas del hogar:",
              -aporte,
              color: TemaApp._colorError,
            ),
            const Divider(height: 20, thickness: 1),
            _buildSummaryRow(
              "Ingreso personal restante:",
              restante,
              isBold: true,
            ),
            const SizedBox(height: 8),
            const Text(
              "Este es el monto que tienes disponible para tu presupuesto y metas personales.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value, {
    Color? color,
    bool isBold = false,
    double? fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            formatoMoneda.format(value),
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Card _buildHomeConfigCard(double ingresoTotalHogar) {
    double totalAsignado =
        (double.tryParse(controllerGastoHogar.text) ?? 0) +
        (double.tryParse(controllerAhorroHogar.text) ?? 0) +
        (double.tryParse(controllerInversionHogar.text) ?? 0);
    Color colorResumen = totalAsignado == 100
        ? Colors.green
        : (totalAsignado < 100
              ? TemaApp._colorAdvertencia
              : TemaApp._colorError);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Configuración Mensual del Hogar",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controllerIngresoPersonal,
              decoration: const InputDecoration(labelText: "Tu Ingreso"),
              keyboardType: TextInputType.number,
              onEditingComplete: _guardarAjustes,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controllerIngresoPareja,
              decoration: const InputDecoration(
                labelText: "Ingreso de tu Pareja",
              ),
              keyboardType: TextInputType.number,
              onEditingComplete: _guardarAjustes,
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                "Total Ingresos Hogar: ${formatoMoneda.format(ingresoTotalHogar)}",
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllerGastoHogar,
                    decoration: const InputDecoration(labelText: "Gasto %"),
                    keyboardType: TextInputType.number,
                    onEditingComplete: _guardarAjustes,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controllerAhorroHogar,
                    decoration: const InputDecoration(labelText: "Ahorro %"),
                    keyboardType: TextInputType.number,
                    onEditingComplete: _guardarAjustes,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controllerInversionHogar,
                    decoration: const InputDecoration(labelText: "Inversión %"),
                    keyboardType: TextInputType.number,
                    onEditingComplete: _guardarAjustes,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Chip(
              label: Text(
                '${totalAsignado.toStringAsFixed(0)}% Asignado',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: colorResumen.withAlpha(51),
              side: BorderSide(color: colorResumen),
            ),
          ],
        ),
      ),
    );
  }

  Card _buildPersonalConfigCard() {
    double totalAsignado =
        (double.tryParse(controllerGastoPersonal.text) ?? 0) +
        (double.tryParse(controllerAhorroPersonal.text) ?? 0) +
        (double.tryParse(controllerInversionPersonal.text) ?? 0);
    Color colorResumen = totalAsignado == 100
        ? Colors.green
        : (totalAsignado < 100
              ? TemaApp._colorAdvertencia
              : TemaApp._colorError);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Configuración Mensual Personal",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controllerIngresoPersonal,
              decoration: const InputDecoration(
                labelText: "Ingreso Mensual Pronosticado",
              ),
              keyboardType: TextInputType.number,
              onEditingComplete: _guardarAjustes,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllerGastoPersonal,
                    decoration: const InputDecoration(labelText: "Gasto %"),
                    keyboardType: TextInputType.number,
                    onEditingComplete: _guardarAjustes,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controllerAhorroPersonal,
                    decoration: const InputDecoration(labelText: "Ahorro %"),
                    keyboardType: TextInputType.number,
                    onEditingComplete: _guardarAjustes,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controllerInversionPersonal,
                    decoration: const InputDecoration(labelText: "Inversión %"),
                    keyboardType: TextInputType.number,
                    onEditingComplete: _guardarAjustes,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Chip(
              label: Text(
                '${totalAsignado.toStringAsFixed(0)}% Asignado',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: colorResumen.withAlpha(51),
              side: BorderSide(color: colorResumen),
            ),
          ],
        ),
      ),
    );
  }

  Card _buildBudgetCard(
    String title,
    double totalIncome,
    double pGasto,
    double pAhorro,
    double pInversion,
    Box metasBox,
  ) {
    double montoGasto = totalIncome * pGasto / 100;
    double montoAhorro = totalIncome * pAhorro / 100;
    double montoInversion = totalIncome * pInversion / 100;
    double totalMensual(String tipo) => metasBox.values
        .where((m) => m['categoria'] == tipo)
        .fold(0.0, (s, m) => s + (m['precio'] / m['meses']));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _filaPresupuesto("Gastos", montoGasto, totalMensual("Gasto")),
            _filaPresupuesto("Ahorros", montoAhorro, totalMensual("Ahorro")),
            _filaPresupuesto(
              "Inversiones",
              montoInversion,
              totalMensual("Inversion"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaPresupuesto(
    String titulo,
    double presupuestoTotal,
    double comprometido,
  ) {
    double disponible = presupuestoTotal - comprometido;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                formatoMoneda.format(disponible),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${formatoMoneda.format(presupuestoTotal)} | Comprometido: ${formatoMoneda.format(comprometido)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: presupuestoTotal > 0 ? comprometido / presupuestoTotal : 0,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  double _calcularGastoMensualMeta(int idMeta, bool esHogar) {
    final cajaMovimientos = Hive.box('movimientos');
    final ahora = DateTime.now();
    double total = 0;

    for (var mov in cajaMovimientos.values) {
      if (mov['type'] == 'Gasto' &&
          mov['idMetaPresupuesto'] == idMeta &&
          mov['esMetaHogar'] == esHogar) {
        final fechaMov = DateTime.parse(mov['date']);
        if (fechaMov.year == ahora.year && fechaMov.month == ahora.month) {
          total += mov['amount'];
        }
      }
    }
    return total;
  }

  Card _buildAddGoalCard(bool esHogar) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              esHogar
                  ? 'Agregar Meta o Gasto Fijo del Hogar'
                  : 'Agregar Meta o Gasto Fijo Personal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: esHogar
                  ? controllerMetaHogar
                  : controllerMetaPersonal,
              decoration: const InputDecoration(labelText: 'Nombre de la meta'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: esHogar
                        ? controllerPrecioHogar
                        : controllerPrecioPersonal,
                    decoration: const InputDecoration(
                      labelText: 'Valor total',
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: esHogar
                        ? controllerMesesHogar
                        : controllerMesesPersonal,
                    decoration: const InputDecoration(labelText: 'Meses'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: esHogar
                  ? categoriaSeleccionadaHogar
                  : categoriaSeleccionadaPersonal,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                'Gasto',
                'Ahorro',
                'Inversion',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(
                () => esHogar
                    ? categoriaSeleccionadaHogar = val!
                    : categoriaSeleccionadaPersonal = val!,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Agregar Meta'),
              onPressed: esHogar ? _agregarMetaHogar : _agregarMetaPersonal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList(bool esHogar) {
    final box = esHogar ? cajaMetasHogar : cajaMetas;
    final metas = box.toMap();

    if (metas.isEmpty) return const SizedBox.shrink();

    // Obtener ingresos para calcular porcentajes de aporte
    double ingresoPersonal =
        double.tryParse(controllerIngresoPersonal.text) ?? 0.0;
    double ingresoPareja = double.tryParse(controllerIngresoPareja.text) ?? 0.0;
    double ingresoTotalHogar = ingresoPersonal + ingresoPareja;
    double porcentajeAportePersonal = ingresoTotalHogar > 0
        ? (ingresoPersonal / ingresoTotalHogar) * 100
        : 0;
    //double porcentajeAportePareja = 100 - porcentajeAportePersonal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          esHogar ? 'Metas del Hogar' : 'Metas Personales',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: metas.entries.map((entry) {
            final llave = entry.key;
            final meta = entry.value;
            final mensual = meta['precio'] / meta['meses'];

            // Calcular aporte personal si es meta del hogar
            String infoAporte = '';
            if (esHogar && ingresoTotalHogar > 0) {
              double aportePersonal =
                  (mensual * porcentajeAportePersonal) / 100;
              infoAporte =
                  '\nTu aporte: ${formatoMoneda.format(aportePersonal)} (${porcentajeAportePersonal.toStringAsFixed(1)}%)';
            }

            String formatoAniosMeses(int meses) {
              final anios = meses ~/ 12;
              final resto = meses % 12;
              if (anios > 0 && resto > 0) return '$anios a, $resto m';
              if (anios > 0) return '$anios año(s)';
              return '$resto mes(es)';
            }

            // Nuevo: Calcular progreso
            final gastado = _calcularGastoMensualMeta(llave, esHogar);
            final progreso = mensual > 0 ? gastado / mensual : 0.0;
            final colorProgreso = progreso >= 1.0
                ? Colors.red
                : (progreso >= 0.8 ? Colors.orange : Colors.green);

            return Card(
              key: ValueKey(llave),
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Text('${meta['nombre']} (${meta['categoria']})'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${formatoMoneda.format(meta['precio'])} en ${formatoAniosMeses(meta['meses'])}',
                    ),
                    if (esHogar && ingresoTotalHogar > 0)
                      Text(
                        'Mensual: ${formatoMoneda.format(mensual)}$infoAporte',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progreso > 1 ? 1 : progreso,
                      backgroundColor: Colors.grey[300],
                      color: colorProgreso,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gastado: ${formatoMoneda.format(gastado)} / ${formatoMoneda.format(mensual)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorProgreso,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  '${formatoMoneda.format(mensual)}/mes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () => _editarMeta(llave, meta, esHogar),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
// --- FIN: SECCIÓN ACTUALIZADA (SECCIÓN 5) ---

//==============================================================================
// 🛂 UVT / DIAN CONTROL SCREENS
//==============================================================================
class PantallaControlUVT extends StatefulWidget {
  const PantallaControlUVT({super.key});

  @override
  EstadoPantallaControlUVT createState() => EstadoPantallaControlUVT();
}

class EstadoPantallaControlUVT extends State<PantallaControlUVT> {
  final cajaAjustes = Hive.box('ajustes');
  final cajaBancos = Hive.box('bancos');
  late Set<int> cuentasSeleccionadas;

  @override
  void initState() {
    super.initState();
    final seleccionadas = cajaAjustes.get('cuentasUVT', defaultValue: <int>[]);
    cuentasSeleccionadas = Set<int>.from(seleccionadas);
  }

  void guardarSeleccion() {
    cajaAjustes.put('cuentasUVT', cuentasSeleccionadas.toList());
  }

  @override
  Widget build(BuildContext context) {
    // --- INICIO: CAMBIO APLICADO (SECCIÓN 3) ---
    final orderedAccounts = getOrderedAccounts();
    // --- FIN: CAMBIO APLICADO (SECCIÓN 3) ---
    return Scaffold(
      appBar: AppBar(title: const Text('Control UVT / DIAN')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Selecciona las cuentas a incluir en el cálculo de topes. Las cuentas con "bolsillo" en el nombre se excluyen por defecto.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: ListView(
              // --- INICIO: CAMBIO APLICADO (SECCIÓN 3) ---
              children: orderedAccounts.map((entrada) {
                final id = entrada.key;
                final nombre = entrada.value['name'];
                // --- FIN: CAMBIO APLICADO (SECCIÓN 3) ---
                final esBolsillo = nombre.toLowerCase().contains('bolsillo');
                return CheckboxListTile(
                  title: Text(nombre),
                  subtitle: esBolsillo
                      ? const Text('(Excluida automáticamente)')
                      : null,
                  value: esBolsillo ? false : cuentasSeleccionadas.contains(id),
                  onChanged: esBolsillo
                      ? null
                      : (val) {
                          setState(() {
                            if (val == true) {
                              cuentasSeleccionadas.add(id);
                            } else {
                              cuentasSeleccionadas.remove(id);
                            }
                            guardarSeleccion();
                          });
                        },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_ios_rounded),
              label: const Text('Ver Resumen de Topes'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaResumenUVT()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PantallaResumenUVT extends StatefulWidget {
  const PantallaResumenUVT({super.key});
  @override
  EstadoPantallaResumenUVT createState() => EstadoPantallaResumenUVT();
}

class EstadoPantallaResumenUVT extends State<PantallaResumenUVT> {
  Color conAlpha(Color color, double opacidad) {
    return color.withAlpha((opacidad * 255).round());
  }

  final cajaAjustes = Hive.box('ajustes');
  final cajaBancos = Hive.box('bancos');
  final cajaMovimientos = Hive.box('movimientos');

  final Map<String, int> topesUVT = {
    'ingresos': 1400,
    'patrimonio': 4500,
    'movimientos': 1400,
    'consumos': 1400,
    'compras': 1400,
  };
  final controladorValorUVT = TextEditingController();
  Map<String, TextEditingController> controladoresIniciales = {};
  late int anioSeleccionado;
  late NumberFormat formatoPesos;

  @override
  void initState() {
    super.initState();
    anioSeleccionado = DateTime.now().year;
    formatoPesos = NumberFormat.decimalPattern('es_CO');
    controladorValorUVT.text = cajaAjustes
        .get('uvtValor', defaultValue: 47065)
        .toString();
    final valoresIniciales = Map<String, double>.from(
      cajaAjustes.get('uvtValoresIniciales', defaultValue: {}),
    );
    for (var clave in topesUVT.keys) {
      controladoresIniciales[clave] = TextEditingController(
        text: (valoresIniciales[clave] ?? 0).toStringAsFixed(0),
      );
    }
  }

  double get valorUVT => double.tryParse(controladorValorUVT.text) ?? 47065;

  void guardarValores() {
    final mapa = {
      for (var c in controladoresIniciales.keys)
        c: double.tryParse(controladoresIniciales[c]!.text) ?? 0,
    };
    cajaAjustes.put('uvtValoresIniciales', mapa);
    cajaAjustes.put('uvtValor', valorUVT);
    setState(() {});
  }

  double calcularMonto(String categoria) {
    final seleccionadas = Set<int>.from(
      cajaAjustes.get('cuentasUVT', defaultValue: []),
    );
    double total = 0;
    int? buscar(String? n) => n == null
        ? null
        : cajaBancos.keys.cast<int>().firstWhere(
            (k) => cajaBancos.get(k)['name'] == n,
            orElse: () => -1,
          );

    if (categoria == 'patrimonio') {
      total = seleccionadas.fold(
        0.0,
        (sum, key) => sum + (cajaBancos.get(key)?['balance'] ?? 0),
      );
      total += List<Map>.from(
        cajaAjustes.get('bienesUVT', defaultValue: []),
      ).fold(0.0, (s, b) => s + b['valor']);
    } else {
      for (var mov in cajaMovimientos.values) {
        if (DateTime.parse(mov['date']).year == anioSeleccionado) {
          final tipo = mov['type'];
          if (categoria == 'ingresos' &&
              tipo == 'Ingreso' &&
              seleccionadas.contains(buscar(mov['account']))) {
            total += mov['amount'];
          } else if ((categoria == 'compras' || categoria == 'consumos') &&
              tipo == 'Gasto' &&
              seleccionadas.contains(buscar(mov['account']))) {
            total += mov['amount'];
          } else if (categoria == 'movimientos') {
            if ((tipo == 'Ingreso' || tipo == 'Gasto') &&
                seleccionadas.contains(buscar(mov['account']))) {
              total += mov['amount'];
            } else if (tipo == 'Transferencia' &&
                (seleccionadas.contains(buscar(mov['from'])) ||
                    seleccionadas.contains(buscar(mov['to'])))) {
              total += mov['amount'] * 2;
            }
          }
        }
      }
    }
    return total +
        (double.tryParse(controladoresIniciales[categoria]?.text ?? '0') ?? 0);
  }

  Map<String, dynamic> calcularProyeccionAnual(
    String categoria,
    double montoActual,
    double topeUVT,
  ) {
    final ahora = DateTime.now();
    final inicioAnio = DateTime(anioSeleccionado, 1, 1);
    final finAnio = DateTime(anioSeleccionado, 12, 31);

    final diasTranscurridos = ahora.difference(inicioAnio).inDays + 1;
    final diasTotales = finAnio.difference(inicioAnio).inDays + 1;

    final factorProyeccion = diasTotales / diasTranscurridos;
    final proyeccionAnual = montoActual * factorProyeccion;

    final porcentajeTranscurrido = (diasTranscurridos / diasTotales) * 100;

    final tendencia = proyeccionAnual / (topeUVT * valorUVT);
    String mensajeTendencia;
    Color colorTendencia;

    if (tendencia < 0.8) {
      mensajeTendencia = 'Bajo control';
      colorTendencia = Colors.green.shade600;
    } else if (tendencia < 1.0) {
      mensajeTendencia = 'Cerca del límite';
      colorTendencia = Colors.orange;
    } else {
      mensajeTendencia = 'Sobre el límite';
      colorTendencia = Colors.red.shade700;
    }

    return {
      'proyeccionAnual': proyeccionAnual,
      'porcentajeTranscurrido': porcentajeTranscurrido,
      'diasTranscurridos': diasTranscurridos,
      'diasTotales': diasTotales,
      'tendencia': tendencia,
      'mensajeTendencia': mensajeTendencia,
      'colorTendencia': colorTendencia,
      'sobrepasa': proyeccionAnual > (topeUVT * valorUVT),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen Topes UVT')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _construirTarjetaConfiguracionUVT(),
          const SizedBox(height: 16),
          ...topesUVT.entries.map(
            (e) => _construirTarjetaCategoria(e.key, e.value),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaConfiguracionUVT() {
    final fechaDeclaracion = cajaAjustes.get('fechaDeclaracionUVT');
    final fechaFormateada = fechaDeclaracion != null
        ? DateFormat('d MMMM y', 'es').format(DateTime.parse(fechaDeclaracion))
        : 'No definida';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: anioSeleccionado,
                    decoration: const InputDecoration(labelText: 'Año Fiscal'),
                    onChanged: (nuevo) =>
                        setState(() => anioSeleccionado = nuevo!),
                    items: List.generate(5, (i) {
                      final anio = DateTime.now().year - 2 + i;
                      return DropdownMenuItem(
                        value: anio,
                        child: Text(anio.toString()),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: controladorValorUVT,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Valor UVT'),
                    onChanged: (_) => guardarValores(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha límite de declaración'),
              subtitle: Text(
                fechaFormateada,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: () async {
                final seleccionada = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(DateTime.now().year - 1),
                  lastDate: DateTime(DateTime.now().year + 2),
                  locale: const Locale('es'),
                );
                if (seleccionada != null) {
                  cajaAjustes.put(
                    'fechaDeclaracionUVT',
                    seleccionada.toIso8601String(),
                  );
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaCategoria(String categoria, int topeUVT) {
    final topePesos = topeUVT * valorUVT;
    final monto = calcularMonto(categoria);
    final porcentaje = monto / topePesos;
    final color = porcentaje >= 1
        ? TemaApp._colorError
        : (porcentaje >= 0.8
              ? TemaApp._colorAdvertencia
              : Colors.green.shade600);

    final proyeccion = calcularProyeccionAnual(
      categoria,
      monto,
      topeUVT.toDouble(),
    );
    final proyeccionAnual = proyeccion['proyeccionAnual'] as double;
    final porcentajeProyeccion = proyeccionAnual / topePesos;
    final colorProyeccion = proyeccion['colorTendencia'] as Color;
    final mensajeTendencia = proyeccion['mensajeTendencia'] as String;
    final porcentajeTranscurrido =
        proyeccion['porcentajeTranscurrido'] as double;
    final diasTranscurridos = proyeccion['diasTranscurridos'] as int;
    final diasTotales = proyeccion['diasTotales'] as int;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    categoria.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: conAlpha(color, 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: conAlpha(color, 0.3)),
                  ),
                  child: Text(
                    '${(porcentaje * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Límite: $topeUVT UVT (${formatoMoneda.format(topePesos)})'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: porcentaje.clamp(0.0, 1.0),
              color: color,
              backgroundColor: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actual:',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    Text(
                      formatoMoneda.format(monto),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Días: $diasTranscurridos/$diasTotales',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    Text(
                      '${porcentajeTranscurrido.toStringAsFixed(1)}% del año',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: conAlpha(colorProyeccion, 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: conAlpha(colorProyeccion, 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: colorProyeccion, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'PROYECCIÓN ANUAL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorProyeccion,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          formatoMoneda.format(proyeccionAnual),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorProyeccion,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: conAlpha(colorProyeccion, 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          mensajeTendencia,
                          style: TextStyle(
                            color: colorProyeccion,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: porcentajeProyeccion.clamp(0.0, 1.5),
                    color: colorProyeccion,
                    backgroundColor: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(porcentajeProyeccion * 100).toStringAsFixed(1)}% del límite proyectado',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controladoresIniciales[categoria],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Sumar valor inicial manual',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => guardarValores(),
            ),
            if (categoria == 'patrimonio')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('Gestionar bienes'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: conAlpha(Theme.of(context).primaryColor, 0.3),
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PantallaBienesUVT(),
                      ),
                    ).then((_) => setState(() {})),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PantallaBienesUVT extends StatefulWidget {
  const PantallaBienesUVT({super.key});

  @override
  EstadoPantallaBienesUVT createState() => EstadoPantallaBienesUVT();
}

class EstadoPantallaBienesUVT extends State<PantallaBienesUVT> {
  final cajaAjustes = Hive.box('ajustes');

  List<Map<String, dynamic>> _obtenerBienes() {
    return List<Map>.from(
      cajaAjustes.get('bienesUVT', defaultValue: []),
    ).map((b) => Map<String, dynamic>.from(b)).toList();
  }

  void _guardarBienes(List<Map<String, dynamic>> lista) {
    cajaAjustes.put('bienesUVT', lista);
    setState(() {});
  }

  void _mostrarDialogo({int? indice}) {
    final bienes = _obtenerBienes();
    final esNuevo = indice == null;
    final controladorNombre = TextEditingController(
      text: esNuevo ? '' : bienes[indice]['nombre'],
    );
    final controladorValor = TextEditingController(
      text: esNuevo ? '' : bienes[indice]['valor'].toString(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(esNuevo ? 'Nuevo Bien Patrimonial' : 'Editar Bien'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controladorNombre,
              decoration: const InputDecoration(
                labelText: 'Nombre del bien (Carro, Lote, etc)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controladorValor,
              decoration: const InputDecoration(
                labelText: 'Valor estimado',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          if (!esNuevo)
            TextButton(
              onPressed: () {
                bienes.removeAt(indice);
                _guardarBienes(bienes);
                Navigator.pop(context);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: TemaApp._colorError),
              ),
            ),
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Guardar'),
            onPressed: () {
              final nombre = controladorNombre.text.trim();
              final valor = double.tryParse(controladorValor.text) ?? 0;
              if (nombre.isNotEmpty && valor > 0) {
                if (esNuevo) {
                  bienes.add({'nombre': nombre, 'valor': valor});
                } else {
                  bienes[indice] = {'nombre': nombre, 'valor': valor};
                }
                _guardarBienes(bienes);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bienes = _obtenerBienes();
    return Scaffold(
      appBar: AppBar(title: const Text('Bienes Patrimoniales')),
      body: bienes.isEmpty
          ? const Center(child: Text('No has registrado bienes.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: bienes.length,
              itemBuilder: (_, i) {
                final bien = bienes[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.inventory_2_outlined),
                    ),
                    title: Text(bien['nombre']),
                    subtitle: Text(formatoMoneda.format(bien['valor'])),
                    onTap: () => _mostrarDialogo(indice: i),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogo(),
        label: const Text('Agregar Bien'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

//==============================================================================
// 💾 BACKUP SCREEN
//==============================================================================

class PantallaCopiaSeguridad extends StatefulWidget {
  const PantallaCopiaSeguridad({super.key});

  @override
  State<PantallaCopiaSeguridad> createState() =>
      _EstadoPantallaCopiaSeguridad();
}

class _EstadoPantallaCopiaSeguridad extends State<PantallaCopiaSeguridad> {
  bool _estaCargando = false;
  final List<String> _nombresCajas = [
    'debitos', 'bancos', 'movimientos', 'notas', 'ajustes', 'metas',
    'metasHogar', // Añadida caja de metas del hogar al respaldo
    'cuentasUVT', 'uvtValoresIniciales', 'bienesUVT', 'fechaDeclaracionUVT',
    'categorias', 'uvt', 'recordatorios',
    'finanzasHogar', // Añadida caja de finanzas del hogar al respaldo
    'historialHogarEditable',
  ];

  Future<bool> _manejarPermisoAlmacenamiento() async {
    if (kIsWeb) {
      // En web no se necesitan permisos para descargar archivos
      return true;
    }

    if (await Permission.manageExternalStorage.isGranted) return true;
    final resultado = await Permission.manageExternalStorage.request();
    if (resultado.isGranted) return true;

    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permiso Requerido'),
          content: const Text(
            'La app necesita permiso de almacenamiento para leer o guardar respaldos. Ve a los ajustes para concederlo.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Abrir Ajustes'),
            ),
          ],
        ),
      );
    }
    return false;
  }

  Future<void> _exportarDatos() async {
    if (!kIsWeb && !await _manejarPermisoAlmacenamiento()) {
      _mostrarSnackbar(
        'No se concedió el permiso de almacenamiento.',
        esError: true,
      );
      return;
    }
    setState(() => _estaCargando = true);

    try {
      final Map<String, dynamic> todosLosDatos = {};
      for (final nombreCaja in _nombresCajas) {
        if (!Hive.isBoxOpen(nombreCaja)) await Hive.openBox(nombreCaja);
        final caja = Hive.box(nombreCaja);
        todosLosDatos[nombreCaja] = caja.toMap().map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      final cadenaJson = jsonEncode(todosLosDatos);

      final fechaFormateada = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final nombreArchivo = 'finanzas_respaldo_$fechaFormateada.json';

      if (kIsWeb) {
        // Descargar directamente en web
        await SupabaseExportService.exportBackupComplete(
          todosLosDatos.map((key, value) => MapEntry(key.toString(), value)),
        );
        _mostrarSnackbarConUbicacion(
          '✅ Exportación completada: $nombreArchivo',
          nombreArchivo,
        );
      } else {
        // Código existente para móvil
        dynamic directorioDescargas;
        if (io.Platform.isAndroid) {
          directorioDescargas = io.Directory('/storage/emulated/0/Download');
          if (!await directorioDescargas.exists()) {
            directorioDescargas = await getExternalStorageDirectory();
          }
        } else {
          directorioDescargas = await getApplicationDocumentsDirectory();
        }

        if (directorioDescargas == null) {
          throw Exception("No se pudo obtener el directorio");
        }

        final rutaArchivo = '${directorioDescargas.path}/$nombreArchivo';
        final archivo = io.File(rutaArchivo);
        await archivo.writeAsString(cadenaJson);
        _mostrarSnackbar(
          '¡Exportación exitosa! Archivo guardado en: $rutaArchivo',
          esError: false,
        );
      }
    } catch (e) {
      _mostrarSnackbar('Ocurrió un error durante la exportación: $e');
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  Future<void> _importarDatos() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ ¡Atención!'),
        content: const Text(
          'Vas a reemplazar TODOS los datos actuales con los del respaldo. Esta acción no se puede deshacer. ¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaApp._colorError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, importar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    if (!kIsWeb && !await _manejarPermisoAlmacenamiento()) {
      _mostrarSnackbar(
        'No se concedió el permiso para leer archivos.',
        esError: true,
      );
      return;
    }

    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (resultado == null) {
      _mostrarSnackbar('No se seleccionó ningún archivo.', esError: true);
      return;
    }

    setState(() => _estaCargando = true);

    try {
      String cadenaJson;

      if (kIsWeb) {
        // En web, leer los bytes directamente
        final bytes = resultado.files.single.bytes;
        if (bytes == null) {
          throw Exception('No se pudieron leer los bytes del archivo');
        }
        cadenaJson = utf8.decode(bytes);
      } else {
        // En móvil, leer desde la ruta
        final path = resultado.files.single.path;
        if (path == null) {
          throw Exception('No se pudo obtener la ruta del archivo');
        }
        final archivo = io.File(path);
        cadenaJson = await archivo.readAsString();
      }

      final Map<String, dynamic> todosLosDatos = jsonDecode(cadenaJson);

      for (final nombreCaja in _nombresCajas) {
        if (todosLosDatos.containsKey(nombreCaja)) {
          if (!Hive.isBoxOpen(nombreCaja)) await Hive.openBox(nombreCaja);
          final caja = Hive.box(nombreCaja);
          await caja.clear();
          final datosDesdeRespaldo =
              todosLosDatos[nombreCaja] as Map<String, dynamic>;
          final mapaFinal = datosDesdeRespaldo.map(
            (key, value) => MapEntry(int.tryParse(key) ?? key, value),
          );
          await caja.putAll(mapaFinal);
        }
      }
      _mostrarSnackbar('¡Importación completada con éxito!', esError: false);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _mostrarSnackbar(
        'Error al importar: El archivo podría estar dañado o no ser compatible. ($e)',
      );
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  void _mostrarSnackbar(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? TemaApp._colorError : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _mostrarSnackbarConUbicacion(String mensaje, String nombreArchivo) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: '¿Dónde?',
          onPressed: () {
            _mostrarDialogoUbicacionArchivoCopiaSeguridad(nombreArchivo);
          },
        ),
      ),
    );
  }

  void _mostrarDialogoUbicacionArchivoCopiaSeguridad(String nombreArchivo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📁 ¿Dónde está mi archivo?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archivo: $nombreArchivo'),
            const SizedBox(height: 16),
            const Text(
              'Ubicación:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Carpeta de descargas de tu navegador'),
            const SizedBox(height: 12),
            const Text(
              'Para encontrarlo rápidamente:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Chrome: Ctrl+J'),
            const Text('• Firefox: Ctrl+J'),
            const Text('• Safari: Cmd+Option+L'),
            const Text('• Edge: Ctrl+J'),
            const SizedBox(height: 12),
            Text(
              '💡 Tip: Busca por nombre: "$nombreArchivo"',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copia de Seguridad')),
      body: _estaCargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Procesando...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _construirTarjetaAccion(
                  titulo: 'Exportar Datos',
                  descripcion:
                      'Guarda todos tus datos en un archivo de respaldo (.json). Transfiere este archivo a un lugar seguro como tu email, Google Drive o tu computador.',
                  etiquetaBoton: 'Exportar Datos',
                  icono: Icons.cloud_upload_outlined,
                  alPresionar: _exportarDatos,
                  colorBoton: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                _construirTarjetaAccion(
                  titulo: 'Importar Datos',
                  descripcion:
                      'Restaura tus datos desde un archivo de respaldo. ADVERTENCIA: Esta acción borrará permanentemente todos los datos actuales de la aplicación.',
                  etiquetaBoton: 'Importar Datos',
                  icono: Icons.cloud_download_outlined,
                  alPresionar: _importarDatos,
                  colorBoton: TemaApp._colorAdvertencia,
                ),
                const SizedBox(height: 24),
                _construirTarjetaAccion(
                  titulo: 'Otorgar Permisos de Almacenamiento',
                  descripcion:
                      'Asegúrate de que la aplicación tenga los permisos necesarios para acceder al almacenamiento y guardar/cargar tus copias de seguridad.',
                  etiquetaBoton: 'Abrir Ajustes de Permisos',
                  icono: Icons.settings_applications_outlined,
                  alPresionar: () async {
                    await _manejarPermisoAlmacenamiento();
                    if (await Permission.manageExternalStorage.isGranted) {
                      _mostrarSnackbar(
                        'Permiso de almacenamiento concedido.',
                        esError: false,
                      );
                    } else {
                      _mostrarSnackbar(
                        'Permiso de almacenamiento no concedido.',
                        esError: true,
                      );
                    }
                  },
                  colorBoton: Colors.blueGrey,
                ),
              ],
            ),
    );
  }

  Widget _construirTarjetaAccion({
    required String titulo,
    required String descripcion,
    required String etiquetaBoton,
    required IconData icono,
    required VoidCallback alPresionar,
    required Color colorBoton,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(descripcion, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(icono),
              label: Text(etiquetaBoton),
              style: ElevatedButton.styleFrom(backgroundColor: colorBoton),
              onPressed: alPresionar,
            ),
          ],
        ),
      ),
    );
  }
}

//==============================================================================
// 🐞 HIVE DEBUG SCREEN
//==============================================================================

class PantallaDepuracionHive extends StatefulWidget {
  const PantallaDepuracionHive({super.key});

  @override
  EstadoPantallaDepuracionHive createState() => EstadoPantallaDepuracionHive();
}

class EstadoPantallaDepuracionHive extends State<PantallaDepuracionHive> {
  String? cajaSeleccionada;
  Map<dynamic, dynamic> contenidoCaja = {};
  final List<String> cajas = [
    'bancos', 'movimientos', 'ajustes', 'notas', 'metas', 'metasHogar',
    'debitos', 'cuentasUVT', 'uvtValoresIniciales', 'bienesUVT',
    'fechaDeclaracionUVT', 'categorias', 'uvt', 'recordatorios',
    'finanzasHogar', // Cajas nuevas añadidas para depuración
  ];

  void _cargarContenido() {
    if (cajaSeleccionada != null && Hive.isBoxOpen(cajaSeleccionada!)) {
      final caja = Hive.box(cajaSeleccionada!);
      setState(() => contenidoCaja = caja.toMap());
    } else {
      setState(() => contenidoCaja = {});
    }
  }

  void _eliminarEntrada(dynamic llave) async {
    await Hive.box(cajaSeleccionada!).delete(llave);
    _cargarContenido();
  }

  void _limpiarCaja() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: Text(
          'Esto eliminará TODOS los datos de la caja "$cajaSeleccionada".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaApp._colorError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar Eliminación'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await Hive.box(cajaSeleccionada!).clear();
      _cargarContenido();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Depurar Base de Datos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              hint: const Text('Selecciona una caja Hive'),
              initialValue: cajaSeleccionada,
              isExpanded: true,
              items: cajas
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (valor) {
                setState(() => cajaSeleccionada = valor);
                _cargarContenido();
              },
            ),
            const SizedBox(height: 16),
            if (cajaSeleccionada != null)
              Expanded(
                child: contenidoCaja.isEmpty
                    ? const Center(child: Text('Caja vacía o no seleccionada.'))
                    : ListView(
                        children: contenidoCaja.entries.map((entrada) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(
                                'Key: [${entrada.key}]',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(jsonEncode(entrada.value)),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: TemaApp._colorError,
                                ),
                                onPressed: () => _eliminarEntrada(entrada.key),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            if (cajaSeleccionada != null && contenidoCaja.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: Text('Limpiar toda la caja "$cajaSeleccionada"'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaApp._colorError,
                  ),
                  onPressed: _limpiarCaja,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//==============================================================================
// ⚙️ BACKGROUND LOGIC AND HELPER FUNCTIONS
//==============================================================================

/// Obtiene las cuentas del banco en el orden guardado por el usuario.
/// Gets the bank accounts in the order saved by the user.
List<MapEntry<int, dynamic>> getOrderedAccounts() {
  try {
    final bankBox = Hive.box('bancos');
    final settingsBox = Hive.box('ajustes');

    // Obtener todas las cuentas únicas por ID
    final Map<int, dynamic> cuentasUnicas = {};
    for (var key in bankBox.keys) {
      final cuenta = bankBox.get(key);
      if (cuenta != null) {
        cuentasUnicas[key] = cuenta;
      }
    }

    final defaultOrder = cuentasUnicas.keys.toList();
    final savedOrder = List<int>.from(
      settingsBox.get('ordenCuentas', defaultValue: defaultOrder),
    );

    // Filtrar y mantener solo las cuentas que existen y son únicas
    final validOrder = <int>[];
    final idsVistos = <int>{};

    // Primero las cuentas en el orden guardado
    for (var id in savedOrder) {
      if (cuentasUnicas.containsKey(id) && !idsVistos.contains(id)) {
        validOrder.add(id);
        idsVistos.add(id);
      }
    }

    // Luego cualquier cuenta que no esté en el orden guardado
    for (var id in defaultOrder) {
      if (!idsVistos.contains(id)) {
        validOrder.add(id);
        idsVistos.add(id);
      }
    }

    // Actualizar el orden guardado si es necesario
    if (savedOrder.length != validOrder.length ||
        !_listasIguales(savedOrder, validOrder)) {
      settingsBox.put('ordenCuentas', validOrder);
    }

    return validOrder.map((key) => MapEntry(key, cuentasUnicas[key]!)).toList();
  } catch (e) {
    debugPrint('Error en getOrderedAccounts: $e');
    return [];
  }
}

bool _listasIguales(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Future<void> ejecutarDebitosAutomaticos() async {
  final cajaDebitos = Hive.box('debitos');
  final cajaBancos = Hive.box('bancos');
  final cajaMovimientos = Hive.box('movimientos');
  final hoy = DateTime.now();

  for (var llave in cajaDebitos.keys) {
    final debito = cajaDebitos.get(llave);

    if (debito == null) continue;

    final dia = debito['dia'] as int? ?? 1;
    final ultimaEjecucion = debito['ultimaEjecucion'] as String?;
    final ultima = ultimaEjecucion != null
        ? DateTime.tryParse(ultimaEjecucion) ?? DateTime(2000)
        : DateTime(2000);

    bool ejecutarHoy =
        hoy.day == dia &&
        (ultima.year != hoy.year || ultima.month != hoy.month);

    if (ejecutarHoy) {
      final idCuenta = debito['cuentaId'] as int?;
      final monto = (debito['monto'] as num?)?.toDouble() ?? 0.0;

      if (idCuenta != null) {
        final cuenta = cajaBancos.get(idCuenta);
        final nombreDebito = debito['nombre'] as String? ?? 'Débito automático';

        if (cuenta != null) {
          final saldoActual = (cuenta['balance'] as num?)?.toDouble() ?? 0.0;
          final nuevoSaldo = saldoActual - monto;

          cajaBancos.put(idCuenta, {...cuenta, 'balance': nuevoSaldo});

          cajaMovimientos.add({
            'type': 'Débito automático',
            'amount': monto,
            'account': cuenta['name'] as String? ?? 'Cuenta sin nombre',
            'description': nombreDebito,
            'date': hoy.toIso8601String(),
          });
          debito['ultimaEjecucion'] = hoy.toIso8601String();
        }
      }
    }

    final proximaFecha = _calcularProximaFecha(hoy, dia);
    debito['proximaFecha'] = proximaFecha.toIso8601String();
    cajaDebitos.put(llave, debito);
  }
}

DateTime _calcularProximaFecha(DateTime ultimaEjecucion, int dia) {
  final ahora = DateTime.now();
  int proximoAnio = ahora.year;
  int proximoMes = ahora.month;

  if (ultimaEjecucion.year > 2000) {
    proximoAnio = ultimaEjecucion.year;
    proximoMes = ultimaEjecucion.month;
  }

  DateTime proximaFecha;
  try {
    proximaFecha = DateTime(proximoAnio, proximoMes, dia);
  } catch (e) {
    proximaFecha = DateTime(proximoAnio, proximoMes + 1, 0);
  }

  if (proximaFecha.isBefore(ahora)) {
    proximoMes++;
    if (proximoMes > 12) {
      proximoMes = 1;
      proximoAnio++;
    }
    try {
      proximaFecha = DateTime(proximoAnio, proximoMes, dia);
    } catch (e) {
      proximaFecha = DateTime(proximoAnio, proximoMes + 1, 0);
    }
  }
  return proximaFecha;
}

DateTime? _calcularProximaFechaRecordatorio(Map recordatorio) {
  try {
    final ahora = DateTime.now();
    final tipoFrecuencia =
        recordatorio['tipoFrecuencia'] as String? ?? 'Mensual';

    switch (tipoFrecuencia) {
      case 'Una vez':
        final fechaStr = recordatorio['fecha'] as String?;
        if (fechaStr == null || fechaStr.isEmpty) return null;
        return DateTime.tryParse(fechaStr);
      case 'Mensual':
        final dia = recordatorio['dia'] as int? ?? ahora.day;
        DateTime fechaIntento = DateTime(ahora.year, ahora.month, dia);
        if (fechaIntento.isBefore(ahora.subtract(const Duration(days: 1)))) {
          return DateTime(ahora.year, ahora.month + 1, dia);
        }
        return fechaIntento;
      case 'Anual':
        final dia = recordatorio['dia'] as int? ?? ahora.day;
        final mes = recordatorio['mes'] as int? ?? ahora.month;
        DateTime fechaIntento = DateTime(ahora.year, mes, dia);
        if (fechaIntento.isBefore(ahora.subtract(const Duration(days: 1)))) {
          return DateTime(ahora.year + 1, mes, dia);
        }
        return fechaIntento;
      default:
        return null;
    }
  } catch (e) {
    debugPrint('Error al calcular próxima fecha de recordatorio: $e');
    return null;
  }
}
