import type { NextAuthOptions } from 'next-auth'
import type { JWT } from 'next-auth/jwt'
import type { Session } from 'next-auth'
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

          console.log('Finding user...')
          const user = await prisma.user.findFirst()
          
          if (!user) {
            console.log('No user found in database')
            return null
          }

          console.log('Comparing passwords...')
          const isValid = await bcrypt.compare(credentials.password, user.password)
          
          if (!isValid) {
            console.log('Password comparison failed')
            return null
          }

          console.log('Login successful')
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
    strategy: 'jwt'
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
      if (token && session.user) {
        session.user.id = token.id as string
      }
      return session
    }
  }
} 