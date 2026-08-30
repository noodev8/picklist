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
- `POST /get_picks` — protected by `authenticateToken`. Returns picks from `localstock` LEFT JOIN `skusummary`, ordered by location/pickorder/code. Optional `location_filter` body field does a SQL `ILIKE %...%` on `location` (the Flutter app no longer sends it - it fetches the whole run and filters in memory). Optional `pick_type` selects the job (see **Two picking jobs** below); the response echoes it back.
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

`C3-Amazon` is defined in `picklist_server/constants.js` (`AMAZON_LOCATION`). The app does not name it: an Amazon unpick sends back the item's own `location`, which is the bay it was found in.

Auth: `middleware/auth.js` reads `Bearer <token>` from the `Authorization` header. All protected routes go through `authenticateToken`, which attaches `req.user`.

## Flutter architecture

**State management:** `provider`. Two app-wide `ChangeNotifier`s registered in `main.dart`: `AuthProvider` (login/session) and `PicklistProvider` (pick data).

**Navigation flow:** `SplashScreen` (auto-auth check, no artificial delay) -> `HomeScreen` if a valid stored token exists, else `LoginScreen`. `HomeScreen` -> `PicklistScreen` for one area or for the whole unit. There is no router package; navigation is imperative `Navigator.push`.

**Auth/session:** `features/auth/data/auth_service.dart` persists the JWT, login flag, and last-login timestamp in `SharedPreferences`. Tokens are treated as valid for 90 days client-side (matching the server's expiry); expiry is checked locally from the stored `last_login` time, and `getAuthHeaders()` injects `Authorization: Bearer`. `LoginScreen` uses an in-app keypad (`widgets/pin_pad.dart`), not the OS keyboard.

**Centralized auth-error handling:** `core/services/api_service_wrapper.dart` holds the global `navigatorKey`; `core/utils/auth_error_handler.dart` defines `AuthenticationException` and redirects to login from anywhere. API classes throw it on `UNAUTHORIZED`/`FORBIDDEN`, `PicklistProvider` rethrows it, and screens call `AuthErrorHandler.handleWithNotification`.

**Data layer:** thin static API classes in `lib/api/` wrap `http` calls and map JSON to `lib/models/`. `GetPicksApi.getAllPicks` is the only read the app makes.

### One fetch, everything derived

`PicklistProvider` fetches the **whole run in a single `get_picks` call** (no `location_filter`) and derives everything else in memory: area tallies, per-area lists, bay grouping, progress. Do not reintroduce per-location fetches - the previous version made one call for counts plus one per configured area, which was five round trips per screen and let areas disagree with each other mid-load.

Consequences to preserve:
- **Areas are derived from the data, not configured.** `PickArea.of(location)` strips a trailing bay number (`C3-Front-02` -> `C3-Front`, `C1-05` -> `C1`). Retired areas disappear on their own once they hold no stock, and a bay in an unanticipated area still shows up instead of being silently dropped. There is deliberately no location list in `AppConfig`.
- **Picking is optimistic.** `toggle()` flips the item locally, notifies, then calls the API, and rolls back with an error message on failure. `isInFlight(id)` guards against a double tap racing itself.
- State is held per `PickMode`; `setMode()` drops the outgoing job's list so returning to it re-reads the server.

**Product code parsing:** `PickItem` splits the server's `code` against its `groupid` to expose `size`, `styleRef`, `model` and `displayName` (`0745531-GIZEH-37` + `0745531-GIZEH` -> size `37`, style ref `0745531`, model `Gizeh`). The UI leads with size because that is what gets mispicked. If the code has no recognisable size the getter returns an empty string and the row shows an em dash - do not assume it is always populated.

**Working list (do not "fix" this):** `PicklistScreen` never removes a line on its own. Picked rows stay in place, struck through with a green size chip, and tapping one again unpicks it. Only the explicit "Hide N picked" control sets lines aside (into `_setAside`), and a refresh clears that set. This is a direct response to picked items vanishing from a filtered list mid-aisle.

### Design system

One dark theme, no light variant and no toggle - `core/theme/app_theme.dart` is the single entry point (`AppTheme.theme`), applied in `main.dart`.

- `app_colors.dart` - "Stockroom" palette built out from the app mark's `#18353D`. **`AppColors.done` (green) means picked and nothing else**, and `AppColors.signal` (amber) is the only accent; keeping those two exclusive is what makes a list readable at a glance.
- `app_typography.dart` - Barlow Condensed for anything read at arm's length while walking (bay codes, sizes, counts), Barlow for everything else. Numerals are tabular.
- `app_spacing.dart` - 4px grid, `AppSpacing.gutter` for the shared screen edge, small radii.

Signature elements: the **size chip** on `PickRow` (a boxed numeral shaped like a shoebox end-label) and the **bay bar** that marks each walk to the next bay.

