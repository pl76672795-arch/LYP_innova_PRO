# Configuración Firebase - LYP INNOVA

Para activar la nube, la galería en Cloud Storage y el login, sigue estos pasos:

## 1. Crear proyecto Firebase

1. Entra a [console.firebase.google.com](https://console.firebase.google.com)
2. Crea un proyecto nuevo (o usa uno existente)
3. Añade una app **Android** con el package: `com.pylinnova.app`
4. Descarga `google-services.json` y colócalo en `android/app/`

## 2. Configurar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## 3. Generar configuración

En la raíz del proyecto (`alexander_app`):

```bash
flutterfire configure
```

Esto genera `lib/firebase_options.dart` con tus credenciales reales.

## 4. Habilitar servicios en Firebase Console

### Authentication
- **Authentication** → **Sign-in method** → **Email/Password** → Activar

### Firestore
- **Firestore Database** → Crear base de datos (modo producción)
- Reglas (ajusta `{uid}` a tu userId si quieres restringir):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/data/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### Storage
- **Storage** → Comenzar
- Reglas:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## 5. Plugin Google Services (Android)

Si `flutterfire configure` no lo añadió, en `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Añadir
}
```

Y en `android/build.gradle.kts` (en plugins):

```kotlin
id("com.google.gms.google-services") version "4.4.2" apply false
```

## Sin Firebase

La app **funciona 100% offline** sin configurar Firebase:
- Metrados, Caja Chica y Galería se guardan localmente
- En Login verás "Continuar sin cuenta (solo local)"
- Cuando configures Firebase, tendrás sync automático y login seguro
