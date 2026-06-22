# 🌱 Feed the Future — Flutter App

**Plataforma inteligente de rescate alimentario con IA**

---

## 🏗️ Arquitectura

```
lib/
├── main.dart                    # Entry point
├── firebase_options.dart        # Firebase config (NO commitear con claves reales)
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart   # Colecciones, roles, status, etc.
│   ├── errors/
│   │   └── failures.dart        # Tipos de error (AuthFailure, FirestoreFailure...)
│   ├── routes/
│   │   └── app_router.dart      # GoRouter con redirect según auth
│   ├── theme/
│   │   └── app_theme.dart       # Colores, estilos, temas
│   └── widgets/
│       └── main_shell.dart      # NavigationBar + ShellRoute
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/     # Firebase Auth + Firestore
    │   │   ├── models/
    │   │   │   └── app_user_model.dart
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── app_user.dart
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart     # Interface
    │   │   └── usecases/
    │   │       └── auth_usecases.dart
    │   └── presentation/
    │       ├── pages/
    │       │   ├── splash_page.dart
    │       │   ├── login_page.dart
    │       │   └── register_page.dart
    │       └── providers/
    │           └── auth_provider.dart       # Riverpod providers
    │
    ├── donations/
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── donation_model.dart      # Firestore ↔ Entity
    │   │   └── repositories/
    │   │       └── donation_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── donation.dart
    │   │   └── repositories/
    │   │       └── donation_repository.dart  # Interface
    │   └── presentation/
    │       ├── pages/
    │       │   ├── donations_list_page.dart
    │       │   ├── donation_form_page.dart  # Stepper de 3 pasos
    │       │   └── donation_detail_page.dart
    │       ├── providers/
    │       │   └── donation_provider.dart   # Streams + filter state
    │       └── widgets/
    │           ├── donation_card.dart
    │           └── donation_filter_bar.dart
    │
    ├── impact/
    │   └── presentation/
    │       └── pages/
    │           └── impact_dashboard_page.dart  # Gráficas fl_chart + ESG
    │
    └── community/
        └── presentation/
            └── pages/
                └── community_home_page.dart
```

---

## 🚀 Setup

### 1. Requisitos
- Flutter ≥ 3.0.0
- Dart ≥ 3.0.0
- Firebase CLI + FlutterFire CLI

### 2. Clonar e instalar
```bash
git clone https://github.com/tu-usuario/feed-the-future.git
cd feed-the-future/flutter_app
flutter pub get
```

### 3. Configurar Firebase
```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar con tu proyecto Firebase
flutterfire configure --project=feed-the-future-mexico
```

Esto regenera `lib/firebase_options.dart` con tus credenciales reales.

### 4. Variables de entorno (opcional)
Crea `.env` en la raíz del proyecto:
```
GOOGLE_MAPS_API_KEY=tu_clave_aqui
VERTEX_AI_PROJECT_ID=tu_proyecto
```

### 5. Ejecutar
```bash
flutter run
```

---

## 🔥 Firestore — Estructura de colecciones

```
/users/{userId}
  - email, displayName, role, organizationName
  - location: { latitude, longitude, address, city }
  - createdAt, isVerified, reputationScore

/donations/{donationId}
  - donorId, donorName, category, name, description
  - quantity, unit, expirationDate
  - status: pending | available | matched | in_transit | delivered
  - riskScore: SAFE | CONDITIONAL | REJECT
  - location: { latitude, longitude, address, geohash }
  - assignedNgoId, assignedNgoName, assignedVolunteerId

/pickup_requests/{requestId}
  - donationId, ngoId, volunteerId
  - scheduledAt, completedAt, status

/delivery_routes/{routeId}
  - volunteerId, stops: [], optimizedAt
  - totalDistanceKm, estimatedMinutes

/impact_metrics/{metricId}
  - userId, period (month/year)
  - kgRescued, co2Saved, familiesBenefited, deliveriesCompleted
```

### Reglas de seguridad (Firestore)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /donations/{donationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
        request.resource.data.donorId == request.auth.uid;
      allow update: if request.auth != null && (
        resource.data.donorId == request.auth.uid ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['NGO', 'ADMIN', 'VOLUNTEER']
      );
    }
  }
}
```

---

## 🤖 Cloud Functions (Backend)

Las Cloud Functions se activan por eventos de Firestore:

| Función | Trigger | Descripción |
|---------|---------|-------------|
| `onDonationCreated` | `donations/{id}` create | Valida reglas sanitarias → asigna riskScore |
| `onCommunityRequest` | `community_requests/{id}` | Activa motor de matching |
| `optimizeRoute` | HTTP call | Calcula ruta VRP para voluntario |
| `computeImpactMetrics` | Scheduled (daily) | Agrega métricas de impacto |
| `sendDonationAlerts` | `donations/{id}` update | Notificaciones FCM |

---

## 📱 Roles de usuario

| Rol | Pantallas | Acciones |
|-----|-----------|----------|
| `DONOR` | Lista + Crear + Mi historial | Registrar donaciones |
| `NGO` | Lista + Reclamar + Rutas | Aceptar y gestionar donaciones |
| `VOLUNTEER` | Rutas asignadas | Confirmar pickup/delivery |
| `COMMUNITY` | Comunidad + Solicitudes | Solicitar alimentos |
| `ADMIN` | Dashboard completo | Gestión total |

---

## 🧩 Stack técnico

| Capa | Tecnología |
|------|-----------|
| UI | Flutter + Material 3 |
| Estado | Riverpod 2 |
| Navegación | GoRouter |
| Backend | Firebase (Auth, Firestore, Functions, Storage, FCM) |
| Gráficas | fl_chart |
| Mapas | Google Maps Flutter |
| HTTP | Dio + Retrofit |
| Storage local | Hive + SharedPreferences |
| Dominio | Clean Architecture + dartz |

---

## 📦 Comandos útiles

```bash
# Build runner (generar código)
flutter pub run build_runner build --delete-conflicting-outputs

# Tests
flutter test

# Build APK release
flutter build apk --release

# Build iOS
flutter build ios --release

# Lint
flutter analyze
```

---

## 🌱 Siguientes pasos para producción

- [ ] Integrar Google Maps para selección de ubicación real
- [ ] Implementar notificaciones push con FCM
- [ ] Conectar Cloud Functions para scoring de riesgo con ML
- [ ] Agregar carga de fotos a Firebase Storage
- [ ] Implementar algoritmo VRP con OR-Tools en backend
- [ ] Dashboard admin web (Flutter Web)
- [ ] Tests unitarios y de integración completos
- [ ] CI/CD con GitHub Actions + Fastlane

---

*Feed the Future © 2025 — Tecnología para combatir el hambre en México 🇲🇽*
