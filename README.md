# MyNet staff app

Flutter app (Android + iPhone) for MyNet ISP staff. All data comes from
[mynet-erp](https://github.com/Khdelwar/mynet-erp) over its staff API
(`{ERP_BASE_URL}/api/staff/v1`, see `docs/STAFF_APP_API.md` in mynet-erp).

- **App name:** MyNet Staff · **App id:** `net.mynet.staff` (Android and iOS)
- **Languages:** Bangla (default) and English
- **Sign-in:** ERP email or mobile, plus the 2FA code when the user has
  2FA on. The user's role needs "Staff app" (`staff_app.use`).

## Screens

Phase 14. This app is STF-10. The staff API sections are STF-01 … STF-10
in mynet-erp `docs/STAFF_APP_API.md`.

| Screen | What it does | ERP endpoints |
| --- | --- | --- |
| Login | Email or mobile (`identifier`), password, install `device_id`, phone model, app version. 2FA sends `challenge_token` and `challenge` | `POST /auth/login`, `POST /auth/two-factor` |
| Home | Company name in the app bar. Roles, permissions, screens and staff come from `user` | `GET /me` |
| Tickets | Own tickets (or everyone's, when the ERP allows it), status, notes with photos, house GPS, live dBm | `GET /tickets`, `POST /tickets/{id}/status`, `POST /tickets/{id}/comments`, `POST /clients/{id}/location`, `POST /clients/{id}/dbm` |
| Account | Email, mobile, language, app lock, My phones, sign out | `GET /devices`, `DELETE /devices/{id}`, `POST /auth/logout` |
| Duty | Start and end duty. While it is on, the phone sends location at the ERP's interval and shows "MyNet: location on" | `GET /duty`, `POST /duty/start`, `POST /duty/end`, `POST /locations` |
| Job offers | Accept or reject a ticket offered to this technician (`tickets.update`) | `GET /offers`, `POST /offers/{id}/accept`, `POST /offers/{id}/reject` |
| Assign | Nearest technicians, assign, or start an offer (`tickets.assign`) | `GET /tickets/{id}/suggestions`, `POST /tickets/{id}/assign`, `POST /tickets/{id}/offer` |
| Push | After sign-in, and when Firebase refreshes the token, this phone is registered. Sign-out unregisters, then logs out. A tap opens the ticket (`ticket_assigned`, `ticket_helper`, `ticket_unassigned`), the offer (`ticket_offer`), or the chat (`support_chat`) | `POST /push/register`, `POST /push/unregister` |

`android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` are in git for app id `net.mynet.staff` (Firebase project `mynet-7e283`). The Android file also lists the customer app package. Push stays off if Firebase refuses the token.

Home draws only the screens `GET /me` lists for this login.

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
