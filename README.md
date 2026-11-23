# MyNet staff app

Flutter app (Android + iPhone) for MyNet ISP staff. All data comes from
[mynet-erp](https://github.com/Khdelwar/mynet-erp) over its staff API
(`{ERP_BASE_URL}/api/staff/v1`, see `docs/STAFF_APP_API.md` in mynet-erp).

- **App name:** MyNet Staff · **App id:** `net.mynet.staff` (Android and iOS)
- **Languages:** Bangla (default) and English
- **Sign-in:** the same email (or mobile) and password as the ERP website,
  plus the 2FA code when the user has 2FA on. The user's role needs
  "Staff app" (`staff_app.use`) on the ERP Roles page.

## Screens (STF-01)

| Screen | What it does | ERP endpoints |
| --- | --- | --- |
| Login | Email / mobile + password, then 2FA code if on | `POST /auth/login`, `POST /auth/two-factor` |
| Home | Name, staff code, roles, the work this login may do | `GET /me` |
| Account | Email, mobile, language, app lock, sign out | `POST /auth/logout` |
| Push | This phone's notification token; tapping opens the ticket or the offer | `POST /push/register`, `POST /push/unregister` |

Put the staff app's `google-services.json` (Android) and `GoogleService-Info.plist` (iPhone) from the customer app's Firebase project next to the other platform files. They stay out of git. Without them the app still runs and push stays off.

Collection, tickets, clients and HR come next (mynet-erp ROADMAP Phase 14).

## Security

- Token in the phone's Keystore / Keychain; never in plain storage or logs.
- The ERP signs the phone out at once when the user is turned inactive, loses
  "Staff app", or the password changes (lost phone: change the password).
- Optional app lock (fingerprint / face / screen lock) after a minute away.
- https only; Android backup is off.

## Run

```bash
flutter pub get
```

```bash
flutter run --dart-define=ERP_BASE_URL=https://your-erp-host
```

Without `ERP_BASE_URL` (https) the app shows "not set up" and sign-in is off.
`DEBUG_API=true` shows API path / HTTP code in errors (debug builds only).

## Check

```bash
flutter analyze
```

```bash
flutter test
```

## Build

Android: Actions → **Release APK** → Run workflow (secrets listed in
`.github/workflows/release.yml`). Locally:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=ERP_BASE_URL=https://your-erp-host
```

Release signing needs `android/app/key.properties` (never committed); there is
no debug-key fallback.

iPhone: needs a Mac with Xcode and an Apple Developer account. Open
`ios/Runner.xcworkspace`, set the team under Signing & Capabilities (bundle id
`net.mynet.staff`), then:

```bash
flutter build ipa --dart-define=ERP_BASE_URL=https://your-erp-host
```

Upload the `.ipa` to TestFlight (App Store Connect) and invite staff there.
CI builds iOS without signing on every PR to prove it compiles.
