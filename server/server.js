import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import rateLimit from 'express-rate-limit'
import bcrypt from 'bcryptjs'
import { WebSocketServer } from 'ws'
import Stripe from 'stripe'
import { prisma } from './db.js'
import { issueTokens, authRequired, verifyToken } from './auth.js'

const app = express()
app.use(helmet())
app.use(cors({ origin: true }))
app.use(express.json())
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 300 }))

const PORT = process.env.PORT || 4000
const stripeKey = process.env.STRIPE_SECRET_KEY
const stripe = stripeKey ? new Stripe(stripeKey) : null

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

// Auth
app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body || {}
  if (!email || !password) return res.status(400).json({ error: 'email and password required' })
  const normalized = String(email).toLowerCase().trim()
  let user = await prisma.user.findUnique({ where: { email: normalized } })
  if (!user) {
    const passwordHash = await bcrypt.hash(String(password), 10)
    user = await prisma.user.create({ data: { email: normalized, passwordHash, name: 'Rider' } })
  } else {
    const ok = await bcrypt.compare(String(password), user.passwordHash)
    if (!ok) return res.status(401).json({ error: 'invalid credentials' })
  }
  const { accessToken, refreshToken, expiresIn } = issueTokens(user.id)
  res.json({ user: { id: user.id, name: user.name, email: user.email }, accessToken, refreshToken, expiresIn })
})

app.post('/auth/refresh', (req, res) => {
  const { refreshToken } = req.body || {}
  if (!refreshToken) return res.status(400).json({ error: 'refreshToken required' })
  try {
    const payload = verifyToken(refreshToken)
    if (payload.type !== 'refresh') return res.status(401).json({ error: 'invalid token' })
    const { accessToken, expiresIn } = issueTokens(payload.sub)
    res.json({ accessToken, expiresIn })
  } catch {
    res.status(401).json({ error: 'invalid token' })
  }
})

app.post('/auth/apple', async (req, res) => {
  const { identityToken } = req.body || {}
  if (!identityToken) return res.status(400).json({ error: 'identityToken required' })
  // NOTE: For demo only. In production, validate token signature & audience.
  const pseudoEmail = `apple_${Buffer.from(identityToken).toString('hex').slice(0,8)}@example.com`
  let user = await prisma.user.findUnique({ where: { email: pseudoEmail } })
  if (!user) {
    user = await prisma.user.create({ data: { email: pseudoEmail, passwordHash: await bcrypt.hash('apple', 10), name: 'Apple User' } })
  }
  const { accessToken, refreshToken, expiresIn } = issueTokens(user.id)
  res.json({ user: { id: user.id, name: user.name, email: user.email }, accessToken, refreshToken, expiresIn })
})

// Devices
app.post('/devices/register', authRequired, async (req, res) => {
  const { token, platform = 'ios' } = req.body || {}
  if (!token) return res.status(400).json({ error: 'token required' })
  await prisma.device.create({ data: { token, platform, userId: req.userId } })
  res.json({ ok: true })
})

// Pricing
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

// Trips
app.get('/trips', authRequired, async (req, res) => {
  const trips = await prisma.trip.findMany({ where: { userId: req.userId }, orderBy: { startDate: 'desc' } })
  res.json({ trips })
})

app.post('/trips', authRequired, async (req, res) => {
  const t = req.body || {}
  const trip = await prisma.trip.create({
    data: {
      pickupName: t.pickupName,
      dropoffName: t.dropoffName,
      pickupLat: t.pickupCoordinate?.lat ?? 0,
      pickupLon: t.pickupCoordinate?.lon ?? 0,
      dropoffLat: t.dropoffCoordinate?.lat ?? 0,
      dropoffLon: t.dropoffCoordinate?.lon ?? 0,
      startDate: new Date(t.startDate || Date.now()),
      endDate: new Date(t.endDate || Date.now()),
      distanceKm: Number(t.distanceKm || 0),
      fare: Number(t.fare || 0),
      rideType: String(t.rideType || 'standard'),
      rating: t.rating ?? null,
      status: String(t.status || 'completed'),
      userId: req.userId
    }
  })
  res.status(201).json(trip)
})

// Payments
app.post('/payments/intent', async (req, res) => {
  const { amountCents = 0, currency = 'usd' } = req.body || {}
  if (stripe) {
    try {
      const intent = await stripe.paymentIntents.create({ amount: Math.max(0, Math.floor(amountCents)), currency })
      return res.json({ clientSecret: intent.client_secret, amountCents, currency })
    } catch (e) {
      return res.status(500).json({ error: 'stripe_error', message: e.message })
    }
  }
  const clientSecret = `pi_test_${Date.now()}`
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

  const base = { lat: 37.7749, lon: -122.4194 }
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