'use client'

import { useState } from 'react'
import {
  Box,
  Container,
  FormControl,
  FormLabel,
  Input,
  Select,
  NumberInput,
  NumberInputField,
  Button,
  VStack,
  useToast
} from '@chakra-ui/react'
import { useRouter } from 'next/navigation'
import axios from 'axios'

export default function AddVPS() {
  const router = useRouter()
  const toast = useToast()
  const [loading, setLoading] = useState(false)

  const [formData, setFormData] = useState({
    merchantName: '',
    cpu: {
      cores: 1,
      model: ''
    },
    memory: {
      size: 1
    },
    storage: {
      size: 1
    },
    bandwidth: {
      size: 1
    },
    price: 0,
    currency: 'CNY'
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      await axios.post('/api/vps', formData)
      toast({
        title: 'VPS添加成功',
        status: 'success',
        duration: 3000,
      })
      router.push('/')
    } catch (error) {
      toast({
        title: '添加失败',
        status: 'error',
        duration: 3000,
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <Container maxW="container.md" py={8}>
      <Box as="form" onSubmit={handleSubmit}>
        <VStack spacing={4}>
          <FormControl isRequired>
            <FormLabel>服务商</FormLabel>
            <Input
              value={formData.merchantName}
              onChange={(e) => setFormData({...formData, merchantName: e.target.value})}
            />
          </FormControl>

          <FormControl isRequired>
            <FormLabel>CPU核心数</FormLabel>
            <NumberInput min={1}>
              <NumberInputField
                value={formData.cpu.cores}
                onChange={(e) => setFormData({
                  ...formData,
                  cpu: {...formData.cpu, cores: parseInt(e.target.value)}
                })}
              />
            </NumberInput>
          </FormControl>

          <FormControl isRequired>
            <FormLabel>CPU型号</FormLabel>
            <Input
              value={formData.cpu.model}
              onChange={(e) => setFormData({
                ...formData,
                cpu: {...formData.cpu, model: e.target.value}
              })}
            />
          </FormControl>

          <FormControl isRequired>
            <FormLabel>内存(GB)</FormLabel>
            <NumberInput min={0.5}>
              <NumberInputField
                value={formData.memory.size}
                onChange={(e) => setFormData({
                  ...formData,
                  memory: {size: parseInt(e.target.value)}
                })}
              />
            </NumberInput>
          </FormControl>

          <FormControl isRequired>
            <FormLabel>硬盘(GB)</FormLabel>
            <NumberInput min={1}>
              <NumberInputField
                value={formData.storage.size}
                onChange={(e) => setFormData({
                  ...formData,
                  storage: {size: parseInt(e.target.value)}
                })}
              />
            </NumberInput>
          </FormControl>

          <FormControl isRequired>
            <FormLabel>带宽(GB)</FormLabel>
            <NumberInput min={1}>
              <NumberInputField
                value={formData.bandwidth.size}
                onChange={(e) => setFormData({
                  ...formData,
                  bandwidth: {size: parseInt(e.target.value)}
                })}
              />
            </NumberInput>
          </FormControl>

          <FormControl isRequired>
            <FormLabel>价格</FormLabel>
            <NumberInput min={0}>
              <NumberInputField
                value={formData.price}
                onChange={(e) => setFormData({...formData, price: parseFloat(e.target.value)})}
              />
            </NumberInput>
          </FormControl>

          <FormControl isRequired>
            <FormLabel>货币</FormLabel>
            <Select
              value={formData.currency}
              onChange={(e) => setFormData({...formData, currency: e.target.value})}
            >
              <option value="CNY">人民币 (CNY)</option>
              <option value="USD">美元 (USD)</option>
              <option value="EUR">欧元 (EUR)</option>
              <option value="GBP">英镑 (GBP)</option>
              <option value="CAD">加元 (CAD)</option>
              <option value="JPY">日元 (JPY)</option>
            </Select>
          </FormControl>

          <Button
            type="submit"
            colorScheme="blue"
            isLoading={loading}
            width="full"
          >
            添加
          </Button>
        </VStack>
      </Box>
    </Container>
  )
} 