# MyNet staff app

Flutter app (Android + iPhone) for MyNet ISP staff. All data comes from
[mynet-erp](https://github.com/Khdelwar/mynet-erp) over its staff API
(`{ERP_BASE_URL}/api/staff/v1`, see `docs/STAFF_APP_API.md` in mynet-erp).

- **App name:** MyNet Staff · **App id:** `net.mynet.staff` (Android and iOS)
- **Languages:** Bangla (default) and English
- **Sign-in:** the same email (or mobile) and password as the ERP website,
  plus the 2FA code when the user has 2FA on. The user's role needs
  "Staff app" (`staff_app.use`) on the ERP Roles page.

## Screens

The home screen shows only the screens the ERP lists for the login
(`/me` → `screens`); the ERP checks every call again.

| Screen | What it does | ERP endpoints |
| --- | --- | --- |
| Login | Email / mobile + password, then 2FA code if on | `POST /auth/login`, `POST /auth/two-factor` |
| Home | Name, staff code, roles, the work this login may do | `GET /me` |
| Account | Email, mobile, language, app lock, sign out | `POST /auth/logout` |
| Dashboard | The dashboard boxes this login may see | `GET /dashboard` |
| Duty | Duty on / off (location asked once at start and end) | `/duty`, `/duty/start`, `/duty/end` |
| Tickets | Mine / all, active / done, steps (note, outcome, location when finishing, "why so far"), notes with photos, call, map, ONU power, house GPS, new ticket, nearest technicians | `/tickets*`, `/clients/{id}/dbm`, `/clients/{id}/location`, `/tickets/{id}/suggestions`, `/assign`, `/offer` |
| Materials / Install | Parts used on a ticket, scanned items, a new line's ONU SN/MAC, POP, router | `/tickets/{id}/materials`, `/scan`, `/install` |
| Job offers | Take or decline a ticket offered to you | `/offers*` |
| Bill collection | Today, in hand, cash, bKash/Nagad TrxID, expense with receipt photo, day-end handover, receipt | `/collection/*` |
| Approvals | Handovers sent to you, others' expenses (never your own) | `/collection/approvals`, approve / reject |
| Sell products | Scan / type a code, price, cash / due / digital, client or new connection | `/sales*` |
| Clients | Search, details, live connection, edit phone / address / NID, cash, recharge, new ticket, quick add | `/clients*` |
| Due list | Biggest due first, call | `/due-list` |
| Support chat | Conversations with clients | `/chats*` |
| Wallet / Expiring | Reseller wallet, own clients running out, recharge (quote first) | `/reseller/*`, `/clients/{id}/recharge*` |
| HR | Attendance, ask / cancel leave and advance | `/hr/*` |

Every money or stock request carries a `request_key` that is kept while
retrying, so a payment, expense, sale or part is saved once.

Not in the app yet: background location while on duty (needs an Android
foreground service), push notifications (Firebase messaging), camera barcode
scanning (codes are typed or entered by a scanner keyboard), staff map, OLT
and fiber pages (use the website).

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
