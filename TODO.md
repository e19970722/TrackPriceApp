# Pre-Development Blockers

These must be set up manually before the relevant code can be tested end-to-end.
Check them off as you go.

## Apple
- [ ] Enroll in Apple Developer Program (https://developer.apple.com/programs/)
- [ ] Register an App ID with **Sign In with Apple** and **Push Notifications** capabilities
- [ ] Generate an APNs Auth Key (`.p8`) — needed by backend to send push notifications
- [ ] Note down: Team ID, Bundle ID, APNs Key ID

## Google
- [ ] Create a Google Cloud project (https://console.cloud.google.com/)
- [ ] Enable the **Google Sign-In** (People API / Identity)
- [ ] Create an OAuth 2.0 Client ID for iOS (Bundle ID required)
- [ ] Note down: Client ID for iOS

## Scraping Proxy
- [ ] Sign up for a residential proxy provider (Brightdata / Oxylabs / Zyte)
- [ ] Obtain proxy host, username, password
- [ ] Add credentials to backend `.env` as `PROXY_HOST`, `PROXY_USER`, `PROXY_PASS`

## Backend Hosting
- [ ] Pick a hosting provider for FastAPI + PostgreSQL + Redis
  - Recommended options: Railway, Render, Fly.io
- [ ] Provision a PostgreSQL instance
- [ ] Provision a Redis instance
- [ ] Set up environment variables in the hosting dashboard

## When All Done
Once the above are complete, let Claude Code know — it will remind you to wire the credentials
into the backend config and the iOS `Config.xcconfig` before the first end-to-end test.
