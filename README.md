# FeedTheFuture — Flutter App

**Plataforma inteligente de rescate alimentario con IA**

---

## Build Status

![Flutter CI](https://github.com/tu-usuario/feed-the-future/actions/workflows/flutter.yml/badge.svg)

---

## Arquitectura

```
lib/
├── main.dart                    # Entry point
├── firebase_options.dart        # Firebase config
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart   # Colecciones, roles, status, etc.
│   ├── errors/
│   │   └── failures.dart        # Tipos de error
│   ├── routes/
│   │   └── app_router.dart      # GoRouter con redirect según auth
│   ├── theme/
│   │   └── app_theme.dart       # Colores, estilos, temas (Material 3)
│   └── widgets/
│       └── main_shell.dart      # NavigationBar + ShellRoute
│
├── features/
│   ├── auth/
│   ├── donations/
│   ├── impact/
│   ├── community/
│   ├── profile/
│   ├── notifications/
│   ├── ratings/
│   └── settings/
│
└── l10n/                        # Localizaciones
```

---

## Setup

### Requisitos
- Flutter >= 3.0.0
- Dart >= 3.0.0
- Firebase CLI + FlutterFire CLI

### Instalar
```bash
git clone <repo>
cd feedthefuture
flutter pub get
```

### Configurar Firebase
```bash
flutterfire configure --project=feedforthefuture
```

### Ejecutar
```bash
flutter run
```

---

## Comandos

```bash
# Tests
flutter test

# Lint + analyze
flutter analyze

# Build APK
flutter build apk --release
```

---

## CI/CD

El proyecto incluye GitHub Actions en `.github/workflows/flutter.yml` que ejecuta:
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`

---

## Stack

| Capa | Tecnología |
|------|-----------|
| UI | Flutter + Material 3 |
| Estado | Riverpod 2 |
| Navegación | GoRouter |
| Backend | Firebase (Auth, Firestore, Functions, Storage, FCM) |
| Gráficas | fl_chart |
| Mapas | Google Maps Flutter |
| HTTP | Dio |
| Local | Hive + SharedPreferences |
| Dominio | Clean Architecture + dartz |

---

*FeedTheFuture © 2025 — Tecnología para combatir el hambre*
