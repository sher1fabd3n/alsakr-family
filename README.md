# الصقر - طالب وولي أمر

مشروع Flutter مستقل بالكامل (بدون حزمة مشتركة).

## تشغيل (سيرفر محلي)
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5286
```

## بناء APK للسيرفر الفعلي
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://alsakrschools.com
```

## بناء APK للسيرفر المحلي
```bash
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.5:5286
```

Package ID: `com.alsakr.school.family`