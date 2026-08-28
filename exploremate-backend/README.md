# ExploreMate Backend

A complete Node.js + Express.js backend for the **ExploreMate AI Tour Guide** Flutter mobile app. It runs immediately with an in-memory development database and can switch to PostgreSQL when you are ready.

It implements every functional requirement from the project documentation:

- JWT-based authentication with email + password and OTP verification (Firebase or DB-backed fallback)
- User & profile management, preferences, trip history
- Destinations: search, nearby, hidden gems, trending, full CRUD (admin)
- Trips: scheduling, AI-generated itineraries, PDF export
- Reviews, favorites, bookings
- AI Audio Tour Guide (OpenAI script + Google Text-to-Speech)
- AI Assistant chat, smart recommendations, travel tips
- Translator (Google Translate) with TTS playback
- Weather lookup + weather-based food recommendations
- Gamification: XP, levels, badges, leaderboard, missions
- In-app notifications
- Location services: geocoding, reverse-geocoding, nearby places (Google Maps)

The code is structured for clarity and is fully working **out of the box** even without external API keys — every external service has a deterministic mock fallback so you can wire the Flutter app up immediately and add keys later.

---

## Tech Stack

| Layer | Tech |
|---|---|
| Runtime | Node.js 18+ |
| Framework | Express.js |
| Database | In-memory dev adapter, PostgreSQL 14+ for persistence |
| Auth | JWT (access + refresh) + Firebase Admin SDK |
| AI | OpenAI Chat / Itinerary / Audio scripts |
| Maps | Google Maps Places & Geocoding |
| Weather | OpenWeather |
| Translation | Google Cloud Translate |
| Voice | Google Cloud Text-to-Speech |
| PDF | PDFKit |

---

## Project Structure

```
exploremate-backend/
├── server.js                  # entry point
├── package.json
├── .env.example               # env template
└── src/
    ├── app.js                 # Express app factory
    ├── config/
    │   ├── database.js        # DB facade
    │   ├── memoryDatabase.js  # local dev data store
    │   └── firebase.js        # Firebase admin init
    ├── db/
    │   ├── schema.sql         # full schema
    │   ├── init.js            # `npm run db:init`
    │   └── seed.js            # `npm run db:seed`
    ├── middleware/
    │   ├── authMiddleware.js  # JWT protect / optionalAuth / restrictTo
    │   ├── errorHandler.js
    │   ├── notFound.js
    │   ├── rateLimiter.js
    │   └── validate.js
    ├── utils/
    │   ├── jwt.js
    │   ├── password.js
    │   ├── responseHandler.js
    │   ├── geo.js
    │   └── logger.js
    ├── services/
    │   ├── openaiService.js
    │   ├── weatherService.js
    │   ├── translatorService.js
    │   ├── ttsService.js
    │   ├── googleMapsService.js
    │   └── pdfService.js
    ├── controllers/
    │   ├── authController.js
    │   ├── userController.js
    │   ├── destinationController.js
    │   ├── tripController.js
    │   ├── favoriteController.js
    │   ├── reviewController.js
    │   ├── aiController.js
    │   ├── audioTourController.js
    │   ├── translatorController.js
    │   ├── weatherController.js
    │   ├── foodController.js
    │   ├── hiddenGemsController.js
    │   ├── gameController.js
    │   ├── notificationController.js
    │   └── locationController.js
    └── routes/
        └── ... matching route file per controller
```

---

## Getting Started

### 1. Prerequisites
- Node.js 18+
- PostgreSQL 14+ only if you want persistent storage

### 2. Install
```bash
cd exploremate-backend
npm install
```

### 3. Configure environment
```bash
cp .env.example .env
# optional: edit JWT secrets or third-party API keys
```

By default, local development uses the in-memory adapter seeded with demo data.
Demo login: `admin@exploremate.app` / `Admin@12345`.

### 4. Optional: initialize PostgreSQL
```bash
createdb exploremate          # if PostgreSQL is local
# set DB_MODE=postgres in .env
npm run db:init               # apply schema
npm run db:seed               # insert sample destinations + admin user
```

The seed creates an admin: `admin@exploremate.app` / `Admin@12345`.

### 5. Run
```bash
npm run dev      # with nodemon
# or
npm start
```

The API is served at `http://localhost:5000/api/v1` by default.

---

## API Reference (selected)

Base URL: `${API_PREFIX}` (default `/api/v1`).
All authenticated endpoints expect `Authorization: Bearer <accessToken>`.

