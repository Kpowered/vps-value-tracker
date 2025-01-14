import { NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import prisma from '@/lib/prisma'
import { authOptions } from '../auth/[...nextauth]/route'

export async function GET() {
  try {
    const vpsList = await prisma.vPS.findMany({
      orderBy: { createdAt: 'desc' }
    })
    return NextResponse.json(vpsList)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch VPS list' }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const session = await getServerSession(authOptions)
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const data = await request.json()
    const startDate = new Date()
    const endDate = new Date(startDate.getTime() + 365 * 24 * 60 * 60 * 1000)

    const vps = await prisma.vPS.create({
      data: {
        ...data,
        startDate,
        endDate
      }
    })

    return NextResponse.json(vps)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create VPS' }, { status: 500 })
  }
} 