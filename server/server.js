import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import { v4 as uuidv4 } from 'uuid'
import { WebSocketServer } from 'ws'

const app = express()
app.use(cors({ origin: true }))
app.use(express.json())

const PORT = process.env.PORT || 4000

const users = new Map()
const tripsByUser = new Map()

// Helpers
const RIDE_RATES = {
  standard: { base: 3.0, perKm: 1.2 },
  xl: { base: 5.0, perKm: 1.8 },
  luxury: { base: 8.0, perKm: 3.0 }
}
const PROMOS = { SAVE10: 0.1, SAVE20: 0.2 }

function surgeForDate(date) {
  const hour = new Date(date).getHours()
  return ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 20)) ? 1.25 : 1.0
}

// Routes
app.post('/auth/login', (req, res) => {
  const { email, password } = req.body || {}
  if (!email || !password) return res.status(400).json({ error: 'email and password required' })
  let user = users.get(email)
  if (!user) {
    user = { id: uuidv4(), name: 'Rider', email }
    users.set(email, user)
  }
  res.json(user)
})

app.post('/pricing/estimate', (req, res) => {
  const { rideType = 'standard', distanceKm = 0, when = new Date(), promoCode } = req.body || {}
  const rates = RIDE_RATES[rideType] || RIDE_RATES.standard
  const surge = surgeForDate(when)
  let fare = (rates.base + rates.perKm * Math.max(0, Number(distanceKm))) * surge
  if (promoCode && PROMOS[String(promoCode).toUpperCase()]) {
    fare *= (1 - PROMOS[String(promoCode).toUpperCase()])
  }
  fare = Math.round(fare * 100) / 100
  res.json({ fare })
})

app.get('/trips', (req, res) => {
  const userId = req.header('x-user-id')
  if (!userId) return res.status(400).json({ error: 'x-user-id required' })
  const trips = tripsByUser.get(userId) || []
  res.json({ trips })
})

app.post('/trips', (req, res) => {
  const userId = req.header('x-user-id')
  if (!userId) return res.status(400).json({ error: 'x-user-id required' })
  const trip = { id: uuidv4(), ...req.body }
  const list = tripsByUser.get(userId) || []
  list.unshift(trip)
  tripsByUser.set(userId, list)
  res.status(201).json(trip)
})

app.post('/payments/intent', (req, res) => {
  const { amountCents = 0, currency = 'usd' } = req.body || {}
  // Stub: In real app, call Stripe API to create a PaymentIntent and return client_secret
  const clientSecret = `pi_test_${uuidv4()}`
  res.json({ clientSecret, amountCents, currency })
})

const server = app.listen(PORT, () => {
  console.log(`API listening on http://localhost:${PORT}`)
})

// WebSocket for driver tracking
const wss = new WebSocketServer({ server, path: '/ws' })
wss.on('connection', (ws) => {
  ws.isAlive = true
  ws.on('pong', () => (ws.isAlive = true))

  const base = { lat: 37.7749, lon: -122.4194 } // Default SF; client may override
  let center = { ...base }

  ws.on('message', (data) => {
    try {
      const msg = JSON.parse(data.toString())
      if (msg.type === 'subscribe' && msg.lat && msg.lon) {
        center = { lat: Number(msg.lat), lon: Number(msg.lon) }
      }
    } catch {}
  })

  const interval = setInterval(() => {
    const drivers = Array.from({ length: 5 }).map((_, i) => ({
      id: `d${i}`,
      lat: center.lat + (Math.random() - 0.5) * 0.02,
      lon: center.lon + (Math.random() - 0.5) * 0.02
    }))
    const assignedDriverId = drivers[Math.floor(Math.random() * drivers.length)].id
    ws.send(JSON.stringify({ type: 'drivers', drivers, assignedDriverId }))
    ws.ping()
  }, 2000)

  ws.on('close', () => clearInterval(interval))
})

setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) return ws.terminate()
    ws.isAlive = false
    ws.ping()
  })
}, 10000)