# FinanzApp v2 🚀

**FinanzApp v2** es una solución integral para la gestión de finanzas personales y del hogar, diseñada para ofrecer control total, transparencia y automatización. Construida con una arquitectura moderna y escalable, combina la flexibilidad de Flutter con la robustez de Go (Golang).

<img width="499" height="895" alt="image" src="https://github.com/user-attachments/assets/97e29fcd-1bfd-4823-8995-1ec3efb07fbc" />
<img width="499" height="895" alt="image" src="https://github.com/user-attachments/assets/ec46b0c5-23e6-4118-b800-09112f811420" />
<img width="499" height="895" alt="image" src="https://github.com/user-attachments/assets/df651984-1f14-44d1-9ce9-c1709b503dcc" />
<img width="499" height="895" alt="image" src="https://github.com/user-attachments/assets/44164a85-5857-41aa-9ab8-34ac61814413" />
<img width="499" height="895" alt="image" src="https://github.com/user-attachments/assets/57395b2a-b48f-4fdf-be82-afa54ed0abf9" />

---

## 📋 Tabla de Contenidos

1. [Visión General](#-visión-general)
2. [Stack Tecnológico](#-stack-tecnológico)
3. [Características Principales](#-características-principales)
4. [Arquitectura del Proyecto](#-arquitectura-del-proyecto)
5. [Configuración de Desarrollo](#-configuración-de-desarrollo)
6. [Migraciones de Base de Datos](#-migraciones-de-base-de-datos)
7. [Construcción y Despliegue](#-construcción-y-despliegue)
8. [Contribución](#-contribución)

---

## 🌟 Visión General

El proyecto nace de la necesidad de gestionar no solo gastos individuales, sino la compleja dinámica de las **finanzas compartidas** en pareja o con roomies. A diferencia de otras apps que solo permiten "dividir cuentas", FinanzApp v2 implementa un **Motor de Liquidación (Settlement Engine)** que permite cerrar meses, calcular deudas cruzadas y mantener un historial inmutable.

## 🔥 Funcionalidades Principales

### 🏡 Finanzas del Hogar (Household)

El corazón colaborativo de la aplicación.

- **Historial Unificado**: Visualiza ingresos y gastos de ambos miembros en una línea de tiempo compartida.
- **Snapshots Mensuales**: Cada cierre de mes genera una "foto" estática de las finanzas, evitando que cambios futuros alteren el historial pasado.
- **Motor de Liquidación**:
  - Calcula automáticamente quién le debe a quién basándose en splits configurables (50/50, Proporcional al ingreso, o Personalizado).
  - Estado de "Deudor/Acreedor" claro y conciso.
- **Transacciones Fantasma**: Opción "No afectar saldo" para registrar movimientos sin impactar las cuentas reales (ideal para tracking o auditoría).
- **Distribución de Gastos**: Muestra valores en dinero además de porcentajes en la configuración de presupuesto.
- **Disponibilidad Mensual**: Gráfico de assigned vs budgeted por categoría (Gastos, Ahorro, Inversión).

### 👤 Finanzas Personales

Gestión granular de tu dinero.

- **Presupuesto "Waterfall"**: Metodología de flujo de dinero: _Ingresos -> Gastos Fijos -> Ahorro -> Inversión -> Gastos Libres_.
- **Banner de Disponible**: Muestra cuánto dinero queda para presupuesto personal después de aporte al hogar.
- **Contribución por Pareja**: En el hogar, cada meta/gasto muestra cuánto aporta cada miembro según su proporción de ingresos.
- **Control Tributario (DIAN Colombia)**: 
  - Monitoreo automático de topes para declaración de renta.
  - **UVT Personalizable**: Valor UVT editable por el usuario para cálculos de declaración.
- **Bóveda de Cuentas (Vault)**:
  - Almacenamiento seguro de números de tarjetas, CVVs y fechas de vencimiento.
  - Tipos de tarjeta: Débito y Crédito.
  - Campos de fecha de corte y cuotas para tarjetas de crédito.
  - **Resumen de Deuda**: Panel mostrando deuda total y por tarjeta.
  - **Drag & Drop**: Reordenar tarjetas y cuentas dentro de la bóveda.
  - Interfaz protegida con opción de "Ocultar/Mostrar" y copiado rápido.
- **Pagar Tarjeta de Crédito**: Botón para registrar pagos de tarjetas desde la pantalla de transacciones.
- **Activos y Patrimonio**: Registro de vehículos, inmuebles y otros activos para el cálculo de patrimonio neto.

### ⚙️ Automatización y Utilidades

- **Pagos Recurrentes**: Sistema para detectar y sugerir/ejecutar pagos fijos mensuales.
- **Categorías Dinámicas**: Clasificación inteligente de gastos.
- **Modo Privacidad**: Oculta todos los saldos sensibles con un solo toque (ideal para usar la app en público).
- **Drag & Drop**: Reordenar cuentas en la pantalla de administración.

---

## 🛠 Stack Tecnológico

La aplicación sigue los principios de **Clean Architecture** para garantizar mantenibilidad y testabilidad.

### Frontend (Mobile & Web)

- **Framework**: [Flutter](https://flutter.dev/) (Dart) - Despliegue en Android, iOS y Web.
- **Gestión de Estado**: [Riverpod 2.0](https://riverpod.dev/) (StateNotifier & Providers).
- **Navegación**: [GoRouter](https://pub.dev/packages/go_router) (Rutas declarativas y Deep Linking).
- **Cliente HTTP**: [Dio](https://pub.dev/packages/dio) con interceptores para Auth y manejo de errores.
- **Gráficos**: [FL Chart](https://pub.dev/packages/fl_chart).
- **Almacenamiento Seguro**: `flutter_secure_storage` para Tokens JWT y credenciales.

### Backend (API REST)

- **Lenguaje**: [Go (Golang)](https://go.dev/).
- **Router**: [Chi](https://github.com/go-chi/chi) (Ligero y compatible con `net/http`).
- **Base de Datos**: [PostgreSQL](https://www.postgresql.org/).
- **Autenticación**: JWT (JSON Web Tokens) con Middleware personalizado.

### Base de Datos (Schema)

El diseño de base de datos es relacional y normalizado:

- `finanzapp_users`: Usuarios y perfiles.
- `finanzapp_accounts`: Cuentas bancarias y efectivo.
- `finanzapp_transactions`: Movimientos (Ingresos, Gastos, Transferencias).
- `finanzapp_households`: Grupos familiares.
- `finanzapp_settlements`: Historial de cierres de mes.
- `finanzapp_budgets`: Metas y presupuestos.
- `finanzapp_vault_items`: Información sensible de tarjetas y cuentas.
- `finanzapp_pockets`: Sub-cuentas dentro de cuentas principales.
- `finanzapp_assets`: Registro de activos para patrimonio.
- `finanzapp_user_tax_settings`: Configuración de UVT por usuario.

---

## 🏗 Arquitectura del Proyecto

### Frontend (`lib/`)

Estructura basada en **Features** (Funcionalidades):

```
lib/
├── core/                   # Configuraciones globales (Theme, Dio, Router, Config)
├── features/
│   ├── auth/               # Login, Registro, Splash
│   ├── dashboard/          # Pantalla principal, Resumen
│   ├── accounts/           # Cuentas, Bóveda, Bolsillos
│   ├── transactions/       # CRUD de movimientos
│   ├── household/          # Lógica de hogar y liquidación
│   ├── budgets/            # Presupuestos y Metas
│   ├── tax/                # Declaración de renta y UVT
│   ├── assets/             # Activos y Patrimonio
│   ├── automation/         # Pagos recurrentes
│   ├── history/            # Historial de transacciones
│   ├── periods/            # Períodos de liquidación
│   └── settings/           # Configuración de la app
├── shared/                 # Widgets reutilizables (Botones, Inputs, Cards)
└── main.dart               # Punto de entrada
```

### Backend (`internal/`)

Siguiendo la estructura estándar de Go:

```
internal/
├── application/            # Casos de uso y Lógica de Negocio (Services)
├── domain/                 # Modelos y Interfaces (Core struct definitions)
├── infrastructure/         # Implementación técnica (DB, External APIs)
└── interfaces/             # Capa de entrada (HTTP Handlers, Routes)
```

---

## 🚀 Configuración de Desarrollo

### Requisitos Previos

- **Flutter SDK**: Stable channel (3.10+).
- **Go**: 1.20+.
- **PostgreSQL**: Instancia local o remota.
- **Git**.

### Clonar Repositorio

```bash
git clone https://github.com/tu-usuario/finanzapp-v2.git
cd finanzapp-v2
```

### Configuración del Backend

1. **Navegar al directorio del backend**:

```bash
cd backend/api_go
```

2. **Crear archivo `.env`** en `backend/api_go/.env`:

```env
DATABASE_URL=postgresql://usuario:password@host:5432/finanzapp
PORT=8080
JWT_SECRET=tu_secret_aqui
```

3. **Instalar dependencias Go**:

```bash
go mod tidy
```

4. **Ejecutar migraciones de base de datos**:

```bash
# El servidor ejecuta las migraciones automáticamente al iniciar
# O puedes ejecutarlas manualmente:
go run cmd/apply_sql/main.go
```

5. **Opcional: Crear base de datos local desde cero**:

Si prefieres crear tu propia base de datos en lugar de usar la existente, puedes usar el script de setup:

```bash
# a) Crear la base de datos local
createdb finanzapp_local

# b) Configurar DATABASE_URL
export DATABASE_URL="postgresql://tu_usuario:tu_password@localhost:5432/finanzapp_local"

# c) Ejecutar el script de setup (incluye schema + seed)
psql $DATABASE_URL -f db/setup_local_db.sql
```

El script `db/setup_local_db.sql` incluye:
- Schema completo de todas las tablas
- Triggers y funciones necesarias
- Datos de prueba (cuentas, presupuestos, transacciones demo)

**Nota**: Después de crear tu propia base de datos, el login de usuario funciona normal (te registras desde la app), los datos de seed son solo para referencia.

6. **Iniciar el servidor**:

```bash
go run cmd/server/main.go
```

El servidor estará disponible en `http://localhost:8080`

### Configuración del Frontend

1. **Navegar al directorio del frontend**:

```bash
cd frontend/finanzapp_v2
```

2. **Instalar dependencias**:

```bash
flutter pub get
```

3. **Configurar URL del Backend**:

La URL del backend se configura en `lib/core/config/backend_config.dart`:

```dart
class BackendConfig {
  final BackendMode mode;
  final String localUrl;

  const BackendConfig({
    this.mode = BackendMode.online,  // Cambiar a BackendMode.local para desarrollo
    this.localUrl = 'http://TU_IP_LOCAL:8080/api',
  });
}
```

Para desarrollo local:
- Cambia `mode` a `BackendMode.local`
- Actualiza `localUrl` con tu IP local y puerto del backend
- El puerto por defecto del backend es 8080

4. **Ejecutar la app**:

```bash
flutter run
```

### Notas de Desarrollo

- **Cambiar entre Local y Online**: En la pantalla de login, o modificando `backend_config.dart`
- **Hot Reload**: Flutter soporta hot reload durante el desarrollo
- **Logs del Backend**: El servidor muestra logs en consola

---

## 🗄 Migraciones de Base de Datos

El proyecto usa migraciones SQL incrementales. Cada migración adds nuevas tablas o campos.

### Lista de Migraciones

| # | Archivo | Descripción |
|---|---------|-------------|
| 001 | `001_core_hardening.sql` | Tablas principales (users, accounts, transactions, households) |
| 002 | `002_vault_and_ordering.sql` | Bóveda de tarjetas y ordenamiento |
| 003 | `003_split_method.sql` | Método de división en households |
| 004 | `004_allow_null_user_b.sql` | Permitir user_b null |
| 005 | `005_fix_transaction_delete_cascade.sql` | Corrección de cascada en transacciones |
| 006 | `006_fix_period_trigger.sql` | Trigger para períodos |
| 007 | `007_paid_with_credit_card_and_tax_cc_flag.sql` | Pagos con tarjeta de crédito |
| 008 | `008_automation_context_budget.sql` | Contexto de automatización |
| 009 | `009_soft_delete_accounts.sql` | Soft delete para cuentas |
| 010 | `010_credit_card_fields.sql` | Campos de tarjeta de crédito |
| 010 | `010_household_snapshot_sync.sql` | Sync de snapshots |
| 011 | `011_pockets.sql` | Sistema de bolsillos |
| 012 | `012_vault_card_id.sql` | ID de tarjeta en transacciones |
| 013 | `013_installments.sql` | Cuotas de tarjetas |
| 014 | `014_user_tax_settings.sql` | Configuración de UVT por usuario |

### Ejecutar Migraciones

Las migraciones se ejecutan automáticamente cuando el servidor inicia. También puedes ejecutarlas manualmente:

```bash
# Opción 1: Con el binary del servidor
./server migrate

# Opción 2: Manualmente con psql
psql $DATABASE_URL -f migrations/001_core_hardening.sql
psql $DATABASE_URL -f migrations/002_vault_and_ordering.sql
# ... etc
```

---

## 📦 Construcción y Despliegue

### Frontend (APK para Android)

#### Desarrollo
```bash
cd frontend/finanzapp_v2
flutter run
```

#### Build de Debug
```bash
flutter build apk --debug
```
El APK se generará en `build/app/outputs/flutter-apk/app-debug.apk`

#### Build de Release
```bash
flutter build apk --release
```
El APK se generará en `build/app/outputs/flutter-apk/app-release.apk`

#### Build para Releases (GitHub)
```bash
# Asegúrate de tener las claves de firma configuradas
flutter build apk --release --target-platform android-arm64

# O para todas las arquitecturas
flutter build apk --release
```

### Frontend (Web)

```bash
flutter build web --release
```
La carpeta `build/web` contendrá los archivos estáticos para desplegar en Vercel, Netlify, o cualquier hosting web.

### Backend (Producción)

#### Compilar
```bash
cd backend/api_go
go build -o server cmd/server/main.go
```

#### Ejecutar
```bash
./server
```

El servidor leerá las variables de entorno:
- `DATABASE_URL` (requerida)
- `PORT` (default: 8080)
- `JWT_SECRET` (requerida para auth)

#### Despliegue en Render

1. Conectar repositorio a Render
2. Configurar variables de entorno
3. Build Command: `go build -o server cmd/server/main.go`
4. Start Command: `./server`

---

## 🤝 Contribución

Este proyecto es personal pero abierto a mejoras. Si deseas contribuir:

1. Haz un Fork del proyecto.
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`).
3. Haz Commit (`git commit -m 'Add: Nueva funcionalidad'`).
4. Haz Push (`git push origin feature/nueva-funcionalidad`).
5. Abre un Pull Request.

---

## 📱 Estructura de Features

### Accounts (Cuentas y Bóveda)
- **Pantalla de cuentas**: Lista de cuentas con drag & drop para reordenar
- **Bóveda**: Almacenamiento seguro de tarjetas y cuentas con drag & drop
- **Bolsillos (Pockets)**: Sub-cuentas dentro de cuentas principales
- **Resumen de Deuda**: Panel mostrando deuda por tarjeta de crédito

### Transactions (Transacciones)
- CRUD completo de transacciones
- Pagar tarjeta de crédito
- Transferencias entre cuentas y bolsillos
- Filtrado por tipo, categoría, fecha

### Household (Hogar)
- Crear/unirse a hogar
- Historial unificado de movimientos
- Snapshots mensuales
- Motor de liquidación
- Distribución de gastos con valores en dinero
- Gráfico de assigned vs budgeted

### Budgets (Presupuestos)
- Metas y gastos con tipos (expense, saving, investment)
- Configuración de porcentajes
- Banner de disponible personal
- Contribución por pareja

### Tax (Declaración de Renta)
- Monitoreo de topes DIAN
- **UVT Personalizable**: Valor editable por el usuario
- Historial por año

### Assets (Activos)
- Registro de vehículos, inmuebles
- Cálculo de patrimonio neto

### Automation (Automatización)
- Pagos recurrentes
- Detección automática de patrones

---

**Desarrollado con ❤️ para llevar las finanzas al siguiente nivel.**
