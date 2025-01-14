'use client'

import { useEffect, useState } from 'react'
import {
  Box,
  Container,
  Table,
  Thead,
  Tbody,
  Tr,
  Th,
  Td,
  Button,
  useToast,
  Text,
  Flex,
  Spinner
} from '@chakra-ui/react'
import { useSession } from 'next-auth/react'
import { format } from 'date-fns'
import axios from 'axios'

interface VPS {
  id: string
  merchantName: string
  cpu: {
    cores: number
    model: string
  }
  memory: {
    size: number
  }
  storage: {
    size: number
  }
  bandwidth: {
    size: number
  }
  price: number
  currency: string
  startDate: string
  endDate: string
}

export default function Home() {
  const [vpsList, setVpsList] = useState<VPS[]>([])
  const [loading, setLoading] = useState(true)
  const [rates, setRates] = useState<Record<string, number>>({})
  const { data: session } = useSession()
  const toast = useToast()

  useEffect(() => {
    fetchVPSList()
    fetchRates()
  }, [])

  const fetchVPSList = async () => {
    try {
      const { data } = await axios.get('/api/vps')
      setVpsList(data)
    } catch (error) {
      toast({
        title: '获取VPS列表失败',
        status: 'error',
        duration: 3000,
      })
    } finally {
      setLoading(false)
    }
  }

  const fetchRates = async () => {
    try {
      const { data } = await axios.get('/api/exchange-rates')
      setRates(data.rates)
    } catch (error) {
      toast({
        title: '获取汇率失败',
        status: 'error',
        duration: 3000,
      })
    }
  }

  const calculateRemainingValue = (vps: VPS) => {
    const now = new Date()
    const endDate = new Date(vps.endDate)
    const remainingDays = Math.max(0, Math.ceil((endDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)))
    return (vps.price * remainingDays / 365).toFixed(2)
  }

  const convertToCNY = (amount: number, currency: string) => {
    if (currency === 'CNY') return amount
    const rate = rates[currency]
    return rate ? (amount / rate).toFixed(2) : '暂无汇率'
  }

  if (loading) {
    return (
      <Flex justify="center" align="center" h="100vh">
        <Spinner />
      </Flex>
    )
  }

  return (
    <Container maxW="container.xl" py={8}>
      <Flex justify="space-between" mb={6}>
        <Text fontSize="2xl">VPS 列表</Text>
        {session && (
          <Button colorScheme="blue" onClick={() => window.location.href = '/add'}>
            添加 VPS
          </Button>
        )}
      </Flex>

      <Box overflowX="auto">
        <Table variant="simple">
          <Thead>
            <Tr>
              <Th>服务商</Th>
              <Th>配置</Th>
              <Th>价格</Th>
              <Th>到期时间</Th>
              <Th>剩余价值</Th>
              <Th>剩余价值(CNY)</Th>
            </Tr>
          </Thead>
          <Tbody>
            {vpsList.map((vps) => (
              <Tr key={vps.id}>
                <Td>{vps.merchantName}</Td>
                <Td>
                  {`${vps.cpu.cores}核 ${vps.cpu.model} / 
                    ${vps.memory.size}GB / 
                    ${vps.storage.size}GB / 
                    ${vps.bandwidth.size}GB`}
                </Td>
                <Td>{`${vps.price} ${vps.currency}`}</Td>
                <Td>{format(new Date(vps.endDate), 'yyyy-MM-dd')}</Td>
                <Td>{`${calculateRemainingValue(vps)} ${vps.currency}`}</Td>
                <Td>{`￥${convertToCNY(Number(calculateRemainingValue(vps)), vps.currency)}`}</Td>
              </Tr>
            ))}
          </Tbody>
        </Table>
      </Box>
    </Container>
  )
} 