### Auth
| Method | Path | Description |
|---|---|---|
| POST | `/auth/register` | Register with name, email, password (returns OTP for verification) |
| POST | `/auth/login` | Login with email + password |
| POST | `/auth/firebase` | Login/register with a Firebase ID token (phone OTP / Google) |
| POST | `/auth/verify-otp` | Verify the 6-digit OTP |
| POST | `/auth/resend-otp` | Resend OTP |
| POST | `/auth/refresh` | Get a new access token from a refresh token |
| POST | `/auth/logout` | Revoke refresh tokens |
| POST | `/auth/forgot-password` | Send a reset code |
| POST | `/auth/reset-password` | Reset password with code |
| GET  | `/auth/me` | Current user |

### Users
- `GET /users/me`, `PUT /users/me`, `PATCH /users/me/preferences`
- `GET /users/me/history`, `POST /users/me/history`
- `DELETE /users/me` — deactivate
- `GET /users/` — admin list

### Destinations
- `GET /destinations` — `?q=&category=&minRating=&hidden=&sort=&limit=&offset=`
- `GET /destinations/trending`
- `GET /destinations/nearby?lat=&lng=&radius=`
- `GET /destinations/:id`
- `POST/PUT/DELETE /destinations[/:id]` — admin only

### Trips
- `GET /trips`, `POST /trips`, `GET /trips/:id`, `PUT /trips/:id`, `DELETE /trips/:id`
- `POST /trips/:id/generate-itinerary` — AI itinerary
- `GET /trips/:id/export-pdf` — download PDF

### Favorites & Reviews
- `GET /favorites`, `POST /favorites`, `DELETE /favorites/:destinationId`
- `GET /reviews/destination/:id`, `POST /reviews`, `DELETE /reviews/:id`

### AI
- `POST /ai/chat` — `{ messages:[{role,content}], system? }`
- `POST /ai/recommend` — personalised place recs
- `POST /ai/travel-tips`

### Audio Tour
- `POST /audio-tour` — generate transcript + TTS audio
- `GET /audio-tour`, `GET /audio-tour/:id`

### Translator
- `GET /translator/languages`
- `POST /translator` — `{ text, target, source? }`
- `POST /translator/speak` — TTS audio

### Weather & Food
- `GET /weather?city=` or `?lat=&lng=`
- `GET /food` — list food destinations
- `POST /food/recommend` — weather-based food picks

### Hidden Gems
- `GET /hidden-gems`, `GET /hidden-gems/nearby?lat=&lng=&radius=`

### Gamification
- `GET /game/me`, `POST /game/award`, `GET /game/leaderboard`
- `GET /game/badges`, `POST /game/badges/:code/grant`
- `GET /game/missions`

### Notifications
- `GET /notifications`, `POST /notifications` (admin)
- `PATCH /notifications/:id/read`, `PATCH /notifications/read-all`
- `DELETE /notifications/:id`

### Location
- `GET /location/geocode?address=`
- `GET /location/reverse?lat=&lng=`
- `GET /location/nearby?lat=&lng=&type=&keyword=&radius=`

---

## Response Shape

Every endpoint returns JSON in this shape:

```jsonc
// success
{ "success": true, "message": "OK", "data": { ... } }
// error
{ "success": false, "message": "...", "errors": [ ... ] }
```

---

## Connecting the Flutter App

Add a base URL constant in your Flutter code (e.g. `lib/api/api_client.dart`):

```dart
const apiBase = 'http://10.0.2.2:5000/api/v1'; // Android emulator
// const apiBase = 'http://localhost:5000/api/v1'; // iOS simulator
```

Then use `http` or `dio` to call the endpoints above. Save the `accessToken` and `refreshToken` returned from `/auth/login` in `flutter_secure_storage`, send the access token as `Authorization: Bearer ...`, and call `/auth/refresh` whenever the access token expires.

---

## Production Deployment

1. Set `NODE_ENV=production`.
2. Set strong unique values for `JWT_SECRET`, `JWT_REFRESH_SECRET`.
3. Use a managed PostgreSQL (Railway, Supabase, RDS) and set `DATABASE_URL` + `PG_SSL=true`.
4. Configure all third-party keys (`OPENAI_API_KEY`, `GOOGLE_MAPS_API_KEY`, `OPENWEATHER_API_KEY`, `GOOGLE_TRANSLATE_API_KEY`, `GOOGLE_TTS_API_KEY`).
5. Provide Firebase service account credentials via env or `firebase-service-account.json`.
6. Deploy with `npm start`. Reverse-proxy through HTTPS (Nginx / Caddy / cloud LB).

---

## License

MIT — feel free to use ExploreMate for your project, hackathon, or capstone.
#   E x p l o r e M a t e - b a c k e n d  
 