import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'
import { createInterface } from 'readline'

const prisma = new PrismaClient()
const rl = createInterface({
  input: process.stdin,
  output: process.stdout
})

async function question(prompt: string): Promise<string> {
  return new Promise((resolve) => {
    rl.question(prompt, resolve)
  })
}

async function main() {
  try {
    const username = await question('输入用户名: ')
    const password = await question('输入密码: ')
    
    const hashedPassword = await bcrypt.hash(password, 10)
    const user = await prisma.user.create({
      data: {
        username,
        password: hashedPassword
      }
    })

    console.log('用户创建成功:', user.username)
  } catch (error) {
    console.error('创建用户失败:', error)
  } finally {
    rl.close()
    await prisma.$disconnect()
  }
}

main() 