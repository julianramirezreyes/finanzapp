# AGENTS.md

> Este archivo define cómo los agentes de código deben entender, modificar y extender este proyecto.
> No es documentación para humanos: es una guía operativa para ejecución automatizada.

---

# 🧠 PRINCIPIOS RECTORES (MANDATORIOS)

## 1. Diseño y mantenibilidad
- Aplicar SOLID en todo momento.
- Evitar duplicación (DRY), pero sin sobre-abstracción prematura.
- Preferir soluciones simples (KISS).
- No implementar funcionalidades no requeridas (YAGNI).

## 2. Arquitectura
- Respetar separación de responsabilidades estricta.
- No mezclar lógica de negocio con infraestructura.
- Mantener independencia de frameworks cuando sea posible.

## 3. Código limpio
- Nombres explícitos y semánticos.
- Funciones pequeñas (máx ~20-30 líneas).
- Evitar efectos secundarios ocultos.
- No usar comentarios para explicar código mal escrito.

## 4. Evolutividad
- Todo cambio debe facilitar futuras extensiones.
- Evitar acoplamiento fuerte entre módulos.

---

# 🏗️ ESTRUCTURA ARQUITECTÓNICA

## Backend (recomendado)
Seguir principios de Clean Architecture / Hexagonal:

- `domain/`
  - Entidades
  - Value Objects
  - Interfaces (puertos)

- `application/`
  - Casos de uso
  - Orquestación de lógica

- `infrastructure/`
  - Base de datos
  - APIs externas
  - Implementaciones concretas

- `interfaces/`
  - Controllers / handlers / routes

### Reglas clave:
- Domain NO depende de nada externo
- Application depende solo de Domain
- Infrastructure implementa interfaces del Domain/Application

---

## Frontend (recomendado)

- `core/` → lógica de negocio (si aplica)
- `features/` → módulos por dominio
- `shared/` → componentes reutilizables
- `infrastructure/` → API clients

### Reglas clave:
- Componentes deben ser lo más dumb posible
- Separar estado de presentación
- Evitar lógica de negocio en componentes UI

---

# 🔌 INTEGRACIÓN Y COMUNICACIÓN

## Reglas
- Toda comunicación externa debe pasar por adaptadores
- Nunca acoplar directamente servicios externos

## Patrones recomendados:
- Retry con backoff exponencial
- Circuit Breaker para servicios inestables
- Idempotencia en operaciones críticas
- Event-driven cuando haya desacoplamiento entre módulos

---

# 🧪 TESTING (OBLIGATORIO)

## Tipos de test
- Unitarios → lógica de negocio
- Integración → interacción entre componentes
- E2E → flujos críticos

## Reglas
- Todo código nuevo debe incluir tests
- No se permite código sin cobertura en lógica crítica
- Tests deben ser deterministas

## Anti-patrones
- Tests frágiles
- Tests acoplados a implementación
- Mocking excesivo

---

# 🎯 CONVENCIONES DE CÓDIGO

## Generales
- TypeScript strict mode (si aplica)
- Evitar `any`
- Preferir inmutabilidad

## Naming
- Clases → PascalCase
- Variables/funciones → camelCase
- Constantes → UPPER_CASE

## Funciones
- Deben hacer UNA sola cosa
- Evitar más de 3 parámetros (usar objetos)

---

# ⚠️ ANTI-PATRONES PROHIBIDOS

- God classes
- Lógica de negocio en controllers
- Uso excesivo de `if/else` en lugar de polimorfismo
- Acoplamiento a frameworks
- Código duplicado
- Promesas sin manejo de errores

---

# 🔄 MANEJO DE ERRORES

- Nunca ignorar errores
- Usar errores de dominio cuando aplique
- No filtrar errores técnicos hacia el usuario final

---

# 📦 GESTIÓN DE DEPENDENCIAS

- Evitar librerías innecesarias
- Evaluar:
  - Mantenimiento
  - Comunidad
  - Tamaño
  - Seguridad

---

# 🚀 WORKFLOW DE DESARROLLO

## Antes de hacer commit:
- Ejecutar lint
- Ejecutar tests
- Validar tipos

## Commits
- Deben ser pequeños y descriptivos
- Formato recomendado:
  - feat:
  - fix:
  - refactor:
  - test:

---

# 🔐 SEGURIDAD

- Validar inputs SIEMPRE
- Nunca confiar en datos externos
- Sanitizar datos
- Manejar secretos fuera del código

---

# ⚙️ PERFORMANCE

- Evitar cálculos innecesarios
- Lazy loading cuando aplique
- Evitar loops innecesarios
- Medir antes de optimizar

---

# 📊 OBSERVABILIDAD

- Logging estructurado
- Manejo de métricas básicas
- Trazabilidad en flujos críticos

---

# 🧠 DECISIONES ARQUITECTÓNICAS

Cuando el agente tome decisiones debe priorizar:

1. Mantenibilidad > rapidez
2. Claridad > optimización prematura
3. Desacoplamiento > conveniencia
4. Testabilidad > complejidad

---

# 🧩 REFACTORING

El agente debe:

- Identificar code smells:
  - Métodos largos
  - Clases con múltiples responsabilidades
  - Código duplicado

- Aplicar:
  - Extract method
  - Introduce interface
  - Replace conditionals with polymorphism

---

# 📌 REGLA FINAL

Si hay ambigüedad:
- Elegir la solución más simple que cumpla los requisitos
- Priorizar legibilidad sobre "ingeniería elegante"
