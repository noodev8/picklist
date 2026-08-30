# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is a two-part monorepo (no root-level build tooling):

- `picklist_flutter/` — Flutter mobile app used by warehouse pickers.
- `picklist_server/` — Node.js / Express REST API backed by PostgreSQL.

The two communicate over three JSON endpoints. The app's server URL is **hardcoded** in `picklist_flutter/lib/config/app_config.dart` (`apiBaseUrl`); switching between prod and a local/test server means editing that constant (older URLs are kept commented out there).

## Commands

### Server (`picklist_server/`)
- `npm install` — install dependencies.
- `npm start` (alias `npm run dev`) — run the API (`node server.js`). `PORT` comes from the environment; the server will not pick a default.
- No test suite (`npm test` is a stub).
- Requires a `.env` file (untracked) with at minimum: `DATABASE_URL` (PostgreSQL connection string, SSL disabled in `db.js`), `PORT`, and `JWT_SECRET`. Without `JWT_SECRET`, `middleware/auth.js` falls back to an insecure default — always set it.

### Flutter app (`picklist_flutter/`)
- `flutter pub get` — install dependencies.
- `flutter run` — run on a connected device/emulator.
- `flutter analyze` — lint (rules in `analysis_options.yaml`, `flutter_lints`).
- `flutter test` — run widget/unit tests. Single test: `flutter test test/<file>_test.dart` or `flutter test --plain-name "<test name>"`. (Note: the `test/` directory may be sparse/absent.)
- `flutter build apk` / `flutter build ios` — release builds. App icons are generated via `flutter pub run flutter_launcher_icons` (config in `pubspec.yaml`).

## API contract conventions

Every endpoint returns HTTP 200 (or sometimes 401/403/500) **and** a JSON body with a `return_code` string field. Clients branch on `return_code`, not on HTTP status alone. Known codes: `SUCCESS`, `MISSING_FIELDS`, `INVALID_PIN`, `UNAUTHORIZED` (no/missing token), `FORBIDDEN` (invalid/expired token), `DATABASE_ERROR`, `SERVER_ERROR`. When adding endpoints, follow this envelope and the documentation-comment header style at the top of each file in `picklist_server/routes/`.

Endpoints (`server.js` mounts one router per file in `routes/`):
- `POST /login_pin` — PIN → JWT. Validates a 4-digit PIN against the `pickpin` table, issues a JWT valid **90 days** (`issuer: picklist-app`).
- `POST /get_picks` — protected by `authenticateToken`. Returns picks from `localstock` LEFT JOIN `skusummary`, ordered by location/pickorder/code. Optional `location_filter` body field does a SQL `ILIKE %...%` on `location`. Optional `pick_type` selects the job (see **Two picking jobs** below); the response echoes it back.
- `POST /set_picked` — toggles customer picked status (`qty` 1↔0).
- `POST /set_amazon_picked` — protected; picks Amazon stock by *moving* it (see below).

### Two picking jobs

A picker does one of two disjoint jobs, chosen in the app's dashboard mode selector:

| | `pick_type: "customer"` (default) | `pick_type: "amazon"` |
|---|---|---|
| `get_picks` filter | `ordernum != '#FREE'` | `allocated = 'amz' AND location != 'C3-Amazon'` |
| Picked via | `POST /set_picked`, `qty` 1→0 | `POST /set_amazon_picked`, `location` → `C3-Amazon` |
| Unpick | `qty` 0→1 | needs `original_location` in the body — the DB does not remember where the item came from |

Both exclude soft-deleted rows. The lists never overlap: Amazon stock always has `ordernum = '#FREE'`, which the customer query excludes. Amazon picking never changes `allocated`; it stamps `assigned` with the picker's PIN from the JWT and writes `updated` as `TO_CHAR(NOW(), 'YYYYMMDD HH24:MI:SS')` to match every existing value in that column. (Note `set_picked` still writes `NOW()::text` there, which does *not* match — pre-existing behaviour, left alone.)

`C3-Amazon` is defined in `picklist_server/constants.js` (`AMAZON_LOCATION`) and `AppConfig.amazonLocation`; these must stay in sync.

Auth: `middleware/auth.js` reads `Bearer <token>` from the `Authorization` header. All protected routes go through `authenticateToken`, which attaches `req.user`.

## Flutter architecture

**State management:** `provider`. Two app-wide `ChangeNotifier`s registered in `main.dart`: `AuthProvider` (login/session) and `PicklistProvider` (pick data).

**Navigation flow:** `SplashScreen` → on launch calls `AuthProvider.tryAutoAuthenticate()` → `DashboardScreen` if a valid stored token exists, else `LoginScreen`. There is no router package; navigation is imperative `Navigator.push`.

**Auth/session:** `features/auth/data/auth_service.dart` persists the JWT, login flag, and last-login timestamp in `SharedPreferences`. Tokens are treated as valid for 90 days client-side (matching the server's expiry); expiry is checked locally from the stored `last_login` time, and `getAuthHeaders()` injects `Authorization: Bearer`.

**Centralized auth-error handling:** API calls should flow through `core/services/api_service_wrapper.dart` (`ApiServiceWrapper`). It detects `UNAUTHORIZED`/`FORBIDDEN` responses, throws `AuthenticationException` (defined in `core/utils/auth_error_handler.dart`), and uses the global `navigatorKey` to redirect to login from anywhere. Providers rethrow `AuthenticationException` so the UI layer can react.

**Data layer:** thin static API classes in `lib/api/` (`get_picks_api.dart`, `set_picked_api.dart`, `login_pin_api.dart`) wrap `http` calls and map JSON to models in `lib/models/`. `PicklistProvider` caches pick lists per location in memory and derives all dashboard stats (completion rate, remaining counts, location sorting) from that cache — there is no separate stats endpoint.

**Pick modes:** `PickMode` (`lib/models/pick_mode.dart`) selects the job. `PicklistProvider` keys its item cache *and* its location counts per mode (`_pickItemsByMode`, `_locationsByMode`), exposing the active one through the private `_pickItems`/`_locations` getters, so the rest of the provider is mode-agnostic. `setMode()` drops the outgoing mode's cache and reloads. Amazon items keep showing their original `location` after being picked, which is what makes undo possible — but only until a refresh drops them from the server's list.

**Location model:** the five warehouse locations (`c3f`, `c3b`, `c3c`, `c3s`, `c1`) are defined in two places that must stay in sync: `AppConfig.locationFilters`/`locationNames` (UI id → server filter string) and `PicklistProvider._initializeLocations()`. The server has no location concept beyond the `location` text column, so filtering is substring matching on strings like `C3-Front-Rack-01`.

### Important: legacy/dead code

The app was redesigned to a feature-first structure (see `picklist_flutter/REDESIGN_SUMMARY.md`). The **active** UI lives under `lib/features/**` and `lib/core/**`. The following are leftover from the pre-redesign version and are **not** referenced by `main.dart` or the active screens — do not edit them expecting changes to take effect, and prefer deleting over extending them:

- `lib/screens/` (`login_screen.dart`, `location_list_screen.dart`, `pick_list_screen.dart`)
- `lib/test_auth_screen.dart`

Note `lib/theme/app_theme.dart` (old path) **is** still used — `main.dart` imports `AppTheme` from there, while newer widgets use `lib/core/theme/`. Both theme systems coexist; check which one a screen uses before changing colors/typography.
