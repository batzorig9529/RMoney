# RMoney Flutter

Flutter version of the RMoney finance tracker.

## Release links

Public download links and the device redirect page are prepared in:

- `../RELEASE_LINKS.md`
- `../download-links.html`

## Run

```bash
flutter pub get
flutter run
```

If `android/` is missing, generate the Flutter host project first:

```bash
flutter create . --platforms=android
```

Then add this permission to `android/app/src/main/AndroidManifest.xml` above the `<application>` tag:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

The current machine used to generate this source did not have the Flutter SDK installed, so local Flutter build verification was not available here.
