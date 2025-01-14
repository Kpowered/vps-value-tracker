import type { NextAuthOptions } from 'next-auth'
import type { JWT } from 'next-auth/jwt'
import type { Session } from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import bcrypt from 'bcryptjs'
import prisma from './prisma'

// 扩展 Session 类型
interface CustomSession extends Session {
  user: {
    id: string
    email: string
  }
}

// 扩展 JWT 类型
interface CustomJWT extends JWT {
  id?: string
}

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        password: { label: "密码", type: "password" }
      },
      async authorize(credentials) {
        try {
          if (!credentials?.password) {
            console.log('No password provided')
            return null
          }

          const user = await prisma.user.findFirst()
          
          if (!user) {
            console.log('No user found')
            return null
          }

          const isValid = await bcrypt.compare(credentials.password, user.password)
          
          if (!isValid) {
            console.log('Invalid password')
            return null
          }

          return {
            id: user.id,
            email: 'admin@example.com'
          }
        } catch (error) {
          console.error('Auth error:', error)
          return null
        }
      }
    })
  ],
  session: {
    strategy: 'jwt',
    maxAge: 30 * 24 * 60 * 60 // 30 days
  },
  pages: {
    signIn: '/login'
  },
  callbacks: {
    async jwt({ token, user }): Promise<CustomJWT> {
      if (user) {
        token.id = user.id
      }
      return token
    },
    async session({ session, token }): Promise<CustomSession> {
      return {
        ...session,
        user: {
          ...session.user,
          id: token.id as string,
          email: 'admin@example.com'
        }
      }
    }
  },
  debug: process.env.NODE_ENV === 'development'
} 