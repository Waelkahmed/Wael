# Ride Backend (Express + ws)

## Setup

1. Node.js 18+
2. Install deps:
   - cd server
   - npm install
3. Set env vars (copy `.env.example` to `.env` and edit):
   - `DATABASE_URL` (Postgres)
   - `JWT_SECRET`
   - `STRIPE_SECRET_KEY` (optional)
4. Migrate DB:
   - npx prisma migrate dev --name init
5. Start:
   - npm start

Or with Docker Compose:

- docker-compose up --build

API: `http://localhost:4000`
WS: `ws://localhost:4000/ws`

## Endpoints

- POST `/auth/login` { email, password } → { user, accessToken, refreshToken, expiresIn }
- POST `/auth/refresh` { refreshToken } → { accessToken, expiresIn }
- POST `/devices/register` (Bearer) { token, platform } → { ok }
- POST `/pricing/estimate` { rideType, distanceKm, when, promoCode } → { fare }
- GET `/trips` (Bearer) → { trips }
- POST `/trips` (Bearer) `{ pickupName, dropoffName, pickupCoordinate:{lat,lon}, dropoffCoordinate:{lat,lon}, startDate, endDate, distanceKm, fare, rideType, rating, status }` → trip
- POST `/payments/intent` { amountCents, currency } → { clientSecret }

## WebSocket

- Connect to `ws://localhost:4000/ws`
- Optionally send: `{ "type":"subscribe", "lat": 37.77, "lon": -122.42 }`
- Receive periodic messages:
  - `{ "type":"drivers", "drivers": [{"id":"d1","lat":..,"lon":..}], "assignedDriverId": "d1" }`

This is a stub for local development only.