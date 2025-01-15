import { NextResponse } from 'next/server'
import { PrismaClient } from '@prisma/client'
import { getUser } from '@/lib/auth'
import { convertToCNY } from '@/lib/exchange-rate'

const prisma = new PrismaClient()

export async function POST(request: Request) {
  try {
    const user = await getUser()
    if (!user) {
      return NextResponse.json({ error: '未登录' }, { status: 401 })
    }

    const data = await request.json()
    const startTime = new Date()
    const endTime = new Date(startTime)
    endTime.setFullYear(endTime.getFullYear() + 1)

    const vps = await prisma.vps.create({
      data: {
        ...data,
        userId: user.userId,
        startTime,
        endTime,
      },
    })

    return NextResponse.json(vps)
  } catch (error) {
    return NextResponse.json(
      { error: '添加失败' },
      { status: 500 }
    )
  }
}

export async function GET() {
  try {
    const vpsList = await prisma.vps.findMany({
      orderBy: { startTime: 'desc' },
    })

    // 计算剩余价值并转换货币
    const vpsWithValues = await Promise.all(
      vpsList.map(async vps => {
        const now = new Date()
        const end = new Date(vps.endTime)
        const remainingDays = Math.max(0, (end.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
        const remainingValue = (vps.price * remainingDays) / 365
        const remainingValueCNY = await convertToCNY(remainingValue, vps.currency)

        return {
          ...vps,
          remainingValue,
          remainingValueCNY
        }
      })
    )

    return NextResponse.json(vpsWithValues)
  } catch (error) {
    return NextResponse.json(
      { error: '获取失败' },
      { status: 500 }
    )
  }
} 