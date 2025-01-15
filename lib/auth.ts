import { jwtVerify, SignJWT } from 'jose'
import { cookies } from 'next/headers'
import { NextRequest } from 'next/server'

const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || 'your-secret-key'
)

export async function createToken(userId: number) {
  return await new SignJWT({ userId })
    .setProtectedHeader({ alg: 'HS256' })
    .setExpirationTime('24h')
    .sign(JWT_SECRET)
}

export async function verifyToken(token: string) {
  try {
    const verified = await jwtVerify(token, JWT_SECRET)
    return verified.payload as { userId: number }
  } catch (err) {
    return null
  }
}

export async function getUser(req?: NextRequest) {
  const cookieStore = cookies()
  const token = req?.cookies.get('token')?.value || cookieStore.get('token')?.value

  if (!token) return null

  const verified = await verifyToken(token)
  return verified
} 