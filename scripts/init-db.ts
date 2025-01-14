import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function initDatabase(adminPassword: string) {
  try {
    // 检查是否已存在用户
    const existingUser = await prisma.user.findFirst()
    
    if (!existingUser) {
      // 创建管理员用户
      const hashedPassword = await bcrypt.hash(adminPassword, 10)
      await prisma.user.create({
        data: {
          password: hashedPassword
        }
      })
      console.log('Admin user created successfully')
    } else {
      // 更新现有用户的密码
      const hashedPassword = await bcrypt.hash(adminPassword, 10)
      await prisma.user.update({
        where: { id: existingUser.id },
        data: { password: hashedPassword }
      })
      console.log('Admin password updated successfully')
    }
  } catch (error) {
    console.error('Error initializing database:', error)
    throw error
  } finally {
    await prisma.$disconnect()
  }
}

export { initDatabase } 