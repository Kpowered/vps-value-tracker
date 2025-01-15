import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'
import readline from 'readline'

const prisma = new PrismaClient()
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
})

async function createUser() {
  const username = await new Promise<string>(resolve => {
    rl.question('Enter username: ', resolve)
  })

  const password = await new Promise<string>(resolve => {
    rl.question('Enter password: ', resolve)
  })

  try {
    const hashedPassword = await bcrypt.hash(password, 10)
    const user = await prisma.user.create({
      data: {
        username,
        password: hashedPassword
      }
    })
    console.log('User created successfully:', user.username)
  } catch (error) {
    console.error('Error creating user:', error)
  } finally {
    rl.close()
    await prisma.$disconnect()
  }
}

createUser() 