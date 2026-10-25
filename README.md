# Linky

Linky is a social-commerce application: a user has a polished public page at
`https://linky.to/:username`, social links, featured products and a private
mobile management experience.

## What is included

- Flutter mobile and web application with a modern profile/store experience.
- Public profile API: `GET /api/public/:username` and click analytics.
- Creator links API (max 30 links) and automation rules for welcome messages,
  low-stock alerts and order updates.
- Firebase-authenticated API calls; the backend no longer accepts an arbitrary
  user id or unsigned JWT as proof of identity.
- CORS allow-list and standard protective HTTP response headers.

## Run the application

```powershell
flutter pub get
flutter run
```

For a web build:

```powershell
flutter build web --dart-define=API_BASE_URL=https://YOUR-WORKER.workers.dev
```

## Deploy the API securely

Run the database migrations, including `backend/migrations/0003_creator_profiles.sql`
and `backend/migrations/0004_store_team_unique.sql`.
For store customization, apply `backend/migrations/0005_store_branding.sql` too.
Portfolio support requires `backend/migrations/0006_portfolio.sql`.
Portfolio galleries (up to three Cloudflare images per project) require `backend/migrations/0007_portfolio_images.sql`.
Before deploying the Cloudflare Worker, configure these values in its dashboard
or with Wrangler; do not put them in the Flutter client:

```powershell
cd backend
npx wrangler d1 execute linky-db --remote --file=migrations/0003_creator_profiles.sql
npx wrangler d1 execute linky-db --remote --file=migrations/0004_store_team_unique.sql
npx wrangler d1 execute linky-db --remote --file=migrations/0005_store_branding.sql
npx wrangler d1 execute linky-db --remote --file=migrations/0006_portfolio.sql
npx wrangler d1 execute linky-db --remote --file=migrations/0007_portfolio_images.sql
npx wrangler secret put FIREBASE_API_KEY
npx wrangler deploy
```

Set `ALLOWED_ORIGINS` in `backend/wrangler.toml` to the final web domains. The
Firebase API key is used by the Worker solely to validate Firebase ID tokens;
Firebase Authentication remains responsible for passwords and sessions.

## AliExpress import hub

The AliExpress scraper needs Chrome/Puppeteer and therefore runs as a separate
Node 24 service, not in a Cloudflare Worker. In
`aliexpress-product-scraper-master`, install its dependencies and run:

```powershell
$env:IMPORT_SERVICE_TOKEN = "generate-a-long-random-secret"
node service/server.js
```

Configure the Worker with the same token using `npx wrangler secret put
IMPORT_SERVICE_TOKEN`, and set `IMPORT_SERVICE_URL` to the service URL. The
app first previews a product; the seller then chooses variants and a selling
price before publishing. Only a valid AliExpress item URL is accepted.
