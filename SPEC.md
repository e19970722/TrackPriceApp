# TrackPriceApp — Product Specification

## Overview

A native iOS app with two core features:

1. **Price Tracker** — monitor prices on any webpage. The user picks the price element directly inside a WebView; the backend watches it on a schedule and sends a push notification when the price crosses a user-defined threshold.
2. **Expiry Tracker** — track expiry dates for any physical or digital item (food, medicine, cosmetics, coupons, subscriptions). The app reminds the user before an item expires, with a per-item configurable lead time.

---

## Tab Navigation

The app has three top-level tabs:

| Tab | Icon | Purpose |
|---|---|---|
| **Home** | house | Trending tracks + expiry reminders + price target hits |
| **Tracks** | tag | All tracked items (expiry dates and prices), with segmented control |
| **Profile** | person.circle | Settings, account, notifications |

---

## Core User Flow — Price Tracker

1. User opens the app and signs in (Apple or Google).
2. User taps **+** in the Tracks tab (with "Prices" segment active) and enters a URL.
3. App opens a **WKWebView** browser — user navigates freely until the right page/state is showing.
4. User **long-presses** anywhere to activate *Selection Mode* (a floating "Selection Mode" banner appears; all link navigation is intercepted).
5. User taps the price element — it gets highlighted with a CSS overlay.
6. A **bottom sheet** appears showing:
   - Raw element text (e.g. `"Was $200 Now $149"`)
   - The app's parsed numeric value (editable — user corrects if wrong)
   - Detected currency symbol
7. User sets a tracker name (defaults to page `<title>`), a **target price**, and direction (**below** or **above**).
8. If the current price already meets the target: show a warning dialog — *"Current price ($X) already meets your target of $Y. Save anyway?"*
9. Tracker is saved; background checking begins.

---

## Core User Flow — Expiry Tracker

1. User taps **+** in the Tracks tab (with "Expire Dates" segment active).
2. User enters: item name, expiry date, category (optional), and reminder lead time (e.g. "3 days before").
3. Item is saved. The app schedules a local notification for `expiry_date − lead_time`.
4. On the Home tab, items expiring within the next 7 days appear in the **Expiring Soon** section.
5. User can edit or delete items from the Tracks tab (Expire Dates segment).

---

## Home Tab

### On Trend Tracks Section
- Shows the **top 10 URLs** currently tracked by the most users across the entire app.
- Displayed as a horizontal scrollable rail of avatar-style thumbnails, each showing the item name and a price-change delta badge (e.g. −11%, +6%) with directional arrow.
- Items contribute anonymously — no user identity is ever shown or stored against a trending entry.
- Tapping a trending item deep-links to the Add Tracker flow pre-filled with that URL.

### Expire Soon Section
- Shows items from the user's Tracks (Expire Dates) that expire within the next **7 days**, sorted by soonest first.
- Each card shows: thumbnail, item name, quantity/location meta, and a days-remaining chip (warn tone if ≤ 3 days).
- Tapping an item opens the expiry item detail/edit sheet.
- If no items are expiring soon, the section is hidden.

### Price Reach Targets Section
- Shows price trackers where the current price has hit (or crossed) the user's target.
- Displayed as a highlighted hero card with: item name, store, current price (large), previous price (struck through), delta badge, and a **Shop now** CTA that opens the tracked URL.
- Shows "target was $X" footer.
- If no trackers have hit their target, the section is hidden.

---

## iOS App

### Tech Stack

- Swift + SwiftUI
- WKWebView for browsing and element selection
- Charts framework (iOS 16+) for price history graphs
- async/await + Combine for networking and state management
- Firebase Cloud Messaging (FCM) or direct APNs for push tokens
- StoreKit 2 / RevenueCat when monetization is added

### Screens

| Screen | Tab | Purpose |
|---|---|---|
| **Home** | Home | On Trend Tracks rail + Expire Soon cards + Price Reach Targets hero |
| **Tracks List** | Tracks | Segmented control (Expire Dates / Prices), search, all tracked items with urgency bars; FAB to add |
| **Expiry Item Detail** | Tracks | Edit name, date, lead time; delete |
| **Tracker Detail** | Tracks | Current/target price, price history chart, stats; edit/delete |
| **Add Expiry Item** | Tracks | Item name, expiry date, category, reminder lead time |
| **Add Tracker — URL Entry** | Tracks | URL input with paste and QR options |
| **Add Tracker — WebView Browser** | Tracks | Full browser with long-press selection mode |
| **Add Tracker — Confirm Element** | Tracks | Bottom sheet: raw text, editable parsed price, currency |
| **Add Tracker — Set Target** | Tracks | Target price input, direction toggle, tracker name |
| **Profile** | Profile | Account info, notification preferences (price drops, expiring soon, running low, weekly digest), sign out |

### WebView Element Picker (`ElementPicker.js`)

Injected into WKWebView at page load. Inactive until the user long-presses.

**Activation:**
- Long-press gesture on the WebView view controller activates selection mode.
- JS sets `document.body` into intercept mode: all `<a>` clicks are `preventDefault()`-ed, all touch events route through the picker.

