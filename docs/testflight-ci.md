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

**Auto-upload stays off until Jeff sets the repo variable `TESTFLIGHT_UPLOAD_ENABLED=true` after a successful manual TestFlight upload.** Do not set that variable from code or this PR.

## Modes

`workflow_dispatch` accepts:

| Mode | What it does | Secrets required |
| --- | --- | --- |
| `dry-run` | Unsigned `xcodebuild` compile (`CODE_SIGNING_ALLOWED=NO`) | No |
| `archive-only` | Signed archive + IPA export; uploads `WorkoutTracker.ipa` as a workflow artifact | Yes |
| `upload` | Same as archive-only, then `altool --upload-app` **only if** `TESTFLIGHT_UPLOAD_ENABLED=true` | Yes |

Pushes to `master` (when iOS paths change) run `dry-run` until that variable is `true`. After Jeff enables it, those pushes run `upload`.

Build numbers are a UTC timestamp (`YYYYMMDDHHMMSS`) written to `CURRENT_PROJECT_VERSION` so every CI archive is unique.

Signing uses the App Store Connect API key plus Xcode automatic signing (`-allowProvisioningUpdates`). There is no Fastlane, no `.p12`, and no provisioning-profile secret.

## One-time Jeff setup

1. In [App Store Connect](https://appstoreconnect.apple.com) → Users and Access → Integrations → App Store Connect API, create a key with **App Manager** (or Admin) access. Download the `.p8` once.
2. Confirm Workout Tracker (`com.jiggidy.workout-tracker`) exists in App Store Connect and that **the first build has been uploaded manually** (Xcode Organizer or Transporter). Apple will not accept API uploads until that first manual build exists.
3. In this GitHub repo → Settings → Secrets and variables → Actions, add three **repository secrets** (never commit these):

   | Secret | Value |
   | --- | --- |
   | `APP_STORE_CONNECT_API_KEY_ID` | Key ID (e.g. from the App Store Connect key row) |
   | `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from the App Store Connect API page |
   | `APP_STORE_CONNECT_API_KEY_P8` | Full PEM text of the downloaded `.p8` |

4. Run the workflow manually (`Actions` → `TestFlight` → `Run workflow`) with mode `dry-run` to confirm unsigned compile. Then `archive-only` to confirm signing and IPA export.
5. After a successful **manual** TestFlight upload, add the **repository variable** (not a secret, not in git):

   `TESTFLIGHT_UPLOAD_ENABLED=true`

   Until that variable is set, `upload` mode archives (when secrets exist) but skips the App Store Connect upload.

`.p8` files are gitignored. Do not put App Store Connect keys in the repo.
