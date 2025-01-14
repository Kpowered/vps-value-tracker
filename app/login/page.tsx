'use client'

import { useState } from 'react'
import { signIn } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import {
  Container,
  Box,
  FormControl,
  FormLabel,
  Input,
  Button,
  VStack,
  useToast,
  Heading
} from '@chakra-ui/react'

export default function Login() {
  const router = useRouter()
  const toast = useToast()
  const [loading, setLoading] = useState(false)
  const [password, setPassword] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const result = await signIn('credentials', {
        password,
        redirect: false
      })

      if (result?.error) {
        toast({
          title: '登录失败',
          description: '密码错误',
          status: 'error',
          duration: 3000,
        })
      } else {
        router.push('/')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <Container maxW="container.sm" py={8}>
      <Box as="form" onSubmit={handleSubmit}>
        <VStack spacing={4}>
          <Heading>管理员登录</Heading>

          <FormControl isRequired>
            <FormLabel>密码</FormLabel>
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </FormControl>

          <Button
            type="submit"
            colorScheme="blue"
            isLoading={loading}
            width="full"
          >
            登录
          </Button>
        </VStack>
      </Box>
    </Container>
  )
} 