**Selection:**
- User taps any element → JS walks up the DOM to find the nearest non-generic ancestor with meaningful text.
- A CSS highlight overlay is applied to the matched element.
- JS calls `window.webkit.messageHandlers.elementSelected.postMessage({...})` with:
  - `cssSelector` — computed unique path (e.g. `#product-detail > div.price-box > span.price`)
  - `xpath` — absolute XPath as fallback
  - `innerText` — raw visible text of the element
  - `boundingRect` — for scrolling the confirmation sheet into view

**Deactivation:**
- Tapping the "Selection Mode" banner again, or navigating away, deactivates the mode.

### Price Parsing (client-side, for the confirmation step)

Regex-based, applied to `innerText` before showing the confirmation sheet:

- Strip currency symbols and non-numeric prefix/suffix text.
- Distinguish comma-as-thousands (`1,299.00`) from comma-as-decimal (`1.299,00`) based on position.
- Handle `¥12,800`, `HK$499`, `£1,200.00`, `€49,99`.
- "From $X" → extract $X, show note: *"Showing lower bound of a range."*
- "Was $200 Now $149" → extract $149 (last/rightmost price).
- If no numeric value can be extracted: show empty field with placeholder *"Enter price manually."*

The user sees the parsed value and can correct it before saving. The corrected value is stored as `confirmed_price` and used as the first data point in price history.

---

## Backend

### Tech Stack

- Python 3.12 + FastAPI
- PostgreSQL — users, trackers, price history, URL jobs
- Redis + Celery — job queue and scheduler (Celery Beat)
- Playwright + rotating residential proxies (Brightdata / Oxylabs) — page rendering
- APNs / FCM — push notifications

### Data Models

#### `users`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `auth_provider` | enum(`apple`, `google`) | |
| `auth_provider_id` | text | Subject from JWT |
| `email` | text nullable | Apple may hide it |
| `apns_token` | text nullable | Updated on each app launch |
| `subscription_tier` | enum(`free`, `paid`) | Default `free` |
| `created_at` | timestamptz | |

#### `trackers`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `user_id` | UUID FK | |
| `url` | text | Full URL including query params |
| `name` | text | User-set or page title |
| `css_selector` | text | From picker |
| `xpath` | text | Fallback |
| `currency_symbol` | text | As scraped, e.g. `"$"`, `"¥"` |
| `target_price` | numeric | |
| `target_direction` | enum(`below`, `above`) | |
| `check_interval` | enum(`daily`, `hourly`) | `daily` for free tier |
| `status` | enum(`active`, `paused`, `broken`) | |
| `last_price` | numeric nullable | Most recent scraped price |
| `last_checked_at` | timestamptz nullable | |
| `last_successful_fetch_at` | timestamptz nullable | |
| `failure_count` | int | Consecutive failures |
| `first_failure_at` | timestamptz nullable | Reset on success |
| `last_notified_at` | timestamptz nullable | For 24h throttle |
| `last_notified_price` | numeric nullable | For re-notify logic |
| `created_at` | timestamptz | |

#### `expiry_items`

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `user_id` | UUID FK | |
| `name` | text | User-set item name |
| `category` | text nullable | e.g. "Food", "Medicine", "Coupon" |
| `expiry_date` | date | The expiry date |
| `remind_days_before` | int | Lead time in days; default 3 |
| `notified_at` | timestamptz nullable | When the expiry reminder was sent |
| `created_at` | timestamptz | |

#### `price_snapshots`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `tracker_id` | UUID FK | |
| `price` | numeric | Parsed value |
| `raw_text` | text | Original scraped text |
| `scraped_at` | timestamptz | |

Index on `(tracker_id, scraped_at DESC)` for chart queries.

#### `url_jobs` (deduplication table)

| Column | Type | Notes |
|---|---|---|
| `url` | text PK | Canonical URL |
| `last_fetched_at` | timestamptz nullable | |
| `next_fetch_at` | timestamptz | Scheduled time |
| `fetch_status` | enum(`pending`, `in_progress`, `done`, `failed`) | |
| `last_html_hash` | text nullable | For change detection optimisation |

### URL-Level Deduplication

Multiple users can track the same URL. The backend fetches each URL **once per check window** and fans the result out to all trackers for that URL.

- `url_jobs` holds one row per unique URL.
- Celery Beat enqueues a `fetch_url` task per `url_job` based on `next_fetch_at`.
- After a successful fetch, the worker queries all `trackers` where `url = ?` and `status = 'active'`, applies each tracker's CSS selector, stores snapshots, and evaluates alert conditions.
- If a URL is tracked only by paid users, its interval is hourly; if any free user also tracks it, the interval is daily (most restrictive wins, can relax later).

### Scraping Pipeline (per URL job)

1. **Fetch** — Playwright launches headless Chromium, loads URL through residential proxy, waits for `networkidle`.
2. **Per-tracker extraction** — for each tracker on this URL:
   a. Query `document.querySelector(css_selector)` → extract `innerText`.
   b. If null: try `xpath` fallback.
   c. Apply same regex parser used client-side to extract numeric price.
