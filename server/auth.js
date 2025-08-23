import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.JWT_SECRET || 'devsecret'
const ACCESS_TTL_S = 60 * 15
const REFRESH_TTL_S = 60 * 60 * 24 * 30

export function issueTokens(userId) {
  const accessToken = jwt.sign({ sub: userId, type: 'access' }, JWT_SECRET, { expiresIn: ACCESS_TTL_S })
  const refreshToken = jwt.sign({ sub: userId, type: 'refresh' }, JWT_SECRET, { expiresIn: REFRESH_TTL_S })
  return { accessToken, refreshToken, expiresIn: ACCESS_TTL_S }
}

export function verifyToken(token) {
  return jwt.verify(token, JWT_SECRET)
}

export function authRequired(req, res, next) {
  const header = req.header('authorization') || ''
  const parts = header.split(' ')
  if (parts.length !== 2 || parts[0].toLowerCase() !== 'bearer') return res.status(401).json({ error: 'missing bearer token' })
  try {
    const payload = verifyToken(parts[1])
    if (payload.type !== 'access') return res.status(401).json({ error: 'invalid token' })
    req.userId = payload.sub
    next()
  } catch (e) {
    return res.status(401).json({ error: 'invalid token' })
  }
}