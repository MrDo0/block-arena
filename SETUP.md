# Block Arena — Flutter Setup Guide

## 1. Flutter суулгах
```bash
# Flutter SDK татах: https://flutter.dev/docs/get-started/install
flutter doctor  # бүх зүйл бэлэн эсэхийг шалгах
```

## 2. Тоглоомыг ажиллуулах
```bash
cd block_arena
flutter pub get
flutter run
```

## 3. AdMob тохируулах

### pubspec.yaml дээр нэмсэн:
- google_mobile_ads: ^5.1.0

### Android: android/app/src/main/AndroidManifest.xml дотор нэмэх
```xml
<manifest>
  <application>
    <!-- Өөрийн AdMob App ID -->
    <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
  </application>
</manifest>
```

### iOS: ios/Runner/Info.plist дотор нэмэх
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

### main.dart дотор AdMob идэвхжүүлэх:
1. `import 'package:google_mobile_ads/google_mobile_ads.dart';` — comment-г арилгах
2. `await MobileAds.instance.initialize();` — comment-г арилгах
3. `_loadBannerAd()` функцийн comment-г арилгах
4. Banner widget-ийн comment-г арилгах
5. Ad Unit ID-уудаа оруулах

## 4. Ad Unit ID авах
1. admob.google.com руу орох
2. App нэмэх → Android сонгох
3. Ad unit үүсгэх:
   - Banner ad unit
   - Rewarded ad unit

## 5. Play Store гаргах
```bash
# Release build хийх
flutter build apk --release
# эсвэл
flutter build appbundle --release

# AAB файл: build/app/outputs/bundle/release/app-release.aab
```

## Тест Ad Unit ID (хөгжүүлэлтийн үед ашиглах)
- Banner: ca-app-pub-3940256099942544/6300978111
- Rewarded: ca-app-pub-3940256099942544/5224354917

## Файлын бүтэц
```
block_arena/
  lib/
    main.dart        ← бүх тоглоомын код
  pubspec.yaml       ← dependencies
  android/           ← Android тохиргоо
  ios/               ← iOS тохиргоо
```