3. **Store** — insert `price_snapshot` row.
4. **Evaluate alerts** — see Alert Evaluation below.
5. **Update tracker** — set `last_checked_at`, `last_price`, reset `failure_count` and `first_failure_at` on success.

### Selector Failure Handling

A failure is any of: selector returns null, regex can't extract a number, HTTP error, page timeout, proxy error.

| Condition | Action |
|---|---|
| failure but `first_failure_at + 3 days > now` | Increment `failure_count`, silent retry on normal schedule |
| `first_failure_at + 3 days ≤ now` (sustained failure) | Set `status = 'broken'`, send push: *"[Name] — couldn't fetch price for 3 days. Tap to fix."* |
| Success after any failures | Reset `failure_count = 0`, `first_failure_at = null`, `status = 'active'` |

### Alert Evaluation

For each tracker after a successful scrape:

1. **Condition check:**
   - `below`: `new_price ≤ target_price`
   - `above`: `new_price ≥ target_price`
2. **Re-notify guard:** only fire if `new_price < last_notified_price` (for `below`) or `new_price > last_notified_price` (for `above`). This means the price must reach a **new extreme** past the threshold to trigger another alert.
3. **24h throttle:** skip if `last_notified_at + 24h > now`.
4. If all checks pass: enqueue push notification, update `last_notified_at` and `last_notified_price`.

### Domain-Level Rate Limiting

To reduce the chance of IP blocks, the worker enforces a minimum gap of **10 seconds between requests to the same domain**, regardless of how many URL jobs are queued for that domain.

### Push Notifications

| Scenario | Notification Body |
|---|---|
| Price below target | `"[Name] is now $X — your target is under $Y. Tap to view."` |
| Price above target | `"[Name] is now $X — your target is over $Y. Tap to view."` |
| Tracker broken (3-day failure) | `"[Name] — couldn't fetch price. Tap to provide a new URL or re-select."` |
| Expiry reminder | `"[Name] expires in [N] day(s). Don't forget to use it!"` |

- Max **1 alert push per tracker per 24 hours** (tracker-broken pushes are separate and not throttled the same way).
- User can mute a specific tracker's notifications from the Tracker Detail screen (stored as a flag on the tracker).
- Notification categories (all toggleable from the Profile tab):
  - **Price drops** — when a price tracker hits its target
  - **Expiring soon** — configurable lead time before an expiry date
  - **Running low** — when quantity reaches a reorder point (future)
  - **Weekly digest** — Sunday summary of all tracks (future)

---

## Authentication

- **Apple Sign In** (required for App Store if social login is offered)
- **Google Sign In**
- Backend issues JWT on sign-in; tokens refresh silently.
- Apple's private-relay email is accepted and stored as-is; no email is required.

---

## Tracker Limits

| Tier | Active Trackers | Check Interval |
|---|---|---|
| Free | 10 | Daily |
| Paid (future) | Unlimited | Hourly |

Currently all users are on the free tier with no paywall enforced. Infrastructure is built with tier-awareness (the `subscription_tier` column and `check_interval` field exist) so the paywall can be switched on without a migration.

---

## Price History

- Every successful scrape stores a `price_snapshot` row.
- Tracker Detail screen shows a line chart of all historical data points.
- Chart uses native iOS Charts framework; x-axis is time, y-axis is price.
- No automatic purge — history is retained for the lifetime of the tracker.
- On tracker deletion: cascade delete all price snapshots.

---

## Currency

- Price is stored and displayed **as scraped** — no conversion.
- Currency symbol is captured during element selection (extracted from element text or nearby sibling text).
- Target price is set in the same currency as the scraped price.
- No FX rates, no normalization across currencies.

---

## Variants & Pagination

- The app tracks whatever element the user selected at setup time.
- URL is stored including query params and hash (e.g. `?color=blue&size=M`).
- If a variant selection changes the DOM without changing the URL (JS-only state), the user must track that state manually by navigating to it before long-pressing.
- No automatic variant replay in v1.

---

## Out-of-Stock Detection

Deferred to a future release.

Current v1 behavior: the scraper attempts to fetch the price on every check regardless of stock status. If the price element is present, the price is recorded normally. Out-of-stock states that remove the price element are treated as selector failures (→ 3-day retry logic applies).

---

## Robots.txt

Not respected. The app operates on user-initiated tracking of public URLs.

---

## Platform

- iOS only, iOS 16+.
- No Android support planned.
- Backend API is mobile-agnostic (REST + JWT) for future extensibility.

---

## Open Questions (deferred)

- **Proxy provider selection**: Brightdata vs Oxylabs vs Zyte — benchmark success rates against major retailers before committing.
- **Celery vs. APScheduler**: For early scale a single APScheduler instance may suffice; move to Celery when worker concurrency is needed.
- **Push notification service**: direct APNs via `aioapns` vs FCM relay — decide based on whether Android is ever added.
- **Out-of-stock signal**: planned for v2 — user optionally selects a second element (e.g. "Add to Cart" button) as a stock indicator during setup.
- **Shared/community selectors**: if multiple users track the same URL, allow a successful re-selection by one user to propagate to others who are broken.
