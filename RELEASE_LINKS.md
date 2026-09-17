# RMoney release links

Use `download-links.html` as the public download page. It detects the device and redirects:

- Android: Play Store, or APK when `preferBetaLinks` is `true`
- iPhone: App Store, or TestFlight when `preferBetaLinks` is `true`
- Desktop/unknown device: shows all links

## Links to fill

```text
Android Play Store:
https://play.google.com/store/apps/details?id=com.batzorig.rmoney

Android APK:
https://example.com/downloads/rmoney.apk

iPhone App Store:
https://apps.apple.com/app/idYOUR_APP_ID

iPhone TestFlight:
https://testflight.apple.com/join/YOUR_TESTFLIGHT_CODE
```

## Current app ids

```text
Native Android applicationId:
com.example.rmoney

Flutter Android applicationId:
com.batzorig.rmoney

iOS bundle identifier:
com.batzorig.rmoney
```

The Flutter Android and iOS builds use `com.batzorig.rmoney`. The native Android prototype still uses `com.example.rmoney` and is not the Play Store release target. App Store links need the numeric Apple app id, and TestFlight links need the invite code from App Store Connect.
