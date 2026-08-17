# PhotoFix AI: Enhance & Restore

Production-oriented Flutter Android app for AI photo enhancement, restore, upscale, colorize, denoise, and sharpen.

**Package:** `com.appstudio.photofixai`

## Features

- Gallery / camera photo selection with validation
- AI tools: Enhance, Upscale (2X / 4X Pro), Restore, Colorize (Pro), Denoise, Sharpen
- Before/After comparison with drag divider + zoom/pan
- Save to gallery + native share
- Local processing history (10 items free / unlimited Pro)
- Daily free limit (3) with midnight reset
- Rewarded ads for +1 free use
- Banner + frequency-capped interstitial ads (hidden for Pro)
- Google Play Billing: monthly, yearly, lifetime
- Dark / light / system themes
- Onboarding, settings, help, legal placeholders

## Architecture

```
lib/
  core/           config, theme, router, services
  domain/         models
  presentation/   providers, screens, widgets
```

State management: **Provider**  
Networking: **Dio**  
Ads: **google_mobile_ads**  
IAP: **in_app_purchase**

## Quick start (Real OpenAI AI)

1. Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Ensure billing is enabled and your org can use **GPT Image** models
3. Run the app and open **Profile → Settings → OpenAI API Key** → paste → Save

```bash
cd photofix_ai
flutter pub get
flutter run
```

Or pass the key at build time (recommended for release):

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
```

Optional model override (default `gpt-image-1.5`):

```bash
--dart-define=OPENAI_IMAGE_MODEL=gpt-image-1
```

Every tool (Enhance, Upscale, Restore, Colorize, Denoise, Sharpen) calls OpenAI  
`POST https://api.openai.com/v1/images/edits` with a task-specific prompt, then saves the real result.

**Billing:** OpenAI charges your OpenAI account per image edit.  
**Security:** Do not commit keys. Prefer dart-define for release builds; Settings key is for device testing.

## Mock mode (UI only)

```bash
flutter run --dart-define=USE_MOCK_AI=true
```

Mock mode is **off by default** and blocked in production.

## Custom backend (optional)

If you prefer your own server instead of OpenAI from the app:

```bash
flutter run \
  --dart-define=USE_MOCK_AI=false \
  --dart-define=API_BASE_URL=https://your-backend.example.com
```

(OpenAI key in Settings takes priority when present.)

Expected backend endpoints:

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/process` | multipart: `image` + `operation` (+ optional `strength`, `upscale_factor`) |
| GET | `/v1/process/{jobId}` | async job status |

Response JSON shape:

```json
{
  "success": true,
  "job_id": "abc",
  "image_url": "https://...",
  "status": "completed",
  "message": "ok"
}
```

Statuses: `pending` | `processing` | `completed` | `failed`

For strongest production security, put the OpenAI key on **your backend** and point `API_BASE_URL` there.

## Enable production AI

```bash
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=USE_MOCK_AI=false \
  --dart-define=OPENAI_API_KEY=sk-... \
  --dart-define=ADMOB_APP_ID=ca-app-pub-xxxx~yyyy \
  --dart-define=ADMOB_BANNER_ID=ca-app-pub-xxxx/zzzz \
  --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-xxxx/zzzz \
  --dart-define=ADMOB_REWARDED_ID=ca-app-pub-xxxx/zzzz \
  --dart-define=PRIVACY_POLICY_URL=https://yourdomain.com/privacy \
  --dart-define=TERMS_URL=https://yourdomain.com/terms
```

Also set the AdMob App ID in `android/app/build.gradle.kts` `manifestPlaceholders["admobAppId"]` (AndroidManifest meta-data).

Production fails loudly if `USE_MOCK_AI=true` or `API_BASE_URL` is empty.

## Mock AI mode

```bash
flutter run --dart-define=USE_MOCK_AI=true
```

Use only for UI / flow testing. Do not ship with mock enabled.

## AdMob IDs

Centralized in `lib/core/config/app_config.dart` via dart-defines:

- `ADMOB_APP_ID`
- `ADMOB_BANNER_ID`
- `ADMOB_INTERSTITIAL_ID`
- `ADMOB_REWARDED_ID`

Defaults are **Google test IDs**. Replace before Play Store release.

Android App ID also lives in:

`android/app/build.gradle.kts` → `manifestPlaceholders["admobAppId"]`

## Google Play product IDs

Defaults:

- `photofix_pro_monthly`
- `photofix_pro_yearly`
- `photofix_lifetime`

Override:

```bash
--dart-define=PRODUCT_MONTHLY=your_monthly_id
--dart-define=PRODUCT_YEARLY=your_yearly_id
--dart-define=PRODUCT_LIFETIME=your_lifetime_id
```

Create matching products in Play Console → Monetize → Products.

### Testing purchases

1. Upload an internal testing AAB to Play Console.
2. Add license testers.
3. Install from the internal test track (not sideload-only).
4. Use a tester Google account on device.
5. Open Premium → purchase → verify entitlement removes ads/limits.
6. Profile → Restore Purchases to verify restore flow.

Purchases are **not** faked on button tap — the app listens to `purchaseStream` and only unlocks after `purchased` / `restored`.

## Privacy Policy & Terms URLs

```bash
--dart-define=PRIVACY_POLICY_URL=https://...
--dart-define=TERMS_URL=https://...
```

If unset, in-app legal screens show a configuration placeholder (no invented legal text).

## Build release AAB

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=USE_MOCK_AI=false \
  --dart-define=API_BASE_URL=https://api.yourdomain.com
```

Configure a real signing keystore before production (replace debug signing in `build.gradle.kts`).

## Launcher icon

```bash
dart run flutter_launcher_icons
```

Source: `assets/icon/app_icon.png`

## Tests

```bash
flutter test
```

Covers usage limits / day reset, entitlements, history limits, API response parsing, settings persistence.

## Notes

- Camera permission is requested only when taking a photo.
- Gallery uses the system photo picker via `image_picker` (no broad storage permission by default).
- Pro users: no ads, no daily limit, 4X upscale, unlimited history, Colorize unlocked.
