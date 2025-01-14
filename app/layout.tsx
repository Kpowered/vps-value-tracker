'use client'

import { ChakraProvider } from '@chakra-ui/react'
import { SessionProvider } from 'next-auth/react'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh">
      <body>
        <SessionProvider>
          <ChakraProvider>
            {children}
          </ChakraProvider>
        </SessionProvider>
      </body>
    </html>
  )
} 