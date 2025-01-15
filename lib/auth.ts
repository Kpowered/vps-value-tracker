import { SignJWT, jwtVerify } from 'jose'
import { cookies } from 'next/headers'
import { NextRequest } from 'next/server'

const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || 'your-secret-key'
)

export interface UserJwtPayload {
  userId: number
}

export async function createToken(userId: number): Promise<string> {
  return await new SignJWT({ userId })
    .setProtectedHeader({ alg: 'HS256' })
    .setExpirationTime('24h')
    .sign(JWT_SECRET)
}

export async function verifyToken(token: string): Promise<UserJwtPayload | null> {
  try {
    const { payload } = await jwtVerify(token, JWT_SECRET)
    return payload as UserJwtPayload
  } catch {
    return null
  }
}

export async function getUser(req?: NextRequest): Promise<UserJwtPayload | null> {
  const cookieStore = cookies()
  const token = req?.cookies.get('token')?.value || cookieStore.get('token')?.value

  if (!token) return null

  return await verifyToken(token)
} 