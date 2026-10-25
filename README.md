# Aether iOS

Native iPhone client for the Aether backend — SwiftUI + Liquid Glass, iOS 26.

The backend is a JSON API at a user-configurable base URL
(default `http://10.10.10.11:8787`), all paths under `/api/`.
If an API key is configured in Settings, it is sent as an
`Authorization: Bearer` header on every request. No secrets,
signing config, or API keys live in this repo.

## Endpoint settings

- Open the **Settings** tab in the app.
- Set **Base URL** (e.g. `http://10.10.10.11:8787`).
- Optionally set the **API key**.
- Tap **Test** — it hits `/api/health` and shows OK or FAIL.
- Values persist in `UserDefaults` on-device only.

## Local build

Requirements: Xcode 26, iOS 26 SDK, `xcodegen`.

```sh
brew install xcodegen   # if missing
xcodegen generate
open Aether.xcodeproj
```

Run on a simulator or device from Xcode. CI (`.github/workflows/ipa.yml`)
does the same headless and produces an **unsigned** IPA artifact.

## Signing the unsigned IPA yourself

CI builds with `CODE_SIGNING_ALLOWED=NO` and an empty
`CODE_SIGN_IDENTITY`, so the artifact can't install as-is. To sign it:

1. Download `Aether-unsigned.ipa` from the workflow run, unzip it.
2. In Xcode, open the generated project and select the **Aether** target.
3. Under **Signing & Capabilities**, pick your own Team and set your own
   bundle identifier (e.g. change `dev.aether.Aether` to something unique).
4. Build & run on your device, or Product → Archive → Distribute with
   your own signing.

Alternatively re-sign the `.app` with your own identity:

```sh
codesign -f -s "Apple Development: Your Name (TEAMID)" Payload/Aether.app
```

## v1 scope

- **Chat**: streaming SSE replies, model picker (`GET /api/models`),
  search + brain toggles, source links, tap-to-retry on errors.
- **Research**: run list (`GET /api/research`), new-run composer,
  detail with status/sources/claims, 4s polling while running.
- **Brain**: note search (`GET /api/brain/notes`), reader, inbox with
  dismiss, capture sheet with tag suggestions (`GET /api/brain/tags`).
- **Library**: notes filtered to `Research*` / `Outputs*` paths + reader.
- **Status**: pretty-printed `/api/health` and `/api/status` in glass cards.
- **Settings**: base URL + API key + Test button.
