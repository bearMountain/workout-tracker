# TestFlight CI

GitHub Actions on `macos-latest` archives Workout Tracker and can upload the IPA to TestFlight. This repo is a committed Xcode project (`WorkoutTracker.xcodeproj`); there is no XcodeGen `project.yml`.

| | |
| --- | --- |
| Repo | [bearMountain/workout-tracker](https://github.com/bearMountain/workout-tracker) |
| Default branch | `master` |
| Scheme / project | `WorkoutTracker` / `WorkoutTracker.xcodeproj` |
| Bundle ID | `com.jiggidy.workout-tracker` |
| Team | `QF6B888F7S` (Jeffrey Camealy), Automatic signing |

Pushes that only touch `api/` (or other non-iOS paths) do not run this workflow. iOS-related paths that do trigger it: `WorkoutTracker/`, `WorkoutTracker.xcodeproj/`, `ci/`, and `.github/workflows/testflight.yml`.

**Push auto-upload stays off until Jeff sets the repo variable `TESTFLIGHT_UPLOAD_ENABLED=true` after a successful `workflow_dispatch` upload.** Do not set that variable from code or this PR. `workflow_dispatch` mode `upload` is the first manual TestFlight upload and runs even when that variable is unset.

## Modes

`workflow_dispatch` accepts:

| Mode | What it does | Secrets required |
| --- | --- | --- |
| `dry-run` | Unsigned `xcodebuild` compile (`CODE_SIGNING_ALLOWED=NO`) | No |
| `archive-only` | Unsigned archive, then cloud-sign on export; uploads `WorkoutTracker.ipa` as a workflow artifact. Does **not** upload to TestFlight | Yes |
| `upload` | Same as archive-only, then `altool --upload-app`. This **is** the first manual upload and is **not** gated by `TESTFLIGHT_UPLOAD_ENABLED` | Yes |

Pushes to `master` (when iOS paths change) resolve as:

| Secrets | `TESTFLIGHT_UPLOAD_ENABLED` | Mode |
| --- | --- | --- |
| Missing | any | `dry-run` |
| Present | not `true` | `archive-only` (no TestFlight upload) |
| Present | `true` | `upload` |

Build numbers are a UTC timestamp (`YYYYMMDDHHMMSS`) written to `CURRENT_PROJECT_VERSION` so every CI archive is unique.

Archive is unsigned. Cloud-signing happens on export via the App Store Connect API key and Xcode automatic signing (`-allowProvisioningUpdates`). There is no Fastlane, no `.p12`, and no provisioning-profile secret.

A new push does not cancel an in-flight TestFlight job (`cancel-in-progress: false`).

## One-time Jeff setup

1. In [App Store Connect](https://appstoreconnect.apple.com) → Users and Access → Integrations → App Store Connect API, create a key with **App Manager** (or Admin) access. Download the `.p8` once. Confirm Workout Tracker (`com.jiggidy.workout-tracker`) exists as an app record.
2. In this GitHub repo → Settings → Secrets and variables → Actions, add three **repository secrets** (never commit these):

   | Secret | Value |
   | --- | --- |
   | `APP_STORE_CONNECT_API_KEY_ID` | Key ID (e.g. from the App Store Connect key row) |
   | `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from the App Store Connect API page |
   | `APP_STORE_CONNECT_API_KEY_P8` | Full PEM text of the downloaded `.p8` |

3. Run the workflow manually (`Actions` → `TestFlight` → `Run workflow`):
   - `dry-run` — unsigned compile, no secrets needed
   - `archive-only` — unsigned archive + cloud-signed IPA (needs secrets; does not upload)
   - `upload` — same as archive-only, then upload to TestFlight. **This is the first manual upload** and works while `TESTFLIGHT_UPLOAD_ENABLED` is still unset.
4. After that `upload` run succeeds, add the **repository variable** (not a secret, not in git):

   `TESTFLIGHT_UPLOAD_ENABLED=true`

   Until that variable is set, pushes to `master` stay at `archive-only` (or `dry-run` if secrets are missing). They will not auto-upload.

`.p8` files are gitignored. Do not put App Store Connect keys in the repo.
