import { NextResponse } from 'next/server'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export async function GET() {
  try {
    const rates = await prisma.exchangeRate.findMany()
    const ratesMap = rates.reduce((acc, rate) => {
      acc[rate.currency] = rate.rate
      return acc
    }, {} as Record<string, number>)
    
    return NextResponse.json(ratesMap)
  } catch (error) {
    return NextResponse.json({ error: '获取失败' }, { status: 500 })
  }
} 