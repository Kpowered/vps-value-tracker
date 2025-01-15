import { NextResponse } from 'next/server'
import { PrismaClient } from '@prisma/client'
import { cookies } from 'next/headers'
import { verifyToken } from '@/lib/auth'

const prisma = new PrismaClient()

// 获取VPS列表
export async function GET() {
  try {
    const vpsList = await prisma.vps.findMany({
      orderBy: { startTime: 'desc' }
    })
    return NextResponse.json(vpsList)
  } catch (error) {
    return NextResponse.json({ error: '获取失败' }, { status: 500 })
  }
}

// 添加VPS
export async function POST(request: Request) {
  try {
    // 验证用户登录
    const token = cookies().get('token')?.value
    if (!token) {
      return NextResponse.json({ error: '未登录' }, { status: 401 })
    }

    const user = await verifyToken(token)
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
      }
    })

    return NextResponse.json(vps)
  } catch (error) {
    return NextResponse.json({ error: '添加失败' }, { status: 500 })
  }
} 