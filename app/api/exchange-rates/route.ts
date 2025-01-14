import { NextResponse } from 'next/server'
import axios from 'axios'
import prisma from '@/lib/prisma'

const FIXER_API_KEY = 'e65a0dbfc190ce964f2771bca5c08e13'
const FIXER_API_URL = 'http://data.fixer.io/api'

export async function GET() {
  try {
    // 检查数据库中是否有今天的汇率数据
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    let rates = await prisma.exchangeRate.findFirst({
      where: {
        updatedAt: {
          gte: today
        }
      }
    })

    // 如果没有今天的数据，则从API获取
    if (!rates) {
      const response = await axios.get(`${FIXER_API_URL}/latest`, {
        params: {
          access_key: FIXER_API_KEY,
          base: 'EUR'
        }
      })

      if (response.data.success) {
        // 保存到数据库
        rates = await prisma.exchangeRate.create({
          data: {
            base: 'EUR',
            rates: response.data.rates
          }
        })
      } else {
        throw new Error('Failed to fetch exchange rates')
      }
    }

    return NextResponse.json(rates)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch exchange rates' }, { status: 500 })
  }
} 