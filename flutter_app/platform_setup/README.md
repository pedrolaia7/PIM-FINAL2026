# Configuração das plataformas (rodar uma vez)

O código Dart está completo, mas as pastas `android/` e `ios/` são geradas pelo Flutter.

```bash
cd flutter_app
flutter create . --org br.com.ticketfut --project-name ticketfut
rm -f test/widget_test.dart      # o gerador cria um teste de exemplo que não serve aqui
flutter pub get
```

Depois aplique os ajustes abaixo.

## Android

**`android/app/src/main/AndroidManifest.xml`** (dentro de `<manifest>`, antes de `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```
Para falar com o backend em `http://` durante o desenvolvimento, adicione em `<application ...>`:
`android:usesCleartextTraffic="true"` (**remova em produção** e use HTTPS).

**`android/app/src/main/kotlin/.../MainActivity.kt`** — o `local_auth` exige `FlutterFragmentActivity`:
```kotlin
package br.com.ticketfut.ticketfut

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

**`android/app/build.gradle(.kts)`**: `minSdk = 23` (exigido por `flutter_secure_storage` e `camera`).

## iOS

**`ios/Runner/Info.plist`** (dentro do `<dict>` principal):
```xml
<key>NSCameraUsageDescription</key>
<string>Usamos a câmera frontal para o seu cadastro facial e para confirmar compras.</string>
<key>NSFaceIDUsageDescription</key>
<string>Usamos o Face ID para confirmar suas compras com segurança.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Usamos sua localização para mostrar a distância até o estádio.</string>
<key>LSApplicationQueriesSchemes</key>
<array><string>https</string></array>
```
`ios/Podfile`: `platform :ios, '13.0'`.

## Apontar o app para o backend
```bash
# Emulador Android (padrão do projeto): http://10.0.2.2:8080
flutter run
# Simulador iOS
flutter run --dart-define=API_URL=http://localhost:8080
# Aparelho físico (IP da sua máquina na rede)
flutter run --dart-define=API_URL=http://192.168.0.10:8080
```
