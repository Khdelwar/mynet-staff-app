# MyNet Staff App: staff app for MyNet ISP ERP

## What this is
Flutter mobile app (Android + iPhone) for MyNet's own staff: collectors,
technicians, support, managers. Backend is the private `mynet-erp` repo,
consumed over `{ERP_BASE_URL}/api/staff/v1` (`docs/STAFF_APP_API.md` there).
Built the same way as the customer app (`mynet-app`).

## Roadmap
mynet-erp `docs/ROADMAP.md` → Phase 14. This app is STF-10.
`docs/STAFF_APP_API.md` numbers the staff API STF-01 … STF-10; the ERP side
of each section (API + Pest tests) goes in mynet-erp first.

## Stack
- Flutter 3.47.9 (pinned in `.github/workflows`), Dart 3.13
- Riverpod 3, dio (one `StaffApi`), flutter_secure_storage for the token,
  shared_preferences for language / app lock only
- Bangla (default) and English in `lib/l10n/*.arb`

## Rules for agents
- Small PRs from `main`, one concern each. Never force push.
- No hardcoded secrets or ERP hosts. Staff type the ERP address at login
  (saved after a successful sign-in, https only); `--dart-define=ERP_BASE_URL`
  only sets a default.
- Never log tokens, passwords, 2FA codes, client phone numbers or payments.
- The ERP is the source of truth for money, due, balance, approval and
  permissions. The app never computes them as authoritative and never shows
  a screen for work the ERP would refuse; the ERP checks again anyway.
- Owner rules R1–R9 (mynet-erp ROADMAP "Business rules") apply: e.g. cash a
  collector takes stays "pending approval" until the office approves it.
- Do not touch `android/app/key.properties` or any signing config.
- User-facing strings in `lib/l10n/*.arb`, never inline. Never show API
  paths or HTTP codes to staff outside `DEBUG_API` debug builds.
- App id `net.mynet.staff` (Android and iOS). Do not change it after release.

## Commands
```
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=ERP_BASE_URL=https://<erp-host>
```

## Before opening a PR
`flutter analyze` must be clean and `flutter test` must pass.
