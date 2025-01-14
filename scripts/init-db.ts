import { PrismaClient } from '@prisma/client'
import * as bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

export async function initDatabase(adminPassword: string) {
  try {
    console.log('Starting database initialization...')
    
    if (!adminPassword) {
      throw new Error('Admin password not provided')
    }

    // 检查是否已存在用户
    console.log('Checking for existing user...')
    const existingUser = await prisma.user.findFirst()
    
    // 生成密码哈希
    console.log('Generating password hash...')
    const hashedPassword = await bcrypt.hash(adminPassword, 10)
    
    if (!existingUser) {
      // 创建管理员用户
      console.log('Creating new admin user...')
      const user = await prisma.user.create({
        data: {
          password: hashedPassword
        }
      })
      console.log('Admin user created successfully with ID:', user.id)
    } else {
      // 更新现有用户的密码
      console.log('Updating existing admin password...')
      const user = await prisma.user.update({
        where: { id: existingUser.id },
        data: { password: hashedPassword }
      })
      console.log('Admin password updated successfully for ID:', user.id)
    }

    // 验证密码是否正确保存
    console.log('Verifying password...')
    const verifyUser = await prisma.user.findFirst()
    const isValid = await bcrypt.compare(adminPassword, verifyUser!.password)
    console.log('Password verification:', isValid ? 'successful' : 'failed')

  } catch (error) {
    console.error('Error initializing database:', error)
    throw error
  } finally {
    await prisma.$disconnect()
  }
} 