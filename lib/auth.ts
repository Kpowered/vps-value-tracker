import type { NextAuthOptions } from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import bcrypt from 'bcryptjs'
import prisma from './prisma'

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
            email: 'admin@example.com' // NextAuth 需要一个唯一标识符
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
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id
      }
      return token
    },
    async session({ session, token }) {
      if (token) {
        session.user = {
          id: token.id as string,
          email: 'admin@example.com'
        }
      }
      return session
    }
  },
  debug: process.env.NODE_ENV === 'development'
} 