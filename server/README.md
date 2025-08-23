# Ride Backend (Express + ws)

## Setup

1. Node.js 18+
2. Install deps:
   - cd server
   - npm install
3. Start:
   - npm start

API: `http://localhost:4000`
WS: `ws://localhost:4000/ws`

## Endpoints

- POST `/auth/login` { email, password } → user
- POST `/pricing/estimate` { rideType, distanceKm, when, promoCode } → { fare }
- GET `/trips` (header `x-user-id`) → { trips }
- POST `/trips` (header `x-user-id`) body `{ ...trip }` → trip
- POST `/payments/intent` { amountCents, currency } → { clientSecret }

## WebSocket

- Connect to `ws://localhost:4000/ws`
- Optionally send: `{ "type":"subscribe", "lat": 37.77, "lon": -122.42 }`
- Receive periodic messages:
  - `{ "type":"drivers", "drivers": [{"id":"d1","lat":..,"lon":..}], "assignedDriverId": "d1" }`

This is a stub for local development only.