import { PrismaClient } from '@prisma/client'

const FIXER_API_KEY = '9fc7824eeb86c023e2ba423a80f17f9b'
const FIXER_API_URL = 'http://data.fixer.io/api'

const prisma = new PrismaClient()

interface FixerResponse {
  success: boolean
  rates: Record<string, number>
  error?: {
    code: number
    type: string
    info: string
  }
}

export async function updateExchangeRates() {
  try {
    // 获取上次更新时间
    const lastRate = await prisma.exchangeRate.findFirst({
      orderBy: { updatedAt: 'desc' }
    })

    // 如果距离上次更新不到24小时，则跳过
    if (lastRate) {
      const lastUpdate = new Date(lastRate.updatedAt)
      const now = new Date()
      const hoursSinceLastUpdate = (now.getTime() - lastUpdate.getTime()) / (1000 * 60 * 60)
      if (hoursSinceLastUpdate < 24) {
        console.log('Exchange rates were updated less than 24 hours ago')
        return
      }
    }

    // 调用 Fixer API 获取最新汇率
    const response = await fetch(
      `${FIXER_API_URL}/latest?access_key=${FIXER_API_KEY}&base=EUR&symbols=CNY,USD,EUR,GBP,CAD,JPY`
    )
    const data: FixerResponse = await response.json()

    if (!data.success) {
      throw new Error(data.error?.info || 'Failed to fetch exchange rates')
    }

    // 更新数据库中的汇率
    const currencies = ['CNY', 'USD', 'EUR', 'GBP', 'CAD', 'JPY']
    const eurRate = data.rates['EUR'] // EUR 对 EUR 的汇率为 1

    // 使用事务确保原子性
    await prisma.$transaction(
      currencies.map(currency => 
        prisma.exchangeRate.upsert({
          where: { currency },
          create: {
            currency,
            rate: data.rates[currency] / eurRate, // 转换为相对于 EUR 的汇率
            updatedAt: new Date()
          },
          update: {
            rate: data.rates[currency] / eurRate,
            updatedAt: new Date()
          }
        })
      )
    )

    console.log('Exchange rates updated successfully')
  } catch (error) {
    console.error('Failed to update exchange rates:', error)
    throw error
  }
}

export async function convertToCNY(amount: number, currency: string): Promise<number> {
  try {
    const rate = await prisma.exchangeRate.findUnique({
      where: { currency }
    })

    if (!rate) {
      throw new Error(`Exchange rate not found for currency: ${currency}`)
    }

    const cnyRate = await prisma.exchangeRate.findUnique({
      where: { currency: 'CNY' }
    })

    if (!cnyRate) {
      throw new Error('CNY exchange rate not found')
    }

    // 先转换为 EUR，再转换为 CNY
    return amount * (cnyRate.rate / rate.rate)
  } catch (error) {
    console.error('Failed to convert currency:', error)
    throw error
  }
} 