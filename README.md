# FinanzApp v2 🚀

**FinanzApp v2** es una solución integral para la gestión de finanzas personales y del hogar, diseñada para ofrecer control total, transparencia y automatización. Construida con una arquitectura moderna y escalable, combina la flexibilidad de Flutter con la robustez de Go (Golang).

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

### 👤 Finanzas Personales

Gestión granular de tu dinero.

- **Presupuesto "Waterfall"**: Metodología de flujo de dinero: _Ingresos -> Gastos Fijos -> Ahorro -> Inversión -> Gastos Libres_.
- **Control Tributario (DIAN Colombia)**: Monitoreo automático de topes para declaración de renta (Ingresos, Patrimonio, Consumos, Transferencias).
- **Bóveda de Cuentas (Vault)**:
  - Almacenamiento seguro de números de tarjetas, CVVs y fechas de vencimiento.
  - Interfaz protegida con opción de "Ocultar/Mostrar" y copiado rápido.
- **Activos y Patrimonio**: Registro de vehículos, inmuebles y otros activos para el cálculo de patrimonio neto.

### ⚙️ Automatización y Utilidades

- **Pagos Recurrentes**: Sistema para detectar y sugerir/ejecutar pagos fijos mensuales.
- **Categorías Dinámicas**: Clasificación inteligente de gastos.
- **Modo Privacidad**: Oculta todos los saldos sensibles con un solo toque (ideal para usar la app en público).

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
- **Base de Datos**: [PostgreSQL](https://www.postgresql.org/) (Hospedada en Supabase/Render).
- **Autenticación**: JWT (JSON Web Tokens) con Middleware personalizado.
- **Infraestructura**:
  - **Render**: Hosting del servicio Backend.
  - **GitHub Actions**: Workflow `keep_alive` para evitar "Cold Starts" en el tier gratuito.

### Base de Datos (Schema)

El diseño de base de datos es relacional y normalizado:

- `finanzapp_users`: Usuarios y perfiles.
- `finanzapp_accounts`: Cuentas bancarias y efectivo.
- `finanzapp_transactions`: Movimientos (Ingresos, Gastos, Transferencias).
- `finanzapp_households`: Grupos familiares.
- `finanzapp_settlements`: Historial de cierres de mes.
- `finanzapp_budgets`: Metas y presupuestos.

---

## 🏗 Arquitectura del Proyecto

### Frontend (`lib/`)

Estructura basada en **Features** (Funcionalidades):

```
lib/
├── core/                   # Configuraciones globales (Theme, Dio, Router)
├── features/
│   ├── auth/               # Login, Registro, Splash
│   ├── dashboard/          # Pantalla principal, Resumen
│   ├── transactions/       # CRUD de movimientos
│   ├── household/          # Lógica de hogar y liquidación
│   ├── budgeting/          # Presupuestos y Metas
│   └── ...
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

## 🚀 Instalación y Despliegue

### Requisitos Previos

- **Flutter SDK**: Stable channel (3.10+).
- **Go**: 1.20+.
- **PostgreSQL**: Instancia local o remota.

### Configuración Local

1. **Clonar Repositorio**:

   ```bash
   git clone https://github.com/tu-usuario/finanzapp-v2.git
   ```

2. **Backend (Go)**:

   ```bash
   cd backend/api_go
   # Crear archivo .env basado en variables necesarias (DB_URL, PORT, JWT_SECRET)
   go mod tidy
   go run cmd/server/main.go
   ```

3. **Frontend (Flutter)**:
   ```bash
   cd frontend/finanzapp_v2
   flutter pub get
   # Configurar URL del backend en core/api_config.dart o env vars
   flutter run
   ```

### Despliegue (Producción)

#### Backend (Render)

El backend está configurado para desplegarse automáticamente en **Render** al hacer push a `main`.

- **Dockerfile**: No requerido (Go nativo).
- **Build Command**: `go build -o server cmd/server/main.go`
- **Start Command**: `./server`

#### Frontend (Vercel/Web)

Para desplegar la versión Web:

```bash
flutter build web --release
# Subir carpeta build/web a Vercel/Netlify
```

_Nota: El repositorio ignora `build/` por defecto, excepto `build/web` para facilitar el despliegue manual si es necesario._

---

## 🤝 Contribución

Este proyecto es personal pero abierto a mejoras. Si deseas contribuir:

1. Haz un Fork del proyecto.
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`).
3. Haz Commit (`git commit -m 'Add: Nueva funcionalidad'`).
4. Haz Push (`git push origin feature/nueva-funcionalidad`).
5. Abre un Pull Request.

---

**Desarrollado con ❤️ para llevar las finanzas al siguiente nivel.**
