# RMoney Google Play release

## App identity

- App name: `RMoney`
- Package name: `com.batzorig.rmoney`
- Version: `1.0.0` (`versionCode` 1)
- Category: Finance
- Target API: 36 (Android 16)
- Contact email: `batzorig.g@qpay.mn`
- Privacy policy file: `privacy-policy.html`

The package name is permanent after the first Play Console upload. Confirm that `com.batzorig.rmoney` is the intended ID before creating the app in Play Console.

## Store listing copy (Mongolian)

### Short description

`Орлого, зарлага, хадгаламж, зээлээ нэг дороос ухаалгаар хяна.`

### Full description

`RMoney бол хувийн санхүүгээ энгийн, ойлгомжтой байдлаар удирдах Монгол апп юм.`

`• Орлого, зарлагаа хурдан бүртгэнэ`

`• Сарын төсөв, өдөр тутмын боломжит зарцуулалтаа харна`

`• Хадгаламжийн зорилгоо төлөвлөж, явцаа хянана`

`• Өглөг, авлага болон зээлийн үлдэгдлээ нэг дороос харна`

`• Тайлангаа графикаар шинжилж, PDF хэлбэрээр гаргана`

`• Төхөөрөмжийн түгжээгээр санхүүгийн мэдээллээ хамгаална`

`Таны оруулсан санхүүгийн бүртгэл RMoney-ийн серверт илгээгдэхгүй бөгөөд төхөөрөмж дээр хадгалагдана. RMoney нь санхүүгийн байгууллага биш, зээл олгохгүй, төлбөр дамжуулахгүй. Аппын тооцоолол болон зөвлөмж нь мэдээллийн зориулалттай.`

## Assets to upload

- App icon: `store-assets/app-icon.png` (512×512 PNG)
- Phone screenshots (real app with local demo data):
  - `store-assets/screenshot-dashboard.png`
  - `store-assets/screenshot-transactions.png`
  - `store-assets/screenshot-reports.png`
- Feature graphic: `store-assets/feature-graphic.png` (1024×500 PNG)

Do not use generated UI screenshots. Capture the real app on the Android emulator or a device.

## Play Console declarations

- App or game: App
- Free or paid: Free
- Contains ads: Yes (Google interstitial ads)
- Target audience: 18 and over
- App access: No account is required. The app may request the device screen lock; devices without a configured lock can still open it.
- Financial features: declare `Financial advice` if Play Console treats the calculated score/advice as advice. The app does not lend money, facilitate loans, transfer funds, connect to banks, or trade assets.
- Content rating: complete the questionnaire accurately; the app does not contain user-generated or violent/sexual content.
- News, health, government, VPN, COVID-19: No

### Data safety draft

The app's own finance records stay on-device and are not collected by the developer. Google Mobile Ads automatically collects or shares data for advertising, analytics, and fraud prevention. Review the current Google Mobile Ads disclosure when submitting, then declare at least:

- Approximate location (derived from IP address)
- App interactions
- Diagnostics
- Device or other identifiers
- Data is encrypted in transit
- Users can request deletion of the advertising ID through Android settings; local finance data is deleted by clearing app data or uninstalling

Play Console answers remain the developer's responsibility and must match the SDK version and AdMob configuration used for the submitted build.

## Upload sequence

1. Back up `flutter_rmoney/android/app/upload-keystore.jks` and `flutter_rmoney/android/key.properties` in a secure password manager or encrypted drive. They are intentionally ignored by Git.
2. Build with `cd flutter_rmoney && flutter build appbundle --release`.
3. In Play Console, create the app with package `com.batzorig.rmoney` and enable Play App Signing.
4. Complete the store listing, app content declarations, privacy-policy URL, pricing, and country availability.
5. Upload `flutter_rmoney/build/app/outputs/bundle/release/app-release.aab` to Internal testing first.
6. Run the pre-launch report and test notifications, device unlock, PDF export, ads/consent, and all six navigation tabs.
7. If the developer account is a personal account created after 2023-11-13, run a closed test with at least 12 continuously opted-in testers for 14 days, then apply for production access.
8. Promote the tested release to Production and submit it for review.

For every update, increase the build number in `pubspec.yaml` (for example `1.0.1+2`) before rebuilding.
