import { NextResponse } from 'next/server'
import { updateExchangeRates } from '@/lib/exchange-rate'

export async function GET() {
  try {
    await updateExchangeRates()
    return NextResponse.json({ success: true })
  } catch (error) {
    return NextResponse.json(
      { error: '更新汇率失败' },
      { status: 500 }
    )
  }
} 