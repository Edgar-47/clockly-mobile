# ClockLy Mobile — Release Checklist

## Build commands

### Development
```bash
flutter run --dart-define=CLOCKLY_API_BASE_URL=http://127.0.0.1:8000/api/v1
# Android emulator:
flutter run --dart-define=CLOCKLY_API_BASE_URL=http://10.0.2.2:8000/api/v1
```

### Staging
```bash
flutter build apk --debug \
  --dart-define=CLOCKLY_API_BASE_URL=https://staging.clockly.app/api/v1
```

### Production — Android APK
```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols/ \
  --dart-define=CLOCKLY_API_BASE_URL=https://api.clockly.app/api/v1 \
  --dart-define=CLOCKLY_PRIVACY_URL=https://clockly.app/privacy \
  --dart-define=CLOCKLY_TERMS_URL=https://clockly.app/terms
```

### Production — Android App Bundle (recommended for Play Store)
```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols/ \
  --dart-define=CLOCKLY_API_BASE_URL=https://api.clockly.app/api/v1 \
  --dart-define=CLOCKLY_PRIVACY_URL=https://clockly.app/privacy \
  --dart-define=CLOCKLY_TERMS_URL=https://clockly.app/terms
```

### Production — iOS
```bash
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/symbols/ \
  --dart-define=CLOCKLY_API_BASE_URL=https://api.clockly.app/api/v1 \
  --dart-define=CLOCKLY_PRIVACY_URL=https://clockly.app/privacy \
  --dart-define=CLOCKLY_TERMS_URL=https://clockly.app/terms
```

> **Keep `build/symbols/` safe**: needed to de-obfuscate Crashlytics stack traces.

---

## Antes de subir a testers (TestFlight / Internal Testing)

- [ ] `android/key.properties` existe y apunta al keystore de release (no debug)
- [ ] `build.gradle.kts` carga `signingConfigs.release` correctamente
- [ ] `key.properties` y `*.jks` están en `.gitignore` (ya hecho)
- [ ] Firebase configurado: `google-services.json` en `android/app/` y `GoogleService-Info.plist` en `ios/Runner/`
- [ ] Crashlytics activo: `FlutterError.onError` y `PlatformDispatcher.onError` conectados (ver `main.dart`)
- [ ] `--dart-define=CLOCKLY_API_BASE_URL` apunta a staging, NO a localhost
- [ ] `flutter analyze` sin errores
- [ ] `flutter test` sin fallos
- [ ] App instalada en dispositivo físico Android (no solo emulador)
- [ ] App instalada en dispositivo físico iOS (no solo simulador)
- [ ] Probar flujo completo: login → fichaje entrada → fichaje salida → logout
- [ ] Probar kiosk mode en tablet real en landscape
- [ ] Probar sin conexión: app no crashea, muestra banner offline
- [ ] Probar cambio de negocio (si hay más de uno)

---

## Antes de publicar en App Store / Google Play

### Android — Play Store
- [ ] App Bundle generado con `--release --obfuscate`
- [ ] Firmado con keystore de producción (NO debug signing)
- [ ] `applicationId = "com.clockly.mobile"` confirmado
- [ ] `versionCode` incrementado en `pubspec.yaml` respecto a la versión anterior
- [ ] `versionName` actualizado (ej: `1.0.1`)
- [ ] Permisos en `AndroidManifest.xml` auditados (solo `INTERNET` actualmente)
- [ ] Merge manifest verificado: `./gradlew processReleaseManifest` y revisar `build/intermediates/merged_manifest/release/`
- [ ] Privacy Policy URL configurada via `--dart-define=CLOCKLY_PRIVACY_URL`
- [ ] Privacy Policy URL publicada y accesible
- [ ] Capturas de pantalla (teléfono y tablet) preparadas en Google Play Console
- [ ] Descripción corta (80 chars) y descripción larga redactadas
- [ ] Feature graphic 1024×500 preparado
- [ ] App probada en Android 8+ (minSdk actual) y Android 14+
- [ ] Data Safety form rellenado en Play Console (solo INTERNET, no location)

### iOS — App Store
- [ ] Provisioning profile de distribución configurado en Xcode
- [ ] Bundle ID `$(PRODUCT_BUNDLE_IDENTIFIER)` configurado en Xcode project settings
- [ ] `Info.plist` tiene `LSApplicationQueriesSchemes` para url_launcher (ya hecho)
- [ ] Sin `NSLocationWhenInUseUsageDescription` (GPS eliminado; si se reactiva, añadir)
- [ ] IPA generado con `flutter build ipa --release --obfuscate`
- [ ] Privacy Policy URL válida y accesible desde App Store Connect
- [ ] Capturas de pantalla para iPhone SE (4.7"), iPhone 15 Pro (6.1"), iPhone 15 Pro Max (6.7"), iPad Pro 12.9"
- [ ] App Store Connect: descripción, keywords, categoría rellenados
- [ ] App Review Information: credenciales de demo y notas al reviewer
- [ ] Testeado en TestFlight al menos 48h antes de submission
- [ ] App testeada en iPhone físico y iPad físico

---

## Antes de conectar a clientes reales (producción)

- [ ] Todos los puntos de los checklists anteriores completados
- [ ] Endpoint `POST /kiosk/validate-pin` implementado en backend y testeado
- [ ] Endpoint `POST /auth/refresh` implementado en backend (refresh token)
- [ ] Privacy Policy publicada y cubre GDPR (datos de empleados en Europa)
- [ ] Terms of Service publicados
- [ ] URL de producción (`CLOCKLY_API_BASE_URL`) apunta a servidor de producción, nunca a staging/dev
- [ ] Crashlytics recibiendo eventos reales (verificar en Firebase Console)
- [ ] Dashboard de errores revisado post-TestFlight: 0 crashes críticos
- [ ] Separación de entornos: clientes en prod, testers en staging
- [ ] Paginación implementada para clientes con datasets grandes (>50 empleados o >100 sesiones)
- [ ] Plan de soporte definido y accesible desde la app
- [ ] Comunicación a clientes: instrucciones de descarga y onboarding preparadas

---

## Kiosk — verificación específica

- [ ] `POST /kiosk/validate-pin` implementado en backend
- [ ] PIN de empleado se valida correctamente contra backend antes de clockIn/clockOut
- [ ] PIN incorrecto muestra error claro, no permite fichar
- [ ] Lockout de 30s tras 3 intentos fallidos (lado cliente, verificado)
- [ ] Timeout de inactividad de 3 min vuelve a pantalla principal
- [ ] Modo kiosk probado en tablet real en landscape
- [ ] Kiosk no accesible sin autenticación del negocio

---

## Configuración de Firebase (cuando se integre)

1. Crear proyecto en https://console.firebase.google.com
2. Añadir app Android (package: `com.clockly.mobile`) y app iOS (bundle ID real)
3. Descargar y colocar:
   - `google-services.json` → `android/app/` (en `.gitignore`)
   - `GoogleService-Info.plist` → `ios/Runner/` (en `.gitignore`)
4. Ejecutar: `dart pub global run flutterfire_cli:flutterfire configure`
5. Añadir a `pubspec.yaml`:
   ```yaml
   firebase_core: ^3.0.0
   firebase_crashlytics: ^4.0.0
   firebase_analytics: ^11.0.0
   ```
6. Añadir plugins en `android/app/build.gradle.kts`:
   ```kotlin
   id("com.google.gms.google-services")
   id("com.google.firebase.crashlytics")
   ```
7. Añadir plugins en `android/build.gradle.kts`:
   ```kotlin
   id("com.google.gms.google-services") version "4.4.2" apply false
   id("com.google.firebase.crashlytics") version "3.0.2" apply false
   ```
8. Activar en `lib/main.dart` el código comentado de Firebase/Crashlytics

---

## Versioning

Antes de cada release, actualizar en `pubspec.yaml`:
```yaml
version: 1.0.X+Y   # X = semver patch, Y = build number (siempre incremental)
```

Play Store usa el `versionCode` (Y). App Store usa `CFBundleVersion` (Y).
Nunca reutilizar un `versionCode` ya publicado en Play Store